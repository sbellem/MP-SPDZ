#define BOOST_TEST_MODULE test module name
#include <boost/test/unit_test.hpp>

//#include "Math/gf2n.h"
//#include "Math/gfp.h"
//#include "Math/Setup.h"
//#include "Math/Setup.hpp"
//#include "Math/gfp.hpp"
//#include "Protocols/MaliciousShamirShare.h"

#include "Machines/SPDZ.hpp"

#include "Machines/MalRep.hpp"
#include "Machines/ShamirMachine.hpp"
#include "Protocols/ProtocolSet.h"


BOOST_AUTO_TEST_CASE(default_prime_length) {
  BOOST_TEST(gfp0::MAX_N_BITS == 128);
}

BOOST_AUTO_TEST_CASE(galois_degree) {
  BOOST_TEST(gf2n::default_degree() == 128);
}

BOOST_AUTO_TEST_CASE(prime) {
    int lgp = gfp0::size_in_bits();
    BOOST_TEST(lgp == 128);
    bigint p = SPDZ_Data_Setup_Primes(lgp);
    cout << "prime: " << p << endl;
    BOOST_TEST(p == bigint("170141183460469231731687303715885907969"));
}

BOOST_AUTO_TEST_CASE(prep_dir) {
    const int prime_length = 256;
    const int n_limbs = (prime_length + 63) / 64;
    BOOST_TEST(n_limbs == 4);
    typedef MaliciousShamirShare<gfp_<0, 5>> T;
    string prep_dir = get_prep_sub_dir<T>(PREP_DIR, 4);
    cout << prep_dir << endl;
    BOOST_TEST(prep_dir == "Player-Data//4-MSp/");
}
