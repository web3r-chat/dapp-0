# pylint: disable=missing-function-docstring, line-too-long
"""Integration Tests for login flow.

Following services must be up & running prior to running this test:
  (-) canister_motoko
  (-) django
  (-) bot-0

After configuring each component as described in their respective README files,
you run these services locally with these commands:
  (-) canister_motoko:
      $ cd path-to/dapp-0 (root folder of dapp-0 repo)
      $ conda activate dapp-0  (See dapp-0/README.md for conda setup)
      $ make dfx-start-local
      $ make dfx-deploy-local
      $ make smoketest CANISTER_NAME=canister_motoko
      $ make dfx-canisters-of-project-local  # copy ID of canister_motoko

  (-) django
      $ cd path-to/dapp-0-django (root folder of dapp-0-django repo)
      $ conda activate dapp-0-django (See dapp-0-django/README.md for conda setup)
      $ make docker-services-up
      $ make run-with-runserver
      $ make smoketest

      # shut down with:
      # CTRL+C for running django server
      $ make docker-services-down

  (-) rasa server
      $ cd path-to/dapp-0-bot
      $ conda activate dapp-0-bot
      $ rasa run

  (-) rasa action server
      $ cd path-to/dapp-0-bot
      $ conda activate dapp-0-bot
      $ rasa run actions

Now you can run the integration test for the login flow (this file...):

  with make:
    $ make integrationtest NETWORK=[local/ic] DJANGO_URL=<URL> BOT_URL=<URL> INTEGRATION_TEST=[login_flow]

    For example:
    $ make integrationtest
    $ make integrationtest NETWORK=local DJANGO_URL=http://127.0.0.1:8001 BOT_URL=http://127.0.0.1:5005 INTEGRATION_TEST=login_flow

  or, directly with pytest

    $ pytest --network=[local/ic] --django-url=<URL> --bot-url=<URL> test/backend/test__login_flow.py

    For example:
    $ pytest --network=local --django-url=http://127.0.0.1:8001                               --bot-url=http://127.0.0.1:5005                       test/backend/test__login_flow.py
    $ pytest --network=ic    --django-url=https://django-server-main-xec55.ondigitalocean.app --bot-url=https://bot-0-main-3h249.ondigitalocean.app test/backend/test__login_flow.py

  or, you can also run the integration test from within the Wing IDE:
    (-) Configure the pytest configuration with the pytest arguments
    (-) Then run a pytest in Wing IDE as usual


Note that we use pytest for this integration test, with custom fixtures for:
  (-) the IC network to use:  --network=[local/ic]    (default=local)
  (-) the django-server URL:  --django-url=......     (default=http://127.0.0.1:8001)
  (-) the bot-0 URL        :  --bot-url=......        (default=http://127.0.0.1:5005)
  These fixtures are defined in conftest.py
"""

import json
from typing import Dict
import requests
import socketio  # type: ignore
import pytest  # pylint: disable=unused-import
from .scripts.smoketest import smoketest


def test__login_flow(
    network: str, django_url: str, bot_url: str, identity_default: Dict[str, str]
) -> None:

    # Step 1: call canister_motoko to create a random password and store it internally
    #  (-) this call is only valid for a user that is authenticated with the IC.
    #  (-) we use the fixture `identity_default`, which tells dfx to use the 'default'
    #      identity, which is an authenticated user with the IC.
    response_canister = smoketest(
        canister_name="canister_motoko",
        canister_method="session_password_create",
        network=network,
        expected_response_startswith="(variant { ok = ",
    )
    session_password = response_canister.split('"')[1]
    assert len(session_password) == 43

    # Use requests' session object, to automatically send the session cookies that
    # Django returns after a successfull login. The cookies are:
    #  - csrftoken
    #  - sessionid
    # https://docs.python-requests.org/en/latest/user/advanced/#session-objects
    with requests.Session() as s:

        # Step 2: call django-server to login & create a JWT
        #  (-) django-server will verify the password with canister_motoko
        #  (-) if ok, it will:
        #      (-) create a Django user with username=principal, if not yet exists
        #      (-) create a cookie based login session for that user
        #      (-) generate a JWT and return it
        url = f"{django_url}/api/v1/icauth/login"
        payload = json.dumps(
            {
                "principal": identity_default["principal"],
                "session_password": session_password,
            }
        )
        headers = {
            "Content-Type": "application/json",
        }

        response_http = s.post(url, headers=headers, data=payload)
        assert response_http.status_code == 200
        jwt_token = response_http.json().get("jwt")
        assert jwt_token is not None

        # Step 3: connect to bot-0, using the JWT in the socket io
        sio = socketio.Client()

        @sio.on("connect")  # type: ignore
        def on_connect() -> None:
            """."""
            print(f"- Connected to socket.io - Session ID = {sio.sid}")

        sio.connect(
            bot_url,
            headers={},
            auth={"token": jwt_token},
            transports=None,
            namespaces=None,
            socketio_path="socket.io",
            wait=True,
            wait_timeout=1,
        )

        # Step 3: disconnect from bot-0
        sio.disconnect()

        # Step 4: call django-server to logout
        url = f"{django_url}/api/v1/icauth/logout"
        response_http = s.post(url)
        assert response_http.status_code == 200
