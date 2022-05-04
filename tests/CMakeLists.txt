cmake_minimum_required(VERSION 3.18)
project(test_spdz)
enable_testing()

# replace XX with the version you have
set(Boost_ADDITIONAL_VERSIONS "1.74" "1.74.0")

# finds boost, triggers an error otherwise
find_package(Boost 1.74 REQUIRED COMPONENTS unit_test_framework)

# creates the executable
add_executable(test_random test_random.cpp)

# indicates the include paths
target_include_directories(test_random PRIVATE ${BOOST_INCLUDE_DIRS})

# indicates the shared library variant
target_compile_definitions(test_random PRIVATE "BOOST_TEST_DYN_LINK=1")

# indicates the link paths
target_link_libraries(test_random ${Boost_UNIT_TEST_FRAMEWORK_LIBRARY})

# declares a test with our executable
add_test(NAME test1 COMMAND test_random)
