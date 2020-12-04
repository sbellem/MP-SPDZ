#include "Machine.h"

#include "Memory.hpp"
#include "Online-Thread.hpp"

#include "Exceptions/Exceptions.h"

#include <sys/time.h>

#include "Math/Setup.h"
#include "Tools/mkpath.h"
#include "Tools/Bundle.h"

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <pthread.h>
using namespace std;

template<class sint, class sgf2n>
Machine<sint, sgf2n>::Machine(int my_number, Names& playerNames,
    string progname_str, string memtype, int lg2, bool direct,
    int opening_sum, bool receive_threads, int max_broadcast,
    bool use_encryption, bool live_prep, OnlineOptions opts)
  : my_number(my_number), N(playerNames),
    direct(direct), opening_sum(opening_sum),
    receive_threads(receive_threads), max_broadcast(max_broadcast),
    use_encryption(use_encryption), live_prep(live_prep), opts(opts),
    data_sent(0)
{
  if (opening_sum < 2)
    this->opening_sum = N.num_players();
  if (max_broadcast < 2)
    this->max_broadcast = N.num_players();

  // Set up the fields
  sgf2n::clear::init_field(lg2);
  sint::clear::read_or_generate_setup(prep_dir_prefix<sint>(), opts);
  sint::bit_type::mac_key_type::init_field();

  // Initialize gf2n_short for CCD
  sint::bit_type::part_type::open_type::init_field();

  // make directory for outputs if necessary
  mkdir_p(PREP_DIR);

  Player* P;
  if (use_encryption)
    P = new CryptoPlayer(N, 0xF00);
  else
    P = new PlainPlayer(N, 0xF00);

  if (opts.live_prep)
    {
      cout << "Processor/Machine.hpp | LivePrep basic setup ..." << endl;
      sint::LivePrep::basic_setup(*P);
    }

  sint::read_or_generate_mac_key(prep_dir_prefix<sint>(), *P, alphapi);
  sgf2n::read_or_generate_mac_key(prep_dir_prefix<sgf2n>(), *P, alpha2i);
  sint::bit_type::part_type::read_or_generate_mac_key(
      prep_dir_prefix<typename sint::bit_type>(), *P, alphabi);

#ifdef DEBUG_MAC
  cerr << "MAC Key p = " << alphapi << endl;
  cerr << "MAC Key 2 = " << alpha2i << endl;
  cout << "MAC Key p = " << alphapi << endl;
  cout << "MAC Key 2 = " << alpha2i << endl;
#endif

  // for OT-based preprocessing
  sint::clear::next::template init<typename sint::clear>(false);

  // Initialize the global memory
  if (memtype.compare("old")==0)
     {
       ifstream inpf;
       inpf.open(memory_filename(), ios::in | ios::binary);
       if (inpf.fail()) { throw file_error(memory_filename()); }
       inpf >> M2 >> Mp >> Mi;
       inpf.close();
     }
  else if (!(memtype.compare("empty")==0))
     { cerr << "Invalid memory argument" << endl;
       exit(1);
     }

  // Keep record of used offline data
  pos.set_num_players(N.num_players());

  load_schedule(progname_str);

#ifdef VERBOSE
  progs[0].print_offline_cost();
#endif

  cout << "NODE [" << my_number << "] " << "live_prep: " << live_prep << endl;
  cout << "NODE [" << my_number << "] " << "sint::needs_ot: " << sint::needs_ot << endl;
  cout << "NODE [" << my_number << "] " << "sgf2n::needs_ot: " << sgf2n::needs_ot << endl;
  cout << "NODE [" << my_number << "] " << "sint::bit_type::needs_ot: " << sint::bit_type::needs_ot << endl;

  if (live_prep
      and (sint::needs_ot or sgf2n::needs_ot or sint::bit_type::needs_ot))
  {
    for (int i = 0; i < nthreads; i++)
      ot_setups.push_back({ *P, true });
  }

  delete P;

  /* Set up the threads */
  tinfo.resize(nthreads);
  threads.resize(nthreads);
  queues.resize(nthreads);
  join_timer.resize(nthreads);

  for (int i=0; i<nthreads; i++)
    {
      queues[i] = new ThreadQueue;
      // stand-in for initialization
      queues[i]->schedule({});
      tinfo[i].thread_num=i;
      tinfo[i].Nms=&N;
      tinfo[i].alphapi=&alphapi;
      tinfo[i].alpha2i=&alpha2i;
      tinfo[i].machine=this;
      pthread_create(&threads[i],NULL,thread_info<sint, sgf2n>::Main_Func,&tinfo[i]);
    }

  // synchronize with clients before starting timer
  for (int i=0; i<nthreads; i++)
    {
      queues[i]->result();
    }
}

template<class sint, class sgf2n>
void Machine<sint, sgf2n>::load_program(string threadname, string filename)
{
  ifstream pinp(filename);
  if (pinp.fail()) { throw file_error(filename); }
  progs.push_back(N.num_players());
  int i = progs.size() - 1;
  progs[i].parse(pinp);
  pinp.close();
  M2.minimum_size(SGF2N, CGF2N, progs[i], threadname);
  Mp.minimum_size(SINT, CINT, progs[i], threadname);
  Mi.minimum_size(NONE, INT, progs[i], threadname);
}

template<class sint, class sgf2n>
DataPositions Machine<sint, sgf2n>::run_tapes(const vector<int>& args,
    Preprocessing<sint>* prep, Preprocessing<typename sint::bit_type>* bit_prep)
{
  assert(args.size() % 3 == 0);
  for (unsigned i = 0; i < args.size(); i += 3)
    fill_buffers(args[i], args[i + 1], prep, bit_prep);
  DataPositions res(N.num_players());
  for (unsigned i = 0; i < args.size(); i += 3)
    res.increase(run_tape(args[i], args[i + 1], args[i + 2]));
  return res;
}

template<class sint, class sgf2n>
void Machine<sint, sgf2n>::fill_buffers(int thread_number, int tape_number,
    Preprocessing<sint>* prep,
    Preprocessing<typename sint::bit_type>* bit_prep)
{
  // central preprocessing
  auto usage = progs[tape_number].get_offline_data_used();
  if (sint::expensive and prep != 0 and OnlineOptions::singleton.bucket_size == 3)
    {
      try
      {
          auto& source = *dynamic_cast<BufferPrep<sint>*>(prep);
          auto& dest =
              dynamic_cast<BufferPrep<sint>&>(tinfo[thread_number].processor->DataF.DataFp);
          for (auto it = usage.edabits.begin(); it != usage.edabits.end(); it++)
            {
              bool strict = it->first.first;
              int n_bits = it->first.second;
              size_t required = DIV_CEIL(it->second,
                  sint::bit_type::part_type::default_length);
              auto& dest_buffer = dest.edabits[it->first];
              auto& source_buffer = source.edabits[it->first];
              while (dest_buffer.size() < required)
                {
                  if (source_buffer.empty())
                    source.buffer_edabits(strict, n_bits, &queues);
                  size_t n = min(source_buffer.size(),
                      required - dest_buffer.size());
                  dest_buffer.insert(dest_buffer.end(), source_buffer.end() - n,
                      source_buffer.end());
                  source_buffer.erase(source_buffer.end() - n,
                      source_buffer.end());
                }
            }
      }
      catch (bad_cast& e)
      {
#ifdef VERBOSE_CENTRAL
        cerr << "Problem with central preprocessing" << endl;
#endif
      }
    }

  typedef typename sint::bit_type bit_type;
  if (bit_type::expensive_triples and bit_prep and OnlineOptions::singleton.bucket_size == 3)
    {
      try
      {
          auto& source = *dynamic_cast<BufferPrep<bit_type>*>(bit_prep);
          auto &dest =
              dynamic_cast<BufferPrep<bit_type>&>(tinfo[thread_number].processor->share_thread.DataF);
          for (int i = 0; i < DIV_CEIL(usage.files[DATA_GF2][DATA_TRIPLE],
                                        bit_type::default_length); i++)
            dest.push_triple(source.get_triple(bit_type::default_length));
      }
      catch (bad_cast& e)
      {
#ifdef VERBOSE_CENTRAL
        cerr << "Problem with central bit triple preprocessing: " << e.what() << endl;
#endif
      }
    }
}

template<class sint, class sgf2n>
DataPositions Machine<sint, sgf2n>::run_tape(int thread_number, int tape_number,
    int arg)
{
  if (size_t(thread_number) >= tinfo.size())
    throw Processor_Error("invalid thread number: " + to_string(thread_number) + "/" + to_string(tinfo.size()));
  if (size_t(tape_number) >= progs.size())
    throw Processor_Error("invalid tape number: " + to_string(tape_number) + "/" + to_string(progs.size()));

  queues[thread_number]->schedule({tape_number, arg, pos});
  //printf("Send signal to run program %d in thread %d\n",tape_number,thread_number);
  //printf("Running line %d\n",exec);
  if (progs[tape_number].usage_unknown())
    {
#ifndef INSECURE
      if (not opts.live_prep)
        {
          cerr << "Internally called tape " << tape_number <<
              " has unknown offline data usage" << endl;
          throw invalid_program();
        }
#endif
      return DataPositions(N.num_players());
    }
  else
    {
      // Bits, Triples, Squares, and Inverses skipping
      return progs[tape_number].get_offline_data_used();
    }
}

template<class sint, class sgf2n>
DataPositions Machine<sint, sgf2n>::join_tape(int i)
{
  join_timer[i].start();
  //printf("Waiting for client to terminate\n");
  auto pos = queues[i]->result().pos;
  join_timer[i].stop();
  return pos;
}

template<class sint, class sgf2n>
void Machine<sint, sgf2n>::run()
{
  cout << "NODE [" << my_number << "]" << endl;
  cout << "*************************************************************" << endl;
  cout << "*                                                           *" << endl;
  cout << "*            Processor/Machine.hpp | RUN Machine!           *" << endl;
  cout << "*            Machine type: " << typeid(this).name() << "          *" << endl;
  cout << "*                                                           *" << endl;
  cout << "*************************************************************" << endl;
  Timer proc_timer(CLOCK_PROCESS_CPUTIME_ID);
  proc_timer.start();
  timer[0].start();

  // run main tape
  pos.increase(run_tape(0, 0, 0));
  join_tape(0);

  print_compiler();

  finish_timer.start();
  // Tell all C-threads to stop
  for (int i=0; i<nthreads; i++)
    {
	//printf("Send kill signal to client\n");
      queues[i]->schedule(-1);
    }

  // reset to sum actual usage
  pos.reset();

#ifdef DEBUG_THREADS
  cerr << "Waiting for all clients to finish" << endl;
#endif
  // Wait until all clients have signed out
  for (int i=0; i<nthreads; i++)
    {
      queues[i]->schedule({});
      pos.increase(queues[i]->result().pos);
      pthread_join(threads[i],NULL);
      delete queues[i];
    }
  finish_timer.stop();
  
#ifdef VERBOSE
  cerr << "Memory usage: ";
  tinfo[0].print_usage(cerr, Mp.MS, "sint");
  tinfo[0].print_usage(cerr, Mp.MC, "cint");
  tinfo[0].print_usage(cerr, M2.MS, "sgf2n");
  tinfo[0].print_usage(cerr, M2.MS, "cgf2n");
  tinfo[0].print_usage(cerr, bit_memories.MS, "sbits");
  tinfo[0].print_usage(cerr, bit_memories.MC, "cbits");
  tinfo[0].print_usage(cerr, Mi.MC, "regint");
  cerr << endl;

  for (unsigned int i = 0; i < join_timer.size(); i++)
    cerr << "Join timer: " << i << " " << join_timer[i].elapsed() << endl;
  cerr << "Finish timer: " << finish_timer.elapsed() << endl;
  cerr << "Process timer: " << proc_timer.elapsed() << endl;
#endif

  print_timers();
  cerr << "Data sent = " << data_sent / 1e6 << " MB" << endl;

  PlainPlayer P(N, 0xFFF0);
  Bundle<octetStream> bundle(P);
  bundle.mine.store(data_sent.load());
  P.Broadcast_Receive_no_stats(bundle);
  size_t global = 0;
  for (auto& os : bundle)
      global += os.get_int(8);
  cerr << "Global data sent = " << global / 1e6 << " MB" << endl;

#ifdef VERBOSE
  if (opening_sum < N.num_players() && !direct)
    cerr << "Summed at most " << opening_sum << " shares at once with indirect communication" << endl;
  else
    cerr << "Summed all shares at once" << endl;

  if (max_broadcast < N.num_players() && !direct)
    cerr << "Send to at most " << max_broadcast << " parties at once" << endl;
  else
    cerr << "Full broadcast" << endl;
#endif

  // Reduce memory size to speed up
  unsigned max_size = 1 << 20;
  if (M2.size_s() > max_size)
    M2.resize_s(max_size);
  if (Mp.size_s() > max_size)
    Mp.resize_s(max_size);

  // Write out the memory to use next time
  ofstream outf(memory_filename(), ios::out | ios::binary);
  outf << M2 << Mp << Mi;
  outf.close();

  bit_memories.write_memory(N.my_num());

#ifdef OLD_USAGE
  for (int dtype = 0; dtype < N_DTYPE; dtype++)
    {
      cerr << "Num " << DataPositions::dtype_names[dtype] << "\t=";
      for (int field_type = 0; field_type < N_DATA_FIELD_TYPE; field_type++)
        cerr << " " << pos.files[field_type][dtype];
      cerr << endl;
   }
  for (int field_type = 0; field_type < N_DATA_FIELD_TYPE; field_type++)
    {
      cerr << "Num " << DataPositions::field_names[field_type] << " Inputs\t=";
      for (int i = 0; i < N.num_players(); i++)
        cerr << " " << pos.inputs[i][field_type];
      cerr << endl;
    }
#endif

#ifdef VERBOSE
  cout << "Actual cost of program:" << endl;
  cerr << "Actual cost of program:" << endl;
  pos.print_cost();
#endif

  if (not stats.empty())
    {
      cerr << "Instruction statistics:" << endl;
      set<pair<size_t, int>> sorted_stats;
      for (auto& x : stats)
        {
          sorted_stats.insert({x.second, x.first});
        }
      for (auto& x : sorted_stats)
        {
          auto opcode = x.second;
          auto calls = x.first;
          cerr << "\t";
          int n_fill = 15;
          switch (opcode)
          {
#define X(NAME, PRE, CODE) case NAME: cerr << #NAME; n_fill -= strlen(#NAME); break;
          ARITHMETIC_INSTRUCTIONS
#undef X
#define X(NAME, CODE) case NAME: cerr << #NAME; n_fill -= strlen(#NAME); break;
          COMBI_INSTRUCTIONS
#undef X
          default:
            cerr << hex << setw(5) << showbase << left << opcode;
            n_fill -= 5;
            cerr << setw(0);
          }
          for (int i = 0; i < n_fill; i++)
            cerr << " ";
          cerr << dec << calls << endl;
        }
    }

#ifndef INSECURE
  cout << "Processor/Machine.hpp | Create Data_Files instance ..." << endl;
  Data_Files<sint, sgf2n> df(*this);
  df.seekg(pos);
  df.prune();
#endif

  sint::LivePrep::teardown();
  sgf2n::LivePrep::teardown();

#ifdef VERBOSE
  cerr << "End of prog" << endl;
#endif
}

template<class sint, class sgf2n>
string Machine<sint, sgf2n>::memory_filename()
{
  return BaseMachine::memory_filename(sint::type_short(), my_number);
}

template<class sint, class sgf2n>
template<class T>
string Machine<sint, sgf2n>::prep_dir_prefix()
{
  int lgp = opts.lgp;
  if (opts.prime) {
    cout << "opts.prime: " << opts.prime << endl;
    cout << "opts.prime type: " << typeid(opts.prime).name() << endl;
    lgp = numBits(opts.prime);
  }
  return get_prep_sub_dir<T>(PREP_DIR, N.num_players(), lgp);
}

template<class sint, class sgf2n>
void Machine<sint, sgf2n>::reqbl(int n)
{
  sint::clear::reqbl(n);
}
