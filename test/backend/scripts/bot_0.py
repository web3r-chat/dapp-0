"""Helper functions to get the bot-0 status"""
from typing import Any, Optional
import sys
import time
import pprint
import requests
from requests import request

HEALTH_CHECK_RETRIES = 5
SLEEP_TIME = 1
VERBOSE = 1


def my_print(msg: Any, status_code: Optional[int] = None) -> None:
    """Pretty print msg"""
    if VERBOSE > 0:
        if status_code:
            print(f"status_code: {status_code}")

        if isinstance(msg, (list, dict)):
            pprint.pprint(msg)
        else:
            print(msg)


def health(bot_url: str) -> Any:
    """Returns the bot-0 status."""
    url = f"{bot_url}"
    attempt = 0
    while True:
        try:
            attempt += 1
            r = request("GET", url)

            if r.status_code == 200:
                my_print(f"bot-0 health check - attempt {attempt} succeeded")
                break

            my_print(f"bot-0 health check - attempt {attempt} failed")
            my_print(r.json(), r.status_code)
            return r.json()
        except requests.exceptions.ConnectionError as _err:
            my_print(
                f"bot-0 health check - attempt {attempt} "
                f"failed with requests.exceptions.ConnectionError"
            )

        if attempt < HEALTH_CHECK_RETRIES:
            time.sleep(SLEEP_TIME)
            continue

        my_print("Too many failures...")
        sys.exit(1)

    return "Should not get here..."
