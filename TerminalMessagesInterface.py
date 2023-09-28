#!/usr/bin/env python3
# -*- coding: utf-8 -*-

###################
#    This file implements an interface for TerminalMessages with Python
#    Copyright (C) 2023  TerminalMessages

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.
###################

"""
This file implements an interface for TerminalMessages with Python
"""

__version__ = "0.0.1"
__author__ = "Maurice Lambert"
__author_email__ = "mauricelambert434@gmail.com"
__maintainer__ = "Maurice Lambert"
__maintainer_email__ = "mauricelambert434@gmail.com"
__description__ = """
This file implements an interface for TerminalMessages with Python
"""
__url__ = "https://github.com/mauricelambert/TerminalMessages"

__all__ = ["ProgressBar", "add_state", "add_rgb_state", "messagef"]

__license__ = "GPL-3.0 License"
__copyright__ = """
TerminalMessages  Copyright (C) 2023  Maurice Lambert
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions.
"""
copyright = __copyright__
license = __license__

print(copyright)

from ctypes import c_char_p, c_ubyte, c_ushort, Structure, pointer
from os.path import join, dirname, exists
from dataclasses import dataclass
from os import name, getcwd

if name == "nt":
    from ctypes import windll as sysdll

    filename = "TerminalMessages.dll"
else:
    from ctypes import cdll as sysdll

    filename = "libTerminalMessages.so"

filenames = (join(dirname(__file__), filename), join(getcwd(), filename))
for filename in filenames:
    if exists(filename):
        break
else:
    raise FileNotFoundError(f"Library {filename!r} is missing")

lib = sysdll.LoadLibrary(filename)


@dataclass
class ProgressBar:
    """
    This class is a python interface for TerminalMessages.ProgressBarC.
    """

    start: str
    end: str
    character: str
    empty: str
    size: int


class _ProgressBarC(Structure):
    """
    This class is a python interface for TerminalMessages.ProgressBarC.
    """

    _fields_ = [
        ("start", c_char_p),
        ("end", c_char_p),
        ("character", c_char_p),
        ("empty", c_char_p),
        ("size", c_ushort),
    ]


def print_all_state():
    """
    This function is a python interface for TerminalMessages.print_all_state.
    """

    lib.print_all_state()

def add_state(state_name: str, character_symbol: str, color: str) -> None:
    """
    This function is a python interface for TerminalMessages.add_state.

    - State name is the name of the new state (encoded as utf-8)
    - Character symbol is the synbol character of the new state
        (encoded as utf-8)
    - Color is the color name for the symbol, colors available:
        - black,
        - red,
        - green,
        - yellow,
        - blue,
        - purple,
        - cyan,
        - white,
    """

    lib.add_state(
        c_char_p(state_name.encode()),
        c_char_p(character_symbol.encode()),
        c_char_p(color.lower().encode()),
    )


def add_rgb_state(
    state_name: str, character_symbol: str, red: int, green: int, blue: int
) -> None:
    """
    This function is a python interface for TerminalMessages.add_rgb_state.

    - State name is the name of the new state (encoded as utf-8)
    - Character symbol is the synbol character of the new state
        (encoded as utf-8)
    - Red is the red byte for RGB color
        (must greater or equal to 0 and leather than 256)
    - Green is the green byte for RGB color
        (must greater or equal to 0 and leather than 256)
    - Blue is the blue byte for RGB color
        (must greater or equal to 0 and leather than 256)
    """

    lib.add_rgb_state(
        c_char_p(state_name.encode()),
        c_char_p(character_symbol.encode()),
        c_ubyte(red),
        c_ubyte(green),
        c_ubyte(blue),
    )


def messagef(
    message: str,
    state: str = None,
    pourcent: int = None,
    start: str = None,
    end: str = None,
    progressbar: ProgressBar = None,
    add_progressbar: bool = None,
    oneline_progress: bool = None,
) -> None:
    """
    This function is a python interface for TerminalMessages.messagef.
    """

    if pourcent:
        pourcent = pourcent % 100

    if state:
        state = c_char_p(state.encode())

    if start:
        start = c_char_p(start.encode())

    if end:
        end = c_char_p(end.encode())

    if progressbar:
        progressbar = pointer(
            _ProgressBarC(
                progressbar.start.encode(),
                progressbar.end.encode(),
                progressbar.character.encode(),
                progressbar.empty.encode(),
                progressbar.size,
            )
        )

    if pourcent:
        pourcent = c_ubyte(pourcent)

    lib.messagef(
        c_char_p(message.encode()),
        state,
        pourcent,
        start,
        end,
        progressbar,
        c_ubyte(1 if add_progressbar else 0),
        c_ubyte(1 if oneline_progress else 0),
    )


def main() -> int:
    """
    The main function to test the module from the command line.
    """

    add_state("TEST", "T", "cyan")
    add_rgb_state("TEST2", "2", 188, 76, 53)
    print_all_state()
    messagef("This is working !")
    messagef(
        "This is not working !",
        "NOK",
        10,
        " - ",
        "\n\n",
        ProgressBar("[", "]", "#", "-", 30),
        True,
        True,
    )
    messagef("Error", "ERROR", 20, "", "\n\n", None, True, True)
    messagef("Info", "INFO", 30, "", "\n\n", None, True)
    messagef("To do", "TODO", 40, "", "\n\n", None, True)
    messagef("Question ?", "ASK", 50, "", "\n\n", None, True)
    print_all_state()
    messagef("Test my simple state", "TEST", 60, "", "\n\n", None, True)
    messagef("Test my advanced state", "TEST2", 70, "", "\n\n", None, True)
    messagef("Ok", "OK", 80, None, None, None, True)
    messagef("Ok", "OK", 90, None, None, None, True)


if __name__ == "__main__":
    exit(main())
