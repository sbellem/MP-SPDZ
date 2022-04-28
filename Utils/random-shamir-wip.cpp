/*
 * paper-example.cpp
 *
 * Working example similar to Figure 2 in https://eprint.iacr.org/2020/521
 *
 */

#define NO_MIXED_CIRCUITS

#include "Math/gfp.hpp"
//#include "Math/gfp.hpp"
#include "Machines/SPDZ.hpp"
#include "Machines/MalRep.hpp"
#include "Machines/ShamirMachine.hpp"
#include "Protocols/ProtocolSet.h"

#include "Tools/ezOptionParser.h"

using namespace ez;

template<class T>
void run(ezOptionParser& opt, bigint prime, int prime_length);

void Usage(ezOptionParser& opt) {
	string usage;
	opt.getUsage(usage);
	cout << usage;
};

int main(int argc, const char** argv)
{
    auto& opts = ShamirOptions::singleton;
    ezOptionParser opt;
    opts = {opt, argc, argv};

    opt.overview = "Generator of random shares using Shamir Secret Sharing.";
    opt.syntax = "./random-shamir.x [OPTIONS]\n";
    opt.example = "./random-shamir.x -i 0 -N 4 -T 1 --nshares 10000 --host darkmatter.io --port 9999 \n";

    opt.add(
		"", // Default.
		0, // Required?
		0, // Number of args expected.
		0, // Delimiter if expecting multiple args.
		"Display usage instructions.", // Help description.
		"-h",     // Flag token. 
		"--help" // Flag token.
	);

    opt.add(
		"", // Default.
		1, // Required?
		1, // Number of args expected.
		0, // Delimiter if expecting multiple args.
		"Player number.", // Help description.
		"-i", // Flag token.
		"--playerno" // Flag token.
	);

    opt.add(
		"20000", // Default.
		0, // Required?
		1, // Number of args expected.
		0, // Delimiter if expecting multiple args.
		"Number of shares to generate (default: 20000).", // Help description.
		"-s", // Flag token.
		"--nshares" // Flag token.
	);

    opt.add(
		"52435875175126190479447740508185965837690552500527637822603658699938581184513", // Default.
		0, // Required?
		1, // Number of args expected.
		0, // Delimiter if expecting multiple args.
		"Prime field (default: BLS12-381 prime field \
            '52435875175126190479447740508185965837690552500527637822603658699938581184513').", // Help description.
		"-P",
		"--prime"
	);

    opt.add(
		"localhost", // Default.
		0, // Required?
		1, // Number of args expected.
		0, // Delimiter if expecting multiple args.
		"Hostname of MPC server (default: 'localhost').", // Help description.
		"--host"
	);

    opt.add(
		"9999", // Default.
		0, // Required?
		1, // Number of args expected.
		0, // Delimiter if expecting multiple args.
		"Port number.", // Help description.
		"-p", // Flag token.
		"--port" // Flag token.
	);

    opt.parse(argc, argv);

	if (opt.isSet("-h")) {
		Usage(opt);
		return 1;
	}

    if (!opt.isSet("-i"))
    {
		Usage(opt);
        exit(0);
    }

    string prime;
    opt.get("--prime")->getString(prime);

    // bit length of prime
    const int prime_length = 256;

    // compute number of 64-bit words needed
    const int n_limbs = (prime_length + 63) / 64;

    run<MaliciousShamirShare<gfp_<0, n_limbs>>>(opt, bigint(prime), prime_length);
    //run<MaliciousShamirShare<gfp_<0, n_limbs>>>(opt, bigint(prime));
}

template<class T>
void run(ezOptionParser& opt, bigint prime, int prime_length)
{
    int playerno, nparties, nshares, port;
    string hostname, prep_dir;
    opt.get("--playerno")->getInt(playerno);
    opt.get("--nparties")->getInt(nparties);
    opt.get("--nshares")->getInt(nshares);
    opt.get("--host")->getString(hostname);
    opt.get("--port")->getInt(port);
    opt.get("--prep-dir")->getString(prep_dir);

    Names names(playerno, nparties, hostname, port);
    CryptoPlayer crypto_player(names);

    // protocol setup (domain, MAC key if needed etc)
    cout << "prime: " << prime << endl;
    cout << "prime_length: " << prime_length << endl;
    //ProtocolSetup<T> setup(crypto_player, prime_length);
    //ProtocolSetup<T> setup(bigint(prime), crypto_player);

    //ProtocolSet<T> protocol_set(crypto_player, setup);

    //auto& preprocessing = protocol_set.preprocessing;

    //stringstream ss;
    //ofstream outputFile;
    //string prep_data_dir = get_prep_sub_dir<T>(prep_dir, crypto_player.num_players());
    //ss << prep_data_dir << "Randoms-" << T::type_short() << "-P" << crypto_player.my_num();
    //outputFile.open(ss.str().c_str());

    //int ntriples = nshares / 2 + nshares % 2;
    //vector<T> Sa(ntriples), Sb(ntriples), Sc(ntriples);
    //for (int i=0; i < ntriples; i++)
    //{
    //    preprocessing.get_three(DATA_TRIPLE, Sa[i], Sb[i], Sc[i]);
    //    Sa[i].output(outputFile, true);
    //    if (i == ntriples - 1 &&  nshares % 2)
    //        break;
    //    outputFile << "\n";
    //    Sb[i].output(outputFile, true);
    //    if (i != ntriples - 1)
    //        outputFile << "\n";
    //}

    //cout << "\nDONE!" << endl;

    //T::LivePrep::teardown();
}
