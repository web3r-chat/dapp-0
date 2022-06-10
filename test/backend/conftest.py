"""The pytest fixtures
   https://docs.pytest.org/en/latest/fixture.html
"""

from typing import Any, Dict, Generator
import pytest


from .scripts import network_utils, django_server, bot_0
from .scripts.identity import get_identity, set_identity, get_principal


def pytest_addoption(parser: Any) -> None:
    """Adds options: `pytest --network=[local/ic] --django-url=<URL>`"""
    parser.addoption(
        "--network",
        action="store",
        default="local",
        help="The network to use: local or ic",
    )
    parser.addoption(
        "--django-url",
        action="store",
        default="http://127.0.0.1:8001",
        help="The django-server URL to use",
    )
    parser.addoption(
        "--bot-url",
        action="store",
        default="http://127.0.0.1:5005",
        help="The bot-0 URL to use",
    )


@pytest.fixture(scope="module")
def network(request: Any) -> Any:
    """A fixture that verifies the network is up & returns the name."""
    network_ = request.config.getoption("--network")
    network_utils.check(network_)
    return network_


@pytest.fixture(scope="module")
def django_url(request: Any) -> Any:
    """A fixture that verifies the django-server is up & returns the django_url."""
    django_url_ = request.config.getoption("--django-url")
    django_server.health(django_url_)
    return django_url_


@pytest.fixture(scope="module")
def bot_url(request: Any) -> Any:
    """A fixture that verifies bot-0 is up & returns the bot_url."""
    bot_url_ = request.config.getoption("--bot-url")
    bot_0.health(bot_url_)
    return bot_url_


def handle_identity(identity: str) -> Generator[Dict[str, str], None, None]:
    """A fixture that sets the dfx identity."""
    identity_before_test = get_identity()
    set_identity(identity)
    user = {"identity": get_identity(), "principal": get_principal()}
    yield user
    set_identity(identity_before_test)


@pytest.fixture(scope="function")
def identity_anonymous() -> Generator[Dict[str, str], None, None]:
    """A fixture that sets the dfx identity to anonymous."""
    yield from handle_identity("anonymous")


@pytest.fixture(scope="function")
def identity_default() -> Generator[Dict[str, str], None, None]:
    """A fixture that sets the dfx identity to default."""
    yield from handle_identity("default")
