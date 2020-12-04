/*
 * paper-example.cpp
 *
 * Working example similar to Figure 2 in https://eprint.iacr.org/2020/521
 *
 */

//#include "Math/gfp.hpp"
//#include "Machines/SPDZ.hpp"
#include "Processor/Data_Files.hpp"
#include "Protocols/MaliciousShamirShare.h"
#include "Machines/ShamirMachine.hpp"

#include <typeinfo>

int main(int argc, char** argv)
{
    typedef MaliciousShamirShare<gfp> T;

    // need player number and number of players
    if (argc < 3)
    {
        cerr << "Usage: " << argv[0] << "<my number: 0/1/...> <total number of players>" << endl;
        exit(1);
    }

    // set up networking on localhost
    Names N;
    Server::start_networking(N, atoi(argv[1]), atoi(argv[2]), "localhost", 9999);
    CryptoPlayer P(N);

    // initialize fields
    //gfp::init_default(256);
    // BLS12_381
    gfp::init_field(bigint("52435875175126190479447740508185965837690552500527637822603658699938581184513"));
    //gfp1::init_default(128, false);
    T::bit_type::mac_key_type::init_field();

    // must initialize MAC key for security of some protocols
    //typename T::mac_key_type mac_key;
    //T::read_or_generate_mac_key("", P, mac_key);
    //typename T::bit_type::mac_key_type binary_mac_key;
    //T::bit_type::part_type::read_or_generate_mac_key("", P, binary_mac_key);

    // global OT setup
    //BaseMachine machine;
    //machine.ot_setups.push_back({P});

    // keeps tracks of preprocessing usage (triples etc)
    DataPositions usage;
    usage.set_num_players(P.num_players());

    // binary MAC check setup
    //GC::ShareThread<typename T::bit_type> thread(N,
    //        OnlineOptions::singleton, P, binary_mac_key, usage);

    // output protocol
    //typename T::MAC_Check output(mac_key);

    // various preprocessing
    typename T::LivePrep preprocessing(0, usage);
    //SubProcessor<T> processor(output, preprocessing, P);

    int ntriples = 1;
    vector<T> Sa(ntriples), Sb(ntriples), Sc(ntriples);
    //cout << "triples type: " << typeid(preprocessing.triples).name() << endl;
    for (int i=0; i < ntriples; i++)
    {
        preprocessing.get_three(DATA_TRIPLE, Sa[i], Sb[i], Sc[i]);
        cout << "###### Sa[" << i << "]: " << Sa[i] << endl;
    }

    /*
    stringstream ss;
    ofstream outputFile;
    string prep_data_dir = get_prep_sub_dir<T>(PREP_DIR, P.num_players());
    cout << "@@@@@: prep_data_dir: " << prep_data_dir << endl;
    ss << prep_data_dir << "Randoms-";
    ss << T::type_short() << "-P" << P.my_num();
    cout << "$$$$$: prep file: " << ss.str().c_str() << endl;
    outputFile.open(ss.str().c_str());

    int number_of_shares = 100;
    vector<T> random_shares(number_of_shares);
    for (int i=0; i < number_of_shares; i++)
    {
        //T random_share_i = preprocessing.get_random();
        //cout << "random share_i type: " << typeid(random_share_i).name() << endl;
        //cout << "random share_i: " << random_share_i << endl;
        T tmp;
        typename T::open_type _;
        //preprocessing.get_input_no_count(tmp, _, P.num_players());
        preprocessing.get_input(tmp, _, P.my_num());
        random_shares[i] = tmp;
        cout << "###### random shares[" << i << "]: " << random_shares[i] << endl;
        //random_shares[i].output(outputFile, false);
        cout << "random share[" << i << "]: " << random_shares[i] << endl;
    }
    */

    //T random_share;
    //random_share = preprocessing.get_random();
    //cout << "random share: " << random_share << endl;

    //cout << "triples type: " << typeid(preprocessing.triples).name() << endl;
    //preprocessing.buffer_triples();

    /*
    // input protocol
    typename T::Input input(&processor, P);

    // multiplication protocol
    typename T::Protocol protocol(P);

    int n = 1000;
    vector<T> a(n), b(n);
    T c;
    typename T::clear result;

    input.reset_all(P);
    for (int i = 0; i < n; i++)
        input.add_from_all(i);
    input.exchange();
    for (int i = 0; i < n; i++)
    {
        a[i] = input.finalize(0);
        b[i] = input.finalize(1);
    }

    protocol.init_dotprod(&processor);
    for (int i = 0; i < n; i++)
        protocol.prepare_dotprod(a[i], b[i]);
    protocol.next_dotprod();
    protocol.exchange();
    c = protocol.finalize_dotprod(n);
    output.init_open(P);
    output.prepare_open(c);
    output.exchange(P);
    result = output.finalize_open();

    cout << "result: " << result << endl;
    output.Check(P);
    */
}
