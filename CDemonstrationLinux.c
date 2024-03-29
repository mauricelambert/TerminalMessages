// This file is a demonstration to use TerminalMessages Shared Object on Linux.

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
#include <dlfcn.h>

struct ProgressBar {
    char* start;
    char* end;
    char* character;
    char* empty;
    unsigned short int size;
};

int main() {
    void *library;
    void *(*messagef)(char*, char*, unsigned char, char*, char*, struct ProgressBar*, unsigned char, unsigned char);
    void *(*print_all_state)(void);
    void *(*add_state)(char*, char*, char*);
    void *(*add_rgb_state)(char*, char*, unsigned char, unsigned char, unsigned char);
    char *error;

    library = dlopen("./libTerminalMessages.so", RTLD_LAZY);
    if (!library) {
        fprintf(stderr, "%s\n", dlerror());
        return 1;
    }

    messagef = dlsym(library, "messagef");
    if ((error = dlerror()) != NULL) {
        fprintf(stderr, "%s\n", error);
        return 2;
    }

    print_all_state = dlsym(library, "print_all_state");
    if ((error = dlerror()) != NULL) {
        fprintf(stderr, "%s\n", error);
        return 2;
    }

    add_state = dlsym(library, "add_state");
    if ((error = dlerror()) != NULL) {
        fprintf(stderr, "%s\n", error);
        return 2;
    }

    add_rgb_state = dlsym(library, "add_rgb_state");
    if ((error = dlerror()) != NULL) {
        fprintf(stderr, "%s\n", error);
        return 2;
    }

    struct ProgressBar progressbar = {"[", "]", "#", "-", 30};

    messagef("Test", NULL, 0, NULL, NULL, NULL, 0, 0);
    add_state("TEST", "T", "cyan");
    add_rgb_state("TEST2", "2", 188, 76, 53);
    print_all_state();
    messagef("Test", "TEST", 25, NULL, NULL, NULL, 1, 0);
    messagef("Test", "TEST2", 75, " - ", "\n\n", &progressbar, 1, 1);

    dlclose(messagef);
    return 0;
}
