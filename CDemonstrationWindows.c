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

#include <stdio.h>
#include <windows.h>

struct ProgressBar {
    char* start;
    char* end;
    char* character;
    char* empty;
    unsigned short int size;
};

int main() {
    HMODULE library;
    void *(*messagef)(char*, char*, unsigned char, char*, char*, struct ProgressBar*, unsigned char, unsigned char);
    void *(*print_all_state)(void);
    void *(*add_state)(char*, char*, char*);
    void *(*add_rgb_state)(char*, char*, unsigned char, unsigned char, unsigned char);

    library = LoadLibrary("./TerminalMessages.dll");
    if (!library) {
        printf("Error loading library\n");
        return 1;
    }

    messagef = (void *(*)(char*, char*, unsigned char, char*, char*, struct ProgressBar*, unsigned char, unsigned char))GetProcAddress(library, "messagef");
    if (!messagef) {
        printf("Error getting function\n");
        return 1;
    }

    print_all_state = (void *(*)(void))GetProcAddress(library, "print_all_state");
    if (!messagef) {
        printf("Error getting function\n");
        return 1;
    }

    add_state = (void *(*)(char*, char*, char*))GetProcAddress(library, "add_state");
    if (!messagef) {
        printf("Error getting function\n");
        return 1;
    }

    add_rgb_state = (void *(*)(char*, char*, unsigned char, unsigned char, unsigned char))GetProcAddress(library, "add_rgb_state");
    if (!messagef) {
        printf("Error getting function\n");
        return 1;
    }

    struct ProgressBar progressbar = {"[", "]", "#", "-", 30};

    messagef("Test", NULL, 0, NULL, NULL, NULL, 0, 0);
    add_state("TEST", "T", "cyan");
    add_rgb_state("TEST2", "2", 188, 76, 53);
    print_all_state();
    messagef("Test", "TEST", 25, NULL, NULL, NULL, 1, 0);
    messagef("Test", "TEST2", 75, " - ", "\n\n", &progressbar, 1, 1);

    FreeLibrary(library);
    return 0;
}
