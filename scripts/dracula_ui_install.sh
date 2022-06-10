#!/usr/bin/env bash
if [ -f .env ]; then
    echo "Loading environment variables from .env"
    export $(cat .env | grep -v '#' | xargs) && npm install @dracula/dracula-ui
else
    echo "Cannot find .env - assuming environment variables are set"
    npm install @dracula/dracula-ui
fi