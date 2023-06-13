#include "password_generator.h"

#include <algorithm>
#include <random>
#include <string>

#include "ic_api.h"

PasswordGenerator::PasswordGenerator() {}
PasswordGenerator::~PasswordGenerator() {}

// Define a random password
std::string PasswordGenerator::random_password(size_t min_length,
                                               size_t max_length) {
  const char charset[] = "0123456789"
                         "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                         "abcdefghijklmnopqrstuvwxyz"
                         "!@#$%^&*()_+-~";
  const size_t max_index = (sizeof(charset) - 1);

  // Create pseudorandom number generators
  // (-) This is what you would do on a normal computer, but it imports a system call `random_get`
  //   std::random_device rd;
  //   std::mt19937 gen(rd());

  // (-) This is reasonably secure, by seeding it with the IC's System time
  uint64_t seed0 = IC_API::time();
  std::mt19937 gen0(seed0);

  std::uniform_int_distribution<> uid1(0, seed0);
  uint64_t seed1 = uid1(gen0);
  std::mt19937 gen1(seed1);

  std::uniform_int_distribution<> uid2(0, seed1);
  uint64_t seed2 = uid2(gen1);
  std::mt19937 gen2(seed2);

  // Generate the password length
  std::uniform_int_distribution<> len_dis(min_length, max_length);
  size_t length = len_dis(gen1);

  // Generate the password
  std::uniform_int_distribution<> dis(0, max_index);
  std::string str(length, 0);
  std::generate_n(str.begin(), length,
                  [&]() -> char { return charset[dis(gen2)]; });

  // IC_API::debug_print(std::string(__func__) +": seed1              = " + std::to_string(seed1));
  // IC_API::debug_print(std::string(__func__) +": seed2              = " + std::to_string(seed2));
  // IC_API::debug_print(std::string(__func__) +": password length    = " + std::to_string(length));
  // IC_API::debug_print(std::string(__func__) +": password           = " + str);
  return str;
}