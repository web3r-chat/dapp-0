# dapp-0

React frontend & motoko smart contract for our first Rasa Chatbot for the Internet Computer.

The live deployment can be found at https://web3r.chat

The full application consists of 3 GitHub repositories:
1. [dapp-0](https://github.com/web3r-chat/dapp-0)
2. [dapp-0-django](https://github.com/web3r-chat/dapp-0-django)
3. [dapp-0-bot](https://github.com/web3r-chat/dapp-0-bot)

# Setup

## Conda

[Download MiniConda](https://docs.conda.io/en/latest/miniconda.html#linux-installers) and then install it:

```bash
bash Miniconda3-xxxxx.sh
```

Create a conda environment with NodeJS & Python 3.9:

```bash
conda create --name dapp-0 nodejs python=3.9
conda activate dapp-0
```

## git

```bash
git clone git@github.com:web3r-chat/dapp-0.git
cd dapp-0
```

### pre-commit

Create this pre-commit script, file `.git/hooks/pre-commit`

```bash
#!/bin/bash

# Apply all static auto-formatting & perform the static checks
export PATH="$HOME/miniconda3/envs/dapp-0/bin:$PATH"
/usr/bin/make all-static
```

and make the script executable:

```bash
chmod +x .git/hooks/pre-commit
```



## Dracula UI

All color styling is done using [Dracula UI](https://draculatheme.com/ui), 

This styling library is not Open Source, and we plan to swap it out for an open source library.

After purchasing a license, do the following, so the install scripts will be able to install it:

- Create a [GitHub Personal Access Token](https://github.com/settings/tokens/new)

- Store it in a `.env` file in the root of this repo, as:

  ```bash
  # GitHub Personal Access Token to install Dracula UI
  GITHUB_PAT_FOR_DRACULA_UI=ghp_...
  ```



## toolchain & dependencies

Install the toolchain:

- The [dfinity/sdk release version](dfinity/sdk release version) is specified in `dfx.json`
- We use [vessel](https://github.com/dfinity/vessel) to include motoko package sets curated in the [vessel-package-set.](https://github.com/kritzcreek/vessel-package-set/tree/main/index) (See Appendix B below)

```bash
conda activate dapp-0
make install-all

# ~/bin must be on path
source ~/.profile

# Verify all tools are available
dfx --version
vessel --version

# verify all other items are working
make all-static-check
```



# Development

## Start local network

```bash
make dfx-start-local

# stop it with
make dfx-stop-local
```

## Deploy internet_identity

Our dapp is using internet identity for authentication.

To be able to develop the dapp locally, we must deploy the Internet Identity canister to the local network:

- Start the local network as described above

- clone the [Internet Identity](https://github.com/dfinity/internet-identity) repo and deploy the internet identity canister:

  ```bash
  # Use a conda environment with nodejs
  conda create --name internet-identity nodejs
  conda activate internet-identity
  
  # Clone internet-identity as a sibling repository on your computer
  cd ../
  git clone git@github.com:dfinity/internet-identity.git
  cd internet-identity
  npm install
  
  # Install internet identity canister into your running local network
  rm -rf .dfx/local
  II_ENV=development II_DUMMY_AUTH=1 II_DUMMY_CAPTCHA=1 II_FETCH_ROOT_KEY=1 dfx deploy --no-wallet --argument '(null)'
  ```

- Use the canister ID of the `internet_identity canister` for the `II_URL_LOCAL` variable on line `8` in our `webpack.config.js`:

  ```javascript
  // file: webpack.config.js
  
  // Replace ID with your local internet_identity canister
  const II_URL_LOCAL = 'http://<ID>.localhost:8000'
  ```

  

## Deploy dapp-0

Deploy the dapp to the local network with:

```bash
# from root directory

conda activate dapp-0

# Start local network
make dfx-start-local

# Deploy
make dfx-deploy-local
```



## Frontend Development

The frontend is a react application with a webpack based build pipeline. Webpack builds with sourcemaps, so you can use the devtools of the browser for debugging:

- Run frontend with npm development server:

  ```bash
  # from root directory
  
  conda activate dapp-0
  
  # start the development server, with hot reloading
  npm run start
  
  # to rebuild from scratch
  npm run build
  ```

- Open the browser at http://localhost:8080 & open the browser devtools

- Make changes to the frontend code in your favorite editor, and when you save it, everything will auto-rebuild and auto-reload
