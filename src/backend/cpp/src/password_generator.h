#pragma once

#include <random>
#include <string>

class PasswordGenerator {
public:
  PasswordGenerator();
  ~PasswordGenerator();

  std::string random_password(size_t min_length, size_t max_length);
};