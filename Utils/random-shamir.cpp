/*
 * Shamir-based random share generator.
 *
 */

#include "Machines/ShamirMachine.hpp"
#include "Processor/Data_Files.hpp"
#include "Tools/ezOptionParser.h"

using namespace ez;

int generate(ezOptionParser& opt, int nparties);

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
    opt.syntax = "./random-gen-shamir.x [OPTIONS]\n";
    opt.example = "./random-gen-shamir.x -i 0 -N 4 -T 1 --nshares 10000 --host darkmatter.io --port 9999 \n";

    opt.add(
		"", // Default.
		0, // Required?
		0, // Number of args expected.
		0, // Delimiter if expecting multiple args.
		"Display usage instructions.", // Help description.
		"-h",     // Flag token. 
		"-help",  // Flag token.
		"--help", // Flag token.
		"--usage" // Flag token.
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

    //opt.add(
	//	"4", // Default.
	//	0, // Required?
	//	1, // Number of args expected.
	//	0, // Delimiter if expecting multiple args.
	//	"Number of parties.", // Help description.
	//	"-N", // Flag token.
	//	"--nparties" // Flag token.
	//);

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
    cout << "opts threshold: " << opts.threshold << endl;
    cout << "opts nparties: " << opts.nparties << endl;
    return generate(opt, opts.nparties);
}


int generate(ezOptionParser& opt, int nparties)
{
    // needed because of bug in some gcc versions < 9
    // https://gitter.im/MP-SPDZ/community?at=5fcadf535be1fb21c5fce581
    bigint::init_thread();

    typedef MaliciousShamirShare<gfp> T;

    //int playerno, nparties, nshares, port;
    int playerno, nshares, port;
    string hostname, prime;
    opt.get("--playerno")->getInt(playerno);
    //opt.get("--nparties")->getInt(nparties);
    opt.get("--nshares")->getInt(nshares);
    opt.get("--prime")->getString(prime);
    opt.get("--host")->getString(hostname);
    opt.get("--port")->getInt(port);

    Names N;
    Server::start_networking(N, playerno, nparties, hostname, port);
    CryptoPlayer P(N);

    // initialize field
    gfp::init_field(bigint(prime));

    // TODO figure out whether gfp1 is needed, seems not for Shamir
    //gfp1::init_field(bigint(prime), false);
    T::bit_type::mac_key_type::init_field();

    // must initialize MAC key for security of some protocols
    typename T::mac_key_type mac_key;
    T::read_or_generate_mac_key("", P, mac_key);
    typename T::bit_type::mac_key_type binary_mac_key;
    T::bit_type::part_type::read_or_generate_mac_key("", P, binary_mac_key);

    //cout << "threshold: " << T::threshold(4) << endl;

    // Machine setup
    ShamirMachine machine;
    cout << "Shamir Machine threshold: " << ShamirMachine::s().threshold << endl;

    // keeps tracks of preprocessing usage
    DataPositions usage;
    usage.set_num_players(P.num_players());

    // binary MAC check setup
    GC::ShareThread<typename T::bit_type> thread(N,
            OnlineOptions::singleton, P, binary_mac_key, usage);

    // output protocol
    typename T::MAC_Check output(mac_key);

    // preprocessing
    typename T::LivePrep preprocessing(0, usage);
    SubProcessor<T> processor(output, preprocessing, P);

    stringstream ss;
    ofstream outputFile;
    string prep_data_dir = get_prep_sub_dir<T>(PREP_DIR, P.num_players());
    ss << prep_data_dir << "Randoms-" << T::type_short() << "-P" << P.my_num();
    outputFile.open(ss.str().c_str());

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

    return 0;
}
