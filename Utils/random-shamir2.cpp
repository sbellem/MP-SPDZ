/*
 * paper-example.cpp
 *
 * Working example similar to Figure 2 in https://eprint.iacr.org/2020/521
 *
 */

#define NO_MIXED_CIRCUITS

#include "Math/gfp.hpp"
#include "Machines/SPDZ.hpp"
#include "Machines/MalRep.hpp"
#include "Machines/ShamirMachine.hpp"
#include "Protocols/CowGearShare.h"
#include "Protocols/CowGearPrep.hpp"

template<class T>
void run(char** argv, int prime_length);

int main(int argc, char** argv)
{
    // bit length of prime
    const int prime_length = 256;

    // compute number of 64-bit words needed
    const int n_limbs = (prime_length + 63) / 64;

    // need player number and number of players
    if (argc < 2)
    {
        cerr << "Usage: " << argv[0] << "<my number: 0/1/...> <total number of players> [threshold]]" << endl;
        exit(1);
    }

    int nparties = (atoi(argv[2]));
    int threshold = (nparties - 1) / 2;
    if (argc > 3)
        threshold = atoi(argv[3]);
    assert(2 * threshold < nparties);
    ShamirOptions::s().threshold = threshold;
    ShamirOptions::s().nparties = nparties;

    run<MaliciousShamirShare<gfp_<0, n_limbs>>>(argv, prime_length);
}

template<class T>
void run(char** argv, int prime_length)
{
    // set up networking on localhost
    Names N;
    int my_number = atoi(argv[1]);
    int n_parties = atoi(argv[2]);
    int port_base = 9999;
    Server::start_networking(N, my_number, n_parties, "localhost", port_base);
    CryptoPlayer P(N);

    // initialize fields
    T::clear::init_default(prime_length);
    T::clear::next::init_default(prime_length, false);

    // must initialize MAC key for security of some protocols
    typename T::mac_key_type mac_key;
    T::read_or_generate_mac_key("", P, mac_key);

    // global OT setup
    BaseMachine machine;
    if (T::needs_ot)
        machine.ot_setups.push_back({P});

    // keeps tracks of preprocessing usage (triples etc)
    DataPositions usage;
    usage.set_num_players(P.num_players());

    // output protocol
    typename T::MAC_Check output(mac_key);

    // various preprocessing
    typename T::LivePrep preprocessing(0, usage);
    SubProcessor<T> processor(output, preprocessing, P);

    // generate random shares
    stringstream ss;
    ofstream outputFile;
    string prep_data_dir = get_prep_sub_dir<T>(PREP_DIR, P.num_players());
    ss << prep_data_dir << "Randoms-" << T::type_short() << "-P" << P.my_num();
    outputFile.open(ss.str().c_str());

    const int nshares = 20000;
    int ntriples = nshares / 2 + nshares % 2;
    vector<T> Sa(ntriples), Sb(ntriples), Sc(ntriples);
    for (int i=0; i < ntriples; i++)
    {
        preprocessing.get_three(DATA_TRIPLE, Sa[i], Sb[i], Sc[i]);
        Sa[i].output(outputFile, true);
        if (i == ntriples - 1 &&  nshares % 2)
            break;
        outputFile << "\n";
        Sb[i].output(outputFile, true);
        if (i != ntriples - 1)
            outputFile << "\n";
    }
    cout << "\nDONE!" << endl;

    // input protocol
    //typename T::Input input(processor, output);
    //typename T::Protocol protocol(P);
    //int n = 1000;
    //vector<T> a(n), b(n);
    //T c;
    //typename T::clear result;
    //input.reset_all(P);
    //for (int i = 0; i < n; i++)
    //    input.add_from_all(i);
    //input.exchange();
    //for (int i = 0; i < n; i++)
    //{
    //    a[i] = input.finalize(0);
    //    b[i] = input.finalize(1);
    //}
    //protocol.init_dotprod(&processor);
    //for (int i = 0; i < n; i++)
    //    protocol.prepare_dotprod(a[i], b[i]);
    //protocol.next_dotprod();
    //protocol.exchange();
    //c = protocol.finalize_dotprod(n);
    //output.init_open(P);
    //output.prepare_open(c);
    //output.exchange(P);
    //result = output.finalize_open();
    //cout << "result: " << result << endl;
    //output.Check(P);

    T::LivePrep::teardown();
}
