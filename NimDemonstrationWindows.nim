###################
#    This file is a demonstration to use TerminalMessages DLL and Shared Object on Windows and Linux with Nim.
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

import dynlib

type
  ProgressBar = object
    start: cstring
    end1: cstring
    character: cstring
    empty: cstring
    size: cushort

type
  messagef_function = proc(message: cstring, state: cstring, pourcent: uint8, start: cstring, end1: cstring, progressbar: ptr ProgressBar, add_progressbar: uint8, oneline_progress: uint8): void {.gcsafe, stdcall.}

type
  add_state_function = proc(state_name: cstring, character: cstring, color: cstring): void {.gcsafe, stdcall.}

type
  add_rgb_state_function = proc(state_name: cstring, character: cstring, red: uint8, green: uint8, blue: uint8): void {.gcsafe, stdcall.}

type
  print_all_state_function = proc(): void {.gcsafe, stdcall.}

when defined windows:
    let libname = ".\\TerminalMessages.dll"
elif defined linux:
    let libname = "./libTerminalMessages.so"

let terminalmessages = loadLib(libname)

let messagef = cast[messagef_function](terminalmessages.symAddr("messagef"))
let add_state = cast[add_state_function](terminalmessages.symAddr("add_state"))
let add_rgb_state = cast[add_rgb_state_function](terminalmessages.symAddr("add_rgb_state"))
let print_all_state = cast[print_all_state_function](terminalmessages.symAddr("print_all_state"))

let progress = ProgressBar(start: cstring("["), end1: cstring("]"), character: cstring("#"), empty: cstring("-"), size: cushort(30))

messagef(cstring("test"), nil, 0, nil, nil, nil, 0, 0)
add_state(cstring("TEST"), cstring("T"), cstring("cyan"))
add_rgb_state(cstring("TEST2"), cstring("2"), uint8(188), uint8(76), uint8(53))
print_all_state()
messagef(cstring("test"), cstring("TEST"), 50, cstring(" - "), cstring("\n\n"), addr progress, 1, 1)
# messagef(cstring("test"), cstring("TEST"), 50, cstring(" - "), cstring("\n\n"), unsafeAddr progress, 1, 1) # for nim < 2.0.0
messagef(cstring("test"), cstring("TEST2"), 80, cstring(" - "), cstring("\n\n"), nil, 0, 0)
