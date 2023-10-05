// This file is a demonstration to use TerminalMessages DLL on Linux.

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

// #cgo LDFLAGS: -ldl
// #include <dlfcn.h>
// #include <stdlib.h>
// typedef struct {
//     char* start;
//     char* end;
//     char* character;
//     char* empty;
//     unsigned short int size;
// } ProgressBar, *pProgressBar;
// void *messagef(
//     void* function_pointer,
//     char* message,
//     char* state_name,
//     unsigned char pourcent,
//     char* start,
//     char* end,
//     ProgressBar* progressbar,
//     unsigned char add_progressbar,
//     unsigned char oneline_progress
// ) {
//     void *(*messagef)(char*, char*, unsigned char, char*, char*, ProgressBar*, unsigned char, unsigned char) = function_pointer;
//     messagef(message, state_name, pourcent, start, end, progressbar, add_progressbar, oneline_progress);
// }
// void *print_all_state(void* function_pointer) {
//     void *(*print_all_state)(void) = function_pointer;
//     print_all_state();
// }
// void *add_state(void* function_pointer, char* state_name, char* character, char* color) {
//     void *(*add_state)(char*, char*, char*) = function_pointer;
//     add_state(state_name, character, color);
// }
// void *add_rgb_state(void* function_pointer, char* state_name, char* character, unsigned char red, unsigned char green, unsigned char blue) {
//     void *(*add_rgb_state)(char*, char*, unsigned char, unsigned char, unsigned char) = function_pointer;
//     add_rgb_state(state_name, character, red, green, blue);
// }
import "C"
import "unsafe"

func get_function_pointer(library unsafe.Pointer, name string) unsafe.Pointer {
    function_name := C.CString(name)
    defer C.free(unsafe.Pointer(function_name))
    return C.dlsym(library, function_name)
} 

func main() {
    so_name := C.CString("./libTerminalMessages.so")
    defer C.free(unsafe.Pointer(so_name))
    library := C.dlopen(so_name, C.RTLD_LAZY)
    defer C.dlclose(library)

    messagef_address := get_function_pointer(library, "messagef")
    print_all_state_address := get_function_pointer(library, "print_all_state")
    add_state_address := get_function_pointer(library, "add_state")
    add_rgb_state_address := get_function_pointer(library, "add_rgb_state")

    text := C.CString("test")
    defer C.free(unsafe.Pointer(text))

    state1 := C.CString("TEST")
    defer C.free(unsafe.Pointer(state1))

    state2 := C.CString("TEST2")
    defer C.free(unsafe.Pointer(state2))

    character1 := C.CString("T")
    defer C.free(unsafe.Pointer(character1))

    character2 := C.CString("2")
    defer C.free(unsafe.Pointer(character2))

    color := C.CString("cyan")
    defer C.free(unsafe.Pointer(color))

    start_progress := C.CString("[")
    defer C.free(unsafe.Pointer(start_progress))

    end_progress := C.CString("]")
    defer C.free(unsafe.Pointer(end_progress))

    full_progress := C.CString("#")
    defer C.free(unsafe.Pointer(full_progress))

    empty_progress := C.CString("-")
    defer C.free(unsafe.Pointer(empty_progress))

    start := C.CString(" - ")
    defer C.free(unsafe.Pointer(start))

    end := C.CString("\n\n")
    defer C.free(unsafe.Pointer(end))

    progress := (C.pProgressBar)(unsafe.Pointer(new(C.ProgressBar)))
    progress.start = start_progress
    progress.end = end_progress
    progress.character = full_progress
    progress.empty = empty_progress
    progress.size = 30

    C.messagef(messagef_address, text, nil, 20, nil, nil, nil, 0, 0)
    C.print_all_state(print_all_state_address)
    C.add_state(add_state_address, state1, character1, color)
    C.add_rgb_state(add_rgb_state_address, state2, character2, 188, 76, 53)

    C.messagef(messagef_address, text, state2, 80, nil, end, nil, 0, 0)
    C.messagef(messagef_address, text, state1, 50, start, end, progress, 1, 1)
}