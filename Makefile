SHELL := /bin/bash

# Disable built-in rules and variables
MAKEFLAGS += --no-builtin-rules
MAKEFLAGS += --no-builtin-variables

NETWORK ?= local
IDENTITY ?= $(shell dfx identity whoami)

###########################################################################
# toolchain versions
DFX_VERSION ?= $(shell cat dfx.json | jp dfx)
VERSION_VESSEL ?= $(shell cat version_vessel.txt)

###########################################################################
# Some constants
CANISTER_INSTALL_MODE ?= install
CANISTER_CANDID_UI_IC ?= "a4gq6-oaaaa-aaaab-qaa4q-cai"
COMMIT_JSON ?= "src/frontend/assets/deploy-info/commit.json"

###########################################################################
# Unit testing of canisters
CANISTER_DIR ?= src/backend/motoko
CANISTER_NAME ?= canister_motoko
TEST_CANISTER_PY ?= test/backend/test__$(CANISTER_NAME).py

# To call a canister method with dfx-canister-call
CANISTER_METHOD ?= greet
CANISTER_ARGUMENT ?= ("T. Ester")
CANISTER_OUTPUT ?= pp
CANISTER_INPUT ?= idl

###########################################################################
# The integration test, with django-server & bot-0
INTEGRATION_TEST ?= login_flow
TEST_INTEGRATION_PY ?= test/backend/test__$(INTEGRATION_TEST).py
DJANGO_URL ?= http://127.0.0.1:8001
BOT_URL ?= http://127.0.0.1:5005


.PHONY: build-motoko-canister
build-motoko-canister:
	dfx build canister_motoko 

.PHONY: all-static
all-static: \
	python-format python-lint \
	javascript-format javascript-lint
	
.PHONY: all-static-check
all-static-check: \
	python-format-check python-lint-check python-type-check \
	javascript-format-check javascript-lint-check

git-no-unstaged-files:
	@if [[ $$(git diff --name-only) ]]; then \
		echo " "; \
		echo "Unstaged Files ($$(git diff --name-only | wc -w)):"; \
		git diff --name-only | awk '{print "- " $$1}'; \
		echo " "; \
		echo "There are unstaged files in your working directory."; \
		echo "Please only deploy to ic from a freshly pulled main branch."; \
		echo " "; \
		exit 1; \
	else \
		echo "Ok, you have no unstaged files in your working directory." ;\
	fi

git-no-staged-files:
	@if [[ $$(git diff --cached --name-only) ]]; then \
		echo " "; \
		echo "Staged Files ($$(git diff --cached --name-only | wc -w)):"; \
		git diff --cached --name-only | awk '{print "- " $$1}'; \
		echo " "; \
		echo "There are staged files in your working directory."; \
		echo "Please only deploy to ic from a freshly pulled main branch."; \
		echo " "; \
		exit 1; \
	else \
		echo "Ok, you have no staged files in your working directory." ;\
	fi

git-on-origin-main:
	@if [[ $$(git log origin/main..HEAD --first-parent --oneline | awk '{print $$1}' | wc -w) > 0 ]]; then \
		echo " "; \
		echo "Your working directory is not at origin/main:"; \
		git log origin/main..HEAD --first-parent --oneline --boundary; \
		echo " "; \
		echo "Please only deploy to ic from a freshly pulled main branch."; \
		echo " "; \
		exit 1; \
	else \
		echo "Ok, your working directory is at orgin/main" ;\
	fi

# This installs ~/bin/dfx
# Make sure to source ~/.profile afterwards -> it adds ~/bin to the path if it exists
.PHONY: dfx-install
dfx-install:
	sh -ci "$$(curl -fsSL https://sdk.dfinity.org/install.sh)"
	
.PHONY: dfx-canisters-of-project-ic
dfx-canisters-of-project-ic:
	@$(eval CANISTER_WALLET := $(shell dfx identity --network ic get-wallet))
	@$(eval CANISTER_MOTOKO := $(shell dfx canister --network ic id canister_motoko))
	@$(eval CANISTER_FRONTEND := $(shell dfx canister --network ic id canister_frontend))

	@echo '-------------------------------------------------'
	@echo "NETWORK            : ic"
	@echo "cycles canister    : $(CANISTER_WALLET)"
	@echo "Candid UI canister : $(CANISTER_CANDID_UI_IC)"
	@echo "canister_motoko    : $(CANISTER_MOTOKO)"
	@echo "canister_frontend  : $(CANISTER_FRONTEND)"
	@echo '-------------------------------------------------'
	@echo 'View in browser at:'
	@echo  "cycles canister                : https://$(CANISTER_WALLET).raw.ic0.app/"
	@echo  "Candid UI                      : https://$(CANISTER_CANDID_UI_IC).raw.ic0.app/"
	@echo  "Candid UI of canister_motoko   : https://$(CANISTER_CANDID_UI_IC).raw.ic0.app/?id=$(CANISTER_MOTOKO)"
	@echo  "Candid UI of canister_frontend : https://$(CANISTER_CANDID_UI_IC).raw.ic0.app/?id=$(CANISTER_FRONTEND)"
	@echo  "canister_motoko                : https://$(CANISTER_MOTOKO).ic0.app/"
	@echo  "canister_frontend              : https://$(CANISTER_FRONTEND).ic0.app/"

.PHONY: dfx-canisters-of-project-local
dfx-canisters-of-project-local:
	@$(eval CANISTER_WALLET := $(shell dfx identity get-wallet))
	@$(eval CANISTER_CANDID_UI_LOCAL ?= $(shell dfx canister id __Candid_UI))
	@$(eval CANISTER_MOTOKO := $(shell dfx canister id canister_motoko))
	@$(eval CANISTER_FRONTEND := $(shell dfx canister id canister_frontend))

	
	@echo '-------------------------------------------------'
	@echo "NETWORK            : local"
	@echo "cycles canister    : $(CANISTER_WALLET)"
	@echo "Candid UI canister : $(CANISTER_CANDID_UI_IC)"
	@echo "canister_motoko    : $(CANISTER_MOTOKO)"
	@echo "canister_frontend  : $(CANISTER_FRONTEND)"
	@echo '-------------------------------------------------'
	@echo 'View in browser at:'
	@echo  "__Candid_UI                    : http://localhost:8000?canisterId=$(CANISTER_CANDID_UI_LOCAL)"
	@echo  "Candid UI of canister_motoko   : http://localhost:8000?canisterId=$(CANISTER_CANDID_UI_LOCAL)&id=$(CANISTER_MOTOKO)"
	@echo  "Candid UI of canister_frontend : http://localhost:8000?canisterId=$(CANISTER_CANDID_UI_LOCAL)&id=$(CANISTER_FRONTEND)"
	@echo  "canister_motoko (http_request) : http://localhost:8000?canisterId=$(CANISTER_MOTOKO)"
	@echo  "canister_frontend              : http://localhost:8000?canisterId=$(CANISTER_FRONTEND)"

.PHONY: dfx-canisters-of-project
dfx-canisters-of-project:
	@if [[ ${NETWORK} == "ic" ]]; then \
		make --no-print-directory dfx-canisters-of-project-ic; \
	else \
		make --no-print-directory dfx-canisters-of-project-local; \
	fi

.PHONY: dfx-canister-methods
dfx-canister-methods:
	@echo "make dfx-canister-methods CANISTER_NAME=$(CANISTER_NAME)"
	@echo "NETWORK            : $(NETWORK)"
	@echo "CANISTER_NAME           : $(CANISTER_NAME)"
	@echo "View the canister's interface (i.e. the candid methods) at :"
	@echo "- Candid UI: https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.ic0.app/?id=$(CANISTER_NAME)"
	@echo "- icrocks  : https://ic.rocks/principal/$(CANISTER_NAME)"
	@echo "- Canlist  : https://k7gat-daaaa-aaaae-qaahq-cai.ic0.app/search?s=$(CANISTER_NAME)"
	@echo "-------------------------------------------------------------------------"
	@echo "Checking if it is listed at Canlista"
	@dfx canister --network $(NETWORK) call kyhgh-oyaaa-aaaae-qaaha-cai getCandid '(principal "$(CANISTER_NAME)")'

.PHONY: dfx-canister-create
dfx-canister-create:
	@echo "make dfx-canister-create CANISTER_NAME=$(CANISTER_NAME)"
	@echo "NETWORK            : $(NETWORK)"
	@echo "CANISTER_NAME      : $(CANISTER_NAME)"
	@dfx canister --network $(NETWORK) create $(CANISTER_NAME)

.PHONY: dfx-canister-stop
dfx-canister-stop:
	@echo "make dfx-canister-stop CANISTER_NAME=$(CANISTER_NAME)"
	@echo "NETWORK            : $(NETWORK)"
	@echo "CANISTER_NAME      : $(CANISTER_NAME)"
	@dfx canister --network $(NETWORK) stop $(CANISTER_NAME)

.PHONY: dfx-canister-delete
dfx-canister-delete:
	@echo "make dfx-canister-delete CANISTER_NAME=$(CANISTER_NAME)"
	@echo "NETWORK            : $(NETWORK)"
	@echo "CANISTER_NAME      : $(CANISTER_NAME)"
	@dfx canister --network $(NETWORK) stop $(CANISTER_NAME)
	@dfx canister --network $(NETWORK) delete $(CANISTER_NAME)

.PHONY: dfx-canister-install-upgrade
dfx-canister-install-upgrade:
	@make --no-print-directory dfx-canister-install CANISTER_INSTALL_MODE=upgrade

.PHONY: dfx-canister-install-reinstall
dfx-canister-install-reinstall:
	@make --no-print-directory dfx-canister-install CANISTER_INSTALL_MODE=reinstall

.PHONY: dfx-canister-install
dfx-canister-install:
	@echo "make dfx-canister-install CANISTER_NAME=$(CANISTER_NAME)"
	@echo "NETWORK            : $(NETWORK)"
	@echo "CANISTER_NAME      : $(CANISTER_NAME)"
	@dfx canister --network $(NETWORK) install --mode $(CANISTER_INSTALL_MODE) $(CANISTER_NAME)

.PHONY: dfx-canister-call
dfx-canister-call:
	@dfx canister --network $(NETWORK) call --output $(CANISTER_OUTPUT) --type $(CANISTER_INPUT) $(CANISTER_NAME) $(CANISTER_METHOD) '$(CANISTER_ARGUMENT)'

.PHONY: dfx-deploy-local
dfx-deploy-local:
	@dfx deploy
	@echo  "All done.... Getting details... "
	@make --no-print-directory dfx-canisters-of-project

.PHONY: dfx-deploy-ic
dfx-deploy-ic:
	
	# @echo " "	
	# @echo "--Check that working directory is a freshly pulled main branch--"
	# @make --no-print-directory git-on-origin-main
	# @make --no-print-directory git-no-unstaged-files
	# @make --no-print-directory git-no-staged-files
	
	@echo " "	
	@echo "--Test Code--"
	@make --no-print-directory test

	@echo " "
	@echo "--Set commit sha for About page (file: $(COMMIT_JSON))--"
	@echo '{ "sha": "'$$(git log -1 --format='%h')'" }' > $(COMMIT_JSON)
	@cat $(COMMIT_JSON)
	
	@echo " "
	@echo "--Deploy--"
	@dfx deploy --network ic

	@echo " "
	@echo "--Discarding file $(COMMIT_JSON) --"
	@git checkout -- $(COMMIT_JSON)
	@cat $(COMMIT_JSON)


	@echo "--All done.... Get canister details..--"
	@make --no-print-directory dfx-canisters-of-project NETWORK=ic

.PHONY: dfx-identity-and-wallet-for-cicd
dfx-identity-and-wallet-for-cicd:
	@echo $(DFX_IDENTITY_PEM_ENCODED) | base64 --decode > identity-cicd.pem
	@dfx identity import cicd ./identity-cicd.pem
	@rm ./identity-cicd.pem
	@dfx identity use cicd
	@dfx identity --network ic set-wallet "$(DFX_WALLET_CANISTER_ID)"

.PHONY: dfx-identity-use
dfx-identity-use:
	@dfx identity use $(IDENTITY)

.PHONY: dfx-identity-whoami
dfx-identity-whoami:
	@echo -n $(shell dfx identity whoami)
	
.PHONY: dfx-identity-get-principal
dfx-identity-get-principal:
	@echo -n $(shell dfx identity get-principal)

.PHONY: dfx-ping
dfx-ping:
	@dfx ping $(NETWORK)

.PHONY: dfx-start-local
dfx-start-local:
	@dfx stop
	@dfx start --clean --background

.PHONY: dfx-stop-local
dfx-stop-local:
	@dfx stop


.PHONY: dfx-wallet-details
dfx-wallet-details:
	@$(eval CANISTER_WALLET := $(shell dfx identity --network $(NETWORK) get-wallet))
	@echo "-------------------------------------------------------------------------"
	@echo "make dfx-wallet-details NETWORK=$(NETWORK)"
	@if [[ ${NETWORK} == "ic" ]]; then \
		echo  "View details at         : https://$(CANISTER_WALLET).raw.ic0.app/"; \
	else \
		echo  "View details at         : ?? http://localhost:8000?canisterId=$(CANISTER_WALLET) ?? "; \
	fi
	
	@echo "-------------------------------------------------------------------------"
	@echo -n "cycles canister id      : " && dfx identity --network $(NETWORK) get-wallet
	@echo -n "cycles canister name    : " && dfx wallet --network $(NETWORK) name
	@echo -n "cycles canister balance : " && dfx wallet --network $(NETWORK) balance
	@echo "-------------------------------------------------------------------------"
	@echo "controllers: "
	@dfx wallet --network $(NETWORK) controllers
	@echo "-------------------------------------------------------------------------"
	@echo "custodians: "
	@dfx wallet --network $(NETWORK) custodians
	@echo "-------------------------------------------------------------------------"
	@echo "addresses: "
	@dfx wallet --network $(NETWORK) addresses

.PHONY: dfx-wallet-controller-add
dfx-wallet-controller-add:
	@[ "${PRINCIPAL}" ]	|| ( echo ">> Define PRINCIPAL to add as controller: 'make dfx-cycles-controller-add PRINCIPAL=....' "; exit 1 )
	@echo    "NETWORK         : $(NETWORK)"
	@echo    "PRINCIPAL       : $(PRINCIPAL)"
	@dfx wallet --network $(NETWORK) add-controller $(PRINCIPAL)

.PHONY: dfx-wallet-controller-remove
dfx-wallet-controller-remove:
	@[ "${PRINCIPAL}" ]	|| ( echo ">> Define PRINCIPAL to remove as controller: 'make dfx-cycles-controller-remove PRINCIPAL=....' "; exit 1 )
	@echo    "NETWORK         : $(NETWORK)"
	@echo    "PRINCIPAL       : $(PRINCIPAL)"
	@dfx wallet --network $(NETWORK) remove-controller $(PRINCIPAL)

.PHONY: javascript-format
javascript-format:
	@echo "---"
	@echo "javascript-format"
	npm run format:write

.PHONY: javascript-format-check
javascript-format-check:
	@echo "---"
	@echo "javascript-format-check"
	npm run format:check

.PHONY: javascript-lint
javascript-lint:
	@echo "---"
	@echo "javascript-lint"
	npm run lint:fix

.PHONY: javascript-lint-check
javascript-lint-check:
	@echo "---"
	@echo "javascript-lint-check"
	npm run lint:check

.PHONY: python-clean
python-clean:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f  {} +

PYTHON_DIRS ?= scripts test

.PHONY: python-format
python-format:
	@echo "---"
	@echo "python-format"
	python -m black $(PYTHON_DIRS)

.PHONY: python-format-check
python-format-check:
	@echo "---"
	@echo "python-format-check"
	python -m black --check $(PYTHON_DIRS)

.PHONY: python-lint
python-lint:
	@echo "---"
	@echo "python-lint"
	python -m pylint --jobs=0 --rcfile=.pylintrc $(PYTHON_DIRS)

.PHONY: python-lint-check
python-lint-check:
	@echo "---"
	@echo "python-lint-check"
	python -m pylint --jobs=0 --rcfile=.pylintrc $(PYTHON_DIRS)

.PHONY: python-type-check
python-type-check:
	@echo "---"
	@echo "python-type-check"
	python -m mypy --config-file .mypy.ini --show-column-numbers --strict $(PYTHON_DIRS)

.PHONY: smoketest
smoketest:
	pytest --network=$(NETWORK) $(TEST_CANISTER_PY)

.PHONY: integrationtest
integrationtest:
	pytest --network=$(NETWORK) --django-url=$(DJANGO_URL) --bot-url=$(BOT_URL) $(TEST_INTEGRATION_PY)


###########################################################################
# Toolchain installation
.PHONY: install-all
install-all: install-jp install-dfx install-javascript install-python install-vessel

# This installs ~/bin/dfx
# Make sure to source ~/.profile afterwards -> it adds ~/bin to the path if it exists
.PHONY: install-dfx
install-dfx:
	DFX_VERSION=$(DFX_VERSION) sh -ci "$$(curl -fsSL https://sdk.dfinity.org/install.sh)"

.PHONY: install-javascript
install-javascript:
	./scripts/dracula_ui_install.sh
	npm install

.PHONY: install-jp
install-jp:
	sudo apt-get update && sudo apt-get install jp

.PHONY: install-python
install-python:
	pip install --upgrade pip
	pip install -r requirements-dev.txt

# .PHONY:install-rust
# install-rust:
# 	@echo "Installing rust"
# 	curl https://sh.rustup.rs -sSf | sh -s -- -y
# 	@echo "Installing ic-cdk-optimizer"
# 	cargo install ic-cdk-optimizer

.PHONY: install-vessel
install-vessel:
	@echo "Installing $(VERSION_VESSEL) ..."
	sudo rm -rf /usr/local/bin/vessel
	rm -f vessel-linux64
	wget https://github.com/kritzcreek/vessel/releases/download/$(VERSION_VESSEL)/vessel-linux64
	chmod +x vessel-linux64
	sudo mv vessel-linux64 /usr/local/bin/vessel
	@echo " "
	@echo "Installed successfully in:"
	@echo /usr/local/bin/vessel