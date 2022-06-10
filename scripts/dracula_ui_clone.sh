#!/usr/bin/env bash
if [ -f .env ]; then
    echo "Loading environment variables from .env"
    export $(cat .env | grep -v '#' | xargs) && cd .. && git clone https://${GITHUB_PAT_FOR_DRACULA_UI}@github.com/dracula/dracula-ui.git
else
    echo "Cannot find .env - assuming environment variables are set"
    cd .. && git clone https://${GITHUB_PAT_FOR_DRACULA_UI}@github.com/dracula/dracula-ui.git
fi