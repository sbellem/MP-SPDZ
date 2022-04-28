/*
 * random-shares.cpp
 * 
 * Based on paper-example.cpp
 *
 * Working example similar to Figure 2 in https://eprint.iacr.org/2020/521
 *
 */

#define NO_MIXED_CIRCUITS

#include "Math/gfp.hpp"
#include "Machines/SPDZ.hpp"
#include "Machines/MalRep.hpp"
#include "Machines/ShamirMachine.hpp"
#include "Protocols/ProtocolSet.h"

#include "Tools/ezOptionParser.h"

template<class T>
void run(char** argv, int prime_length);

//template<class T>
//void run(char** argv, bigint prime, int prime_length);

int main(int argc, char** argv)
{
    // bit length of prime
    const int prime_length = 256;

    // compute number of 64-bit words needed
    const int n_limbs = (prime_length + 63) / 64;

    // need player number and number of players
    if (argc < 3)
    {
        cerr << "Usage: " << argv[0]
                << " <my number: 0/1/...> <total number of players> [protocol [threshold]]"
                << endl;
        exit(1);
    }

    string protocol = "MalShamir";
    if (argc > 3)
        protocol = argv[3];

    if (protocol == "Shamir" or protocol == "MalShamir")
    {
        int nparties = (atoi(argv[2]));
        int threshold = (nparties - 1) / 2;
        if (argc > 4)
            threshold = atoi(argv[4]);
        assert(2 * threshold < nparties);
        ShamirOptions::s().threshold = threshold;
        ShamirOptions::s().nparties = nparties;

        if (protocol == "Shamir")
            run<ShamirShare<gfp_<0, n_limbs>>>(argv, prime_length);
        else
            run<MaliciousShamirShare<gfp_<0, n_limbs>>>(argv, prime_length);
    }
    else
    {
        cerr << "Unknown protocol: " << protocol << endl;
        exit(1);
    }
}

template<class T>
void run(char** argv, int prime_length)
{
    string hostname = "localhost";
    int my_number = atoi(argv[1]);
    int n_parties = atoi(argv[2]);
    int port_base = 9999;
    bigint prime = bigint("52435875175126190479447740508185965837690552500527637822603658699938581184513");

    Names names(my_number, n_parties, hostname, port_base);
    CryptoPlayer player(names);

    cout << "prime length: " << prime_length << endl;
    //ProtocolSetup<T> setup(player, prime_length);
    ProtocolSetup<T> setup(bigint(prime), player);

    ProtocolSet<T> set(player, setup);

    auto& preprocessing = set.preprocessing;

    stringstream ss;
    ofstream outputFile;
    string prep_data_dir = get_prep_sub_dir<T>(PREP_DIR, player.num_players());
    ss << prep_data_dir << "Randoms-" << T::type_short() << "-P" << player.my_num();
    outputFile.open(ss.str().c_str());

    int nshares = 1000;
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

    T::LivePrep::teardown();
}
