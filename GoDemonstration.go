// This file is a demonstration to use TerminalMessages DLL on Windows.

/*
    Copyright (C) 2023  Maurice Lambert
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

package main

import (
    "unsafe"
    "syscall"
)

func main () {
    terminalMessages, _ := syscall.LoadLibrary(".\\TerminalMessages.dll")
    messagef, _ := syscall.GetProcAddress(terminalMessages, "messagef")
    add_state, _ := syscall.GetProcAddress(terminalMessages, "add_state")
    add_rgb_state, _ := syscall.GetProcAddress(terminalMessages, "add_rgb_state")
    print_all_state, _ := syscall.GetProcAddress(terminalMessages, "print_all_state")

    syscall.Syscall9(
        messagef,
        8,
        uintptr(unsafe.Pointer(&append([]byte("Test"), 0)[0])),
        0,
        uintptr(10),
        0,
        uintptr(unsafe.Pointer(&append([]byte("\n\n"), 0)[0])),
        0,
        uintptr(1),
        0,
        0,
    )

    syscall.Syscall(
        add_state,
        3,
        uintptr(unsafe.Pointer(&append([]byte("TEST"), 0)[0])),
        uintptr(unsafe.Pointer(&append([]byte("T"), 0)[0])),
        uintptr(unsafe.Pointer(&append([]byte("cyan"), 0)[0])),
    )

    syscall.Syscall6(
        add_rgb_state,
        5,
        uintptr(unsafe.Pointer(&append([]byte("TEST2"), 0)[0])),
        uintptr(unsafe.Pointer(&append([]byte("T"), 0)[0])),
        uintptr(188),
        uintptr(76),
        uintptr(53),
        0,
    )

    syscall.Syscall9(
        messagef,
        8,
        uintptr(unsafe.Pointer(&append([]byte("Test"), 0)[0])),
        uintptr(unsafe.Pointer(&append([]byte("TEST"), 0)[0])),
        uintptr(50),
        0,
        uintptr(unsafe.Pointer(&append([]byte("\n\n"), 0)[0])),
        0,
        uintptr(1),
        0,
        0,
    )

    syscall.Syscall(print_all_state, 0, 0, 0, 0)

    syscall.Syscall9(
        messagef,
        8,
        uintptr(unsafe.Pointer(&append([]byte("Test"), 0)[0])),
        uintptr(unsafe.Pointer(&append([]byte("TEST2"), 0)[0])),
        uintptr(90),
        0,
        uintptr(unsafe.Pointer(&append([]byte("\n\n"), 0)[0])),
        0,
        uintptr(1),
        0,
        0,
    )
}