SHELL := /bin/bash

# Disable built-in rules and variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

NETWORK ?= local
IDENTITY ?= $(shell dfx identity whoami)

###########################################################################
# OS we're running on
ifeq ($(OS),Windows_NT)
	detected_OS := Windows
else
	detected_OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
endif

ifeq ($(detected_OS),Darwin)	  # Mac OS X  (Intel)
	OS += macos
	DIDC += didc-macos
endif
ifeq ($(detected_OS),Linux)		  # Ubuntu
	OS += linux
	DIDC += didc-linux64 
endif

ifeq ($(detected_OS),Windows_NT)  # Windows (Not supported)
	OS += windows_not_suppoorted
endif
ifeq ($(detected_OS),Unknown)     # Unknown
	OS += unknown_not_suppoorted
endif


DJANGO_PRINCIPAL_LOCAL ?= $(shell cat secret/local/django-principal.txt)
ACTION_SERVER_PRINCIPAL_LOCAL ?= $(shell cat secret/local/action-server-principal.txt)

DJANGO_PRINCIPAL_IC ?= $(shell cat secret/ic/django-principal.txt)
ACTION_SERVER_PRINCIPAL_IC ?= $(shell cat secret/ic/action-server-principal.txt)

.PHONY: dfx-deploy-local
dfx-deploy-local:
	dfx identity use default
	dfx deploy canister_cpp --mode reinstall
	dfx canister call canister_cpp set_django_principal '(record {"django-principal" = "$(DJANGO_PRINCIPAL_LOCAL)";})'
	dfx canister call canister_cpp set_action_server_principal '(record {"action-server-principal" = "$(ACTION_SERVER_PRINCIPAL_LOCAL)";})'
	dfx canister call canister_cpp debug_1

.PHONY: dfx-deploy-ic
dfx-deploy-ic:
	dfx identity use cicd
	dfx deploy canister_cpp --network ic --mode reinstall
	dfx canister --network ic call canister_cpp set_django_principal '(record {"django-principal" = "$(DJANGO_PRINCIPAL_IC)";})'
	dfx canister --network ic call canister_cpp set_action_server_principal '(record {"action-server-principal" = "$(ACTION_SERVER_PRINCIPAL_IC)";})'
	dfx identity use default
	dfx canister --network ic call canister_cpp debug_1