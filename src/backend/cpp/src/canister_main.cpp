#include "canister_main.h"

#include <string>
#include <unordered_map>
#include <variant>

#include "http.h"
#include "ic_api.h"
#include "password_generator.h"

#include "hash-library/sha256.h"

/* 
Deploy this canister with the command: $ make dfx-deploy

For local testing, do this:
  $ cd src/backend/cpp
  $ mkdir -p secret/local

  $ dfx identity new django-server-test
  $ dfx identity use django-server-test
  $ dfx identity get-principal > secret/local/django-principal.txt

  $ dfx identity new action-server-test
  $ dfx identity use action-server-test
  $ dfx identity get-principal > secret/local/action-server-principal.txt

  $ dfx identity use default  
  $ make dfx-deploy           
*/

// --------------------------------------------------------------------------------------------------
// State of the Smart Contract, using Orthogonal Persistence
// -> saved between calls to the canister, but not during upgrade
// -> we are not migrating them during upgrade, because we want to invalidate all existing logins

// String data, stored as null-terminated C-style strings (char array).
char *p_owner_principal = nullptr;
char *p_django_principal = nullptr;
char *p_action_server_principal = nullptr;

// Unordered_maps:
// - `p_principal_password <str_principal, str_password>`             : for each principal, PasswordSha256
// - `p_sessionkey_principal <str_django_session_key, str_principal>` : for each django session, the corresponding principal, which is the django username
// - `p_sessionkey_password <str_django_session_key, str_password>`   : for each django session, the corresponding PasswordSha256
// - `p_principal_message <str_principal, str_msg>`                   : bot-0-action-server calls this to save the 'secret' message of a user
using str_principal = std::string;
using str_password = std::string;
using str_django_session_key = std::string;
using str_msg = std::string;

std::pair<str_principal, str_password> *p_principal_password = nullptr;
__uint128_t len_principal_password = 0;

std::pair<str_django_session_key, str_principal> *p_sessionkey_principal =
    nullptr;
__uint128_t len_sessionkey_principal = 0;

std::pair<str_django_session_key, str_password> *p_sessionkey_password =
    nullptr;
__uint128_t len_sessionkey_password = 0;

std::pair<str_principal, str_msg> *p_principal_message = nullptr;
__uint128_t len_principal_message = 0;

// --------------------------------------------------------------------------------------------------
// Called using dfx during deployment

// See: https://internetcomputer.org/docs/current/references/ic-interface-spec#system-api-init
// - This method will be called automatically during deployment
void canister_init() {
  IC_API ic_api(CanisterInit{std::string(__func__)}, false);

  CandidTypePrincipal caller = ic_api.get_caller();
  std::string owner_principal = caller.get_text();

  ic_api.store_string_orthogonal(owner_principal, &p_owner_principal);
  IC_API::debug_print(std::string(__func__) +
                      ": owner_principal = " + owner_principal);
}

void set_django_principal() {
  IC_API ic_api(CanisterUpdate{std::string(__func__)}, false);

  CandidTypePrincipal caller = ic_api.get_caller();

  // caller must be the canister owner
  if (caller.get_text() !=
      ic_api.retrieve_string_orthogonal(p_owner_principal)) {
    uint16_t status_code = Http::StatusCode::Unauthorized;
    ic_api.to_wire(CandidTypeVariant{"err", CandidTypeNat16{status_code}});
    IC_API::debug_print(std::string(__func__) +
                        ": ERROR - caller is not the owner.");
    return;
  }

  // Get django-principal from the wire
  std::string django_principal;
  CandidTypeRecord r_in;
  r_in.append("django-principal", CandidTypeText{&django_principal});
  ic_api.from_wire(r_in);
  IC_API::debug_print(std::string(__func__) +
                      ": django_principal = " + django_principal);

  // Store the value for orthogonal persistence
  ic_api.store_string_orthogonal(django_principal, &p_django_principal);
  ic_api.to_wire(CandidTypeVariant{"ok"});
}

void set_action_server_principal() {
  IC_API ic_api(CanisterUpdate{std::string(__func__)}, false);

  CandidTypePrincipal caller = ic_api.get_caller();

  // caller must be the canister owner
  if (caller.get_text() !=
      ic_api.retrieve_string_orthogonal(p_owner_principal)) {
    uint16_t status_code = Http::StatusCode::Unauthorized;
    ic_api.to_wire(CandidTypeVariant{"err", CandidTypeNat16{status_code}});
    IC_API::debug_print(std::string(__func__) +
                        ": ERROR - caller is not the owner.");
    return;
  }

  // Get action-server-principal from the wire
  std::string action_server_principal;
  CandidTypeRecord r_in;
  r_in.append("action-server-principal",
              CandidTypeText{&action_server_principal});
  ic_api.from_wire(r_in);
  IC_API::debug_print(std::string(__func__) +
                      ": action_server_principal = " + action_server_principal);

  // Store the value for orthogonal persistence
  ic_api.store_string_orthogonal(action_server_principal,
                                 &p_action_server_principal);
  ic_api.to_wire(CandidTypeVariant{"ok"});
}

// --------------------------------------------------------------------------------------------------
// Called by the django-server as part of login flow
// Create a one time password - Called by front end after Internet Identity Login
void session_password_create() {
  IC_API ic_api(CanisterUpdate{std::string(__func__)}, false);
  CandidTypePrincipal caller = ic_api.get_caller();
  std::string principal = caller.get_text();

  // User must be logged in
  if (caller.is_anonymous()) {
    uint16_t status_code = Http::StatusCode::Unauthorized;
    ic_api.to_wire(CandidTypeVariant{"err", CandidTypeNat16{status_code}});
    return;
  }

  PasswordGenerator pwgen;
  std::string password = pwgen.random_password(8, 16);
  IC_API::debug_print(std::string(__func__) +
                      ": password           = " + password);

  // Store it as a sha256 hash.
  // - This is OK for our 1 time session passwords.
  // - Replace this with a password hasher like bcrypt for permanent passwords.
  SHA256 sha256;
  std::string password_sha256 = sha256(password);
  IC_API::debug_print(std::string(__func__) +
                      ": password_sha256    = " + password_sha256);

  // Retrieve the unordered map from static memory for orthogonal persistence
  std::unordered_map<std::string, std::string> ump =
      ic_api.retrieve_unordered_map_orthogonal(p_principal_password,
                                               len_principal_password);

  // Write the hashed password for the principal
  ump[principal] = password_sha256;

  // Store it back into static memory for othogonal persistence
  ic_api.store_unordered_map_orthogonal(ump, &p_principal_password,
                                        &len_principal_password);

  // Return the session password to caller
  ic_api.to_wire(CandidTypeVariant{"ok", CandidTypeText{password}});
}

// Called by django-server when user logs into it with username=principal & password=session_password
// -> Called during authentication step in custom auth backend
void session_password_check() {
  IC_API ic_api(CanisterQuery{std::string(__func__)}, false);
  CandidTypePrincipal caller = ic_api.get_caller();
  std::string principal = caller.get_text();

  // Caller must be the django server (See README of django-server)
  std::string django_principal =
      ic_api.retrieve_string_orthogonal(p_django_principal);
  if (principal != django_principal) {
    uint16_t status_code = Http::StatusCode::Unauthorized;
    ic_api.to_wire(CandidTypeVariant{"err", CandidTypeNat16{status_code}});
    IC_API::debug_print(std::string(__func__) +
                        ": ERROR - caller is not the django server.");
    IC_API::debug_print(std::string(__func__) +
                        ": caller           = " + principal);
    IC_API::debug_print(std::string(__func__) +
                        ": django_principal = " + django_principal);
    return;
  }

  // Get the data from the wire
  std::string username{""};
  std::string session_password{""};
  std::vector<CandidType> args_in;
  args_in.push_back(CandidTypeText(&username));
  args_in.push_back(CandidTypeText(&session_password));
  ic_api.from_wire(args_in);

  IC_API::debug_print(std::string(__func__) +
                      ": username           = " + username);
  IC_API::debug_print(std::string(__func__) +
                      ": session_password   = " + session_password);

  // Check if the password hash is correct
  SHA256 sha256;
  std::string password_sha256 = sha256(session_password);
  IC_API::debug_print(std::string(__func__) +
                      ": password_sha256    = " + password_sha256);

  // Retrieve the unordered map from static memory for orthogonal persistence
  std::unordered_map<std::string, std::string> ump =
      ic_api.retrieve_unordered_map_orthogonal(p_principal_password,
                                               len_principal_password);
  IC_API::debug_print(std::string(__func__) +
                      ": ump[username]    = " + ump[username]);

  if (password_sha256 == ump[username]) {
    // It's all good
    ic_api.to_wire(CandidTypeVariant{"ok"});
    return;
  }

  IC_API::debug_print(std::string(__func__) + ": ERROR - wrong password.");
  uint16_t status_code = Http::StatusCode::Unauthorized;
  ic_api.to_wire(CandidTypeVariant{"err", CandidTypeNat16{status_code}});
}

// Called by django-server when front end logs into it with username=principal & password=session_password
// -> Called after succesfull login, to store django's session_key for cleanup purposes upon logout
void save_django_session_key() {
  IC_API ic_api(CanisterUpdate{std::string(__func__)}, false);
  // TO BE IMPLEMENTED
  ic_api.to_wire(CandidTypeVariant{"ok"});
}

// Called by django-server when user logs out
void session_password_delete() {
  IC_API ic_api(CanisterUpdate{std::string(__func__)}, false);
  // TO BE IMPLEMENTED
  ic_api.to_wire(CandidTypeVariant{"ok"});
}

// --------------------------------------------------------------------------------------------------
// Called by the chatbot's action server
void save_message() {
  IC_API ic_api(CanisterUpdate{std::string(__func__)}, false);
  CandidTypePrincipal caller = ic_api.get_caller();
  std::string principal = caller.get_text();

  // caller must be the action server
  if (caller.get_text() !=
      ic_api.retrieve_string_orthogonal(p_action_server_principal)) {
    uint16_t status_code = Http::StatusCode::Unauthorized;
    ic_api.to_wire(CandidTypeVariant{"err", CandidTypeNat16{status_code}});
    IC_API::debug_print(std::string(__func__) +
                        ": ERROR - caller is not the action server.");
    return;
  }

  // Get the principal of user & the secret message from the wire
  std::string user_principal{""};
  std::string secret_message{""};
  std::vector<CandidType> args_in;
  args_in.push_back(CandidTypeText(&user_principal));
  args_in.push_back(CandidTypeText(&secret_message));
  ic_api.from_wire(args_in);

  // Retrieve the unordered map from static memory for orthogonal persistence
  std::unordered_map<std::string, std::string> ump =
      ic_api.retrieve_unordered_map_orthogonal(p_principal_message,
                                               len_principal_message);

  // Write the secret message for the principal
  ump[user_principal] = secret_message;

  // Store it back into static memory for othogonal persistence
  ic_api.store_unordered_map_orthogonal(ump, &p_principal_message,
                                        &len_principal_message);

  // Return 'ok'
  ic_api.to_wire(CandidTypeVariant{"ok"});
}

// --------------------------------------------------------------------------------------------------
// Called from CandidUI or dfx
void get_message() {
  IC_API ic_api(CanisterQuery{std::string(__func__)}, false);
  CandidTypePrincipal caller = ic_api.get_caller();
  std::string principal = caller.get_text();

  // unprotected method. Anyone can call
  // ...

  // Get the principal of user & the secret message from the wire
  std::string user_principal{""};
  ic_api.from_wire(CandidTypeText(&user_principal));

  // Retrieve the unordered map from static memory for orthogonal persistence
  std::unordered_map<std::string, std::string> ump =
      ic_api.retrieve_unordered_map_orthogonal(p_principal_message,
                                               len_principal_message);

  std::optional<std::string> secret_message;
  if (ump.find(user_principal) != ump.end()) {
    secret_message = ump[user_principal];
  }

  ic_api.to_wire(CandidTypeOptText{secret_message});
}

// --------------------------------------------------------------------------------------------------
// Two test functions, not used by chatbot in production
void greet() {
  IC_API ic_api(CanisterQuery{std::string(__func__)}, false);
  std::string name{""};
  ic_api.from_wire(CandidTypeText{&name});
  ic_api.to_wire(CandidTypeText{
      "hello " + name + "! from a C++ backend canister, build with icpp-pro."});
}

void whoami() {
  IC_API ic_api(CanisterQuery{std::string(__func__)}, false);
  CandidTypePrincipal caller = ic_api.get_caller();
  ic_api.to_wire(CandidTypeText("Your principal is " + caller.get_text()));

  // Also print some debug checks during local development
  IC_API::debug_print(std::string(__func__) + ": owner_principal  = " +
                      ic_api.retrieve_string_orthogonal(p_owner_principal));
  IC_API::debug_print(std::string(__func__) + ": django_principal = " +
                      ic_api.retrieve_string_orthogonal(p_django_principal));
  IC_API::debug_print(
      std::string(__func__) + ": action_server_principal = " +
      ic_api.retrieve_string_orthogonal(p_action_server_principal));
  // ---
}

// --------------------------------------------------------------------------------------------------
// for debug only
void debug_1() {
  IC_API ic_api(CanisterQuery{std::string(__func__)}, false);
  CandidTypePrincipal caller = ic_api.get_caller();

  std::string owner_principal =
      ic_api.retrieve_string_orthogonal(p_owner_principal);
  std::string django_principal =
      ic_api.retrieve_string_orthogonal(p_django_principal);
  std::string action_server_principal =
      ic_api.retrieve_string_orthogonal(p_action_server_principal);

  std::vector<CandidType> args_out;
  args_out.push_back(CandidTypeText(owner_principal));
  args_out.push_back(CandidTypeText(django_principal));
  args_out.push_back(CandidTypeText(action_server_principal));
  ic_api.to_wire(args_out);
}