// Main entry point for a native debug executable.
// Build it with: `icpp build-native` from the parent folder where 'icpp.toml' resides

#include "main.h"

#include <iostream>

#include "../src/canister_main.h"

// The Mock IC
#include "global.h"
#include "mock_ic.h"

int main() {
  MockIC mockIC(true);

  // -----------------------------------------------------------------------------
  // Configs for the tests:

  // The pretend principals of the caller
  std::string my_principal{
      "expmt-gtxsw-inftj-ttabj-qhp5s-nozup-n3bbo-k7zvn-dg4he-knac3-lae"};
  std::string anonymous_principal{"2vxsx-fae"};
  std::string django_principal{
      "3jugl-acjka-fzovn-ojo65-glrop-x4qja-um6y4-sfr56-avzeh-ktelc-fqe"};
  std::string action_server_principal{
      "ypb2o-3i7yp-ganxs-yje36-4q3cf-rqcfu-3spm6-3qmef-w6rsc-3k6qr-mae"};

  bool silent_on_trap = true;

  // -----------------------------------------------------------------------------
  // '()' -> canister_init does not return directly, so skip validation check
  mockIC.run_test("canister_init", canister_init, "4449444c0000", "",
                  silent_on_trap, my_principal);

  // '(record {"django-principal" = "3jugl-acjka-fzovn-ojo65-glrop-x4qja-um6y4-sfr56-avzeh-ktelc-fqe" : text; })' -> '(variant { err = 401 : nat16})'
  // Call with non owner principal
  mockIC.run_test(
      "set_django_principal", set_django_principal,
      "4449444c016c01fceeeef7067101003f336a75676c2d61636a6b612d667a6f766e2d6f6a6f36352d676c726f702d7834716a612d756d3679342d73667235362d61767a65682d6b74656c632d667165",
      "4449444c016b01e58eb4027a0100009101", silent_on_trap,
      anonymous_principal);

  // '(record {"django-principal" = "3jugl-acjka-fzovn-ojo65-glrop-x4qja-um6y4-sfr56-avzeh-ktelc-fqe" : text; })' -> '(variant { ok })'
  // ok: Call with owner principal
  mockIC.run_test(
      "set_django_principal", set_django_principal,
      "4449444c016c01fceeeef7067101003f336a75676c2d61636a6b612d667a6f766e2d6f6a6f36352d676c726f702d7834716a612d756d3679342d73667235362d61767a65682d6b74656c632d667165",
      "4449444c016b019cc2017f010000", silent_on_trap, my_principal);

  // '(record {"action-server-principal" = "ypb2o-3i7yp-ganxs-yje36-4q3cf-rqcfu-3spm6-3qmef-w6rsc-3k6qr-mae" : text; })' -> '(variant { err = 401 : nat16})'
  // Call with non owner principal
  mockIC.run_test(
      "set_action_server_principal", set_action_server_principal,
      "4449444c016c019bfed7bb0e7101003f797062326f2d33693779702d67616e78732d796a6533362d34713363662d72716366752d3373706d362d33716d65662d77367273632d336b3671722d6d6165",
      "4449444c016b01e58eb4027a0100009101", silent_on_trap,
      anonymous_principal);

  // '(record {"action-server-principal" = "ypb2o-3i7yp-ganxs-yje36-4q3cf-rqcfu-3spm6-3qmef-w6rsc-3k6qr-mae" : text; })' -> '(variant { ok })'
  // ok: Call with owner principal
  mockIC.run_test(
      "set_action_server_principal", set_action_server_principal,
      "4449444c016c019bfed7bb0e7101003f797062326f2d33693779702d67616e78732d796a6533362d34713363662d72716366752d3373706d362d33716d65662d77367273632d336b3671722d6d6165",
      "4449444c016b019cc2017f010000", silent_on_trap, my_principal);

  // '("C++ Developer")' -> '("hello C++ Developer! from a C++ backend canister, build with icpp-pro.")'
  mockIC.run_test(
      "greet", greet, "4449444c0001710d432b2b20446576656c6f706572",
      "4449444c0001714668656c6c6f20432b2b20446576656c6f706572212066726f6d206120432b2b206261636b656e642063616e69737465722c206275696c64207769746820696370702d70726f2e",
      silent_on_trap, my_principal);

  // '()' -> '("Your principal is expmt-gtxsw-inftj-ttabj-qhp5s-nozup-n3bbo-k7zvn-dg4he-knac3-lae")'
  mockIC.run_test(
      "whoami", whoami, "4449444c0000",
      "4449444c00017151596f7572207072696e636970616c206973206578706d742d67747873772d696e66746a2d747461626a2d71687035732d6e6f7a75702d6e3362626f2d6b377a766e2d64673468652d6b6e6163332d6c6165",
      silent_on_trap, my_principal);

  // '()' -> '(variant { err = 401 : nat16})'
  // Unauthorized to ask for a session password if not logged in
  mockIC.run_test("session_password_create (err)", session_password_create,
                  "4449444c0000", "4449444c016b01e58eb4027a0100009101",
                  silent_on_trap, anonymous_principal);

  // '()' -> '(variant { ok = "<A SESSION PASSWORD>" : text})'
  // Since the session password is different each time, cannot assert it
  mockIC.run_test("session_password_create (ok)", session_password_create,
                  "4449444c0000", "", silent_on_trap, my_principal);

  // '("expmt-gtxsw-inftj-ttabj-qhp5s-nozup-n3bbo-k7zvn-dg4he-knac3-lae", "a-pw")' -> '(variant { err = 401 : nat16})'
  // error: Call with non django principal
  mockIC.run_test(
      "session_password_check (err 1)", session_password_check,
      "4449444c000271713f6578706d742d67747873772d696e66746a2d747461626a2d71687035732d6e6f7a75702d6e3362626f2d6b377a766e2d64673468652d6b6e6163332d6c616504612d7077",
      "4449444c016b01e58eb4027a0100009101", silent_on_trap, my_principal);

  // '("expmt-gtxsw-inftj-ttabj-qhp5s-nozup-n3bbo-k7zvn-dg4he-knac3-lae", "a-pw")' -> '(variant { err = 401 : nat16})'
  // error: wrong pw for this principal
  mockIC.run_test(
      "session_password_check (err 2)", session_password_check,
      "4449444c000271713f6578706d742d67747873772d696e66746a2d747461626a2d71687035732d6e6f7a75702d6e3362626f2d6b377a766e2d64673468652d6b6e6163332d6c616504612d7077",
      "4449444c016b01e58eb4027a0100009101", silent_on_trap, django_principal);

  // '("2vxsx-fae", "a-pw")' -> '(variant { err = 401 : nat16})'
  // error: no pw for this principal
  mockIC.run_test("session_password_check (err 3)", session_password_check,
                  "4449444c000271710932767873782d66616504612d7077",
                  "4449444c016b01e58eb4027a0100009101", silent_on_trap,
                  django_principal);

  // '("expmt-gtxsw-inftj-ttabj-qhp5s-nozup-n3bbo-k7zvn-dg4he-knac3-lae", "SECRET-MESSAGE")' -> '(variant { err = 401 : nat16})'
  // error: not called by action server
  mockIC.run_test(
      "save_message (err)", save_message,
      "4449444c000271713f6578706d742d67747873772d696e66746a2d747461626a2d71687035732d6e6f7a75702d6e3362626f2d6b377a766e2d64673468652d6b6e6163332d6c61650e5345435245542d4d455353414745",
      "4449444c016b01e58eb4027a0100009101", silent_on_trap, my_principal);

  // '("expmt-gtxsw-inftj-ttabj-qhp5s-nozup-n3bbo-k7zvn-dg4he-knac3-lae", "SECRET-MESSAGE")' -> '(variant { ok })'
  mockIC.run_test(
      "save_message (ok)", save_message,
      "4449444c000271713f6578706d742d67747873772d696e66746a2d747461626a2d71687035732d6e6f7a75702d6e3362626f2d6b377a766e2d64673468652d6b6e6163332d6c61650e5345435245542d4d455353414745",
      "4449444c016b019cc2017f010000", silent_on_trap, action_server_principal);

  // '("expmt-gtxsw-inftj-ttabj-qhp5s-nozup-n3bbo-k7zvn-dg4he-knac3-lae")' -> '(opt ("SECRET-MESSAGE" : text))'
  mockIC.run_test(
      "get_message", get_message,
      "4449444c0001713f6578706d742d67747873772d696e66746a2d747461626a2d71687035732d6e6f7a75702d6e3362626f2d6b377a766e2d64673468652d6b6e6163332d6c6165",
      "4449444c016e710100010e5345435245542d4d455353414745", silent_on_trap,
      my_principal);

  // '("2vxsx-fae")' -> The raw bytes returned represent an opt : text without a value.
  //                    There is no IDL representation for this.
  //                    didc decodes it to '(null)'
  mockIC.run_test("get_message (no secret available)", get_message,
                  "4449444c0001710932767873782d666165", "4449444c016e71010000",
                  silent_on_trap, my_principal);

  // -----------------------------------------------------------------------------
  // returns 1 if any tests failed
  return mockIC.test_summary();
}