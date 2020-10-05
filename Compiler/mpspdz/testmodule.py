# Python modules in here can be imported from .mpc files

from mpspdz.util import *  # noqa F403
from mpspdz.types import *  # noqa F403
from mpspdz.library import *  # noqa F403


def test_module():
    print_ln("hi")  # noqa F405
