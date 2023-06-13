#pragma once

#include "wasm_symbol.h"
#include <string>

void canister_init() WASM_SYMBOL_EXPORTED("canister_init");
void set_django_principal()
    WASM_SYMBOL_EXPORTED("canister_update set_django_principal");
void set_action_server_principal()
    WASM_SYMBOL_EXPORTED("canister_update set_action_server_principal");

void session_password_create()
    WASM_SYMBOL_EXPORTED("canister_update session_password_create");
void session_password_check()
    WASM_SYMBOL_EXPORTED("canister_query session_password_check");
void save_django_session_key()
    WASM_SYMBOL_EXPORTED("canister_update save_django_session_key");
void session_password_delete()
    WASM_SYMBOL_EXPORTED("canister_update session_password_delete");

void save_message() WASM_SYMBOL_EXPORTED("canister_update save_message");

void get_message() WASM_SYMBOL_EXPORTED("canister_query get_message");

void greet() WASM_SYMBOL_EXPORTED("canister_query greet");
void whoami() WASM_SYMBOL_EXPORTED("canister_query whoami");
void debug_1() WASM_SYMBOL_EXPORTED("canister_query debug_1");