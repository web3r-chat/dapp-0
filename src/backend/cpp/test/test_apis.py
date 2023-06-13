"""Test canister APIs

   First deploy the canister, then run:

   $ pytest --network=[local/ic] test_apis.py

"""
# pylint: disable=unused-argument, missing-function-docstring, unused-import, wildcard-import, unused-wildcard-import, line-too-long

from pathlib import Path
import pytest
from icpp.smoketest import call_canister_api

# Path to the dfx.json file
DFX_JSON_PATH = Path(__file__).parent / "../dfx.json"

# Canister in the dfx.json file we want to test
CANISTER_NAME = "canister_cpp"


def test__greet(network: str, principal: str) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="greet",
        canister_argument='("C++ Developer")',
        network=network,
    )
    expected_response = (
        '("hello C++ Developer! from a C++ backend canister, build with icpp-pro.")'
    )
    assert response == expected_response


def test__whoami(network: str, principal: str) -> None:
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="whoami",
        canister_argument="()",
        network=network,
    )
    expected_response = f'("Your principal is {principal}")'
    assert response == expected_response


# Run this test with anonymous identity
def test__session_password_create_err(
    identity_anonymous: dict[str, str], network: str
) -> None:
    # double check the identity_anonymous fixture worked
    assert identity_anonymous["identity"] == "anonymous"
    assert identity_anonymous["principal"] == "2vxsx-fae"

    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="session_password_create",
        canister_argument="()",
        network=network,
    )
    expected_response = "(variant { err = 401 : nat16 })"
    assert response == expected_response


# Run this test with default identity
def test__session_password_create_ok(
    identity_default: dict[str, str], network: str
) -> None:
    # double check the identity_anonymous fixture worked
    assert identity_default["identity"] == "default"

    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="session_password_create",
        canister_argument="()",
        network=network,
    )
    assert "ok" in response

    ####################################################
    # now call the session_password_check method

    # Make sure this fails
    response = call_canister_api(
        dfx_json_path=DFX_JSON_PATH,
        canister_name=CANISTER_NAME,
        canister_method="session_password_check",
        canister_argument='("2vxsx-fae", "a-pw")',
        network=network,
    )
    expected_response = "(variant { err = 401 : nat16 })"
    assert response == expected_response
