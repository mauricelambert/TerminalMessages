# TerminalMessages

## Description

This package is a DLL written in Rust with *interface* for other languages like Python, Ruby, Perl, Go... This library implements formatted and colored messages to be written in the console. It should be used when running a procedure, script, or analysis to show statuses, errors, prompt for input, or explain what the user should do, etc...

## Requirements

### Download

 - *No requirements*

### Compilation

 - Rust
 - Rust Standard library
 - Cargo
 - lazy_static

## Demontration

### Python POC

Source code: https://github.com/mauricelambert/PythonToolsKit/blob/main/PythonToolsKit/PrintF.py

![TerminalMessages demonstration](https://mauricelambert.github.io/info/python/code/PythonToolsKit/PrintF_demo.png "TerminalMessages demonstration")

### Rust executable

Source code: https://github.com/mauricelambert/TerminalMessages/blob/main/src/main.rs

![TerminalMessages demonstration](https://mauricelambert.github.io/info/rust/code/TerminalMessagesExecutableLinux.png "TerminalMessages demonstration")

## Installation

### Download

Download the DLL or SharedObject and executables for demonstration from [Github](https://github.com/mauricelambert/TerminalMessages/releases/latest/).

### Compilation

```bash
git clone https://github.com/mauricelambert/TerminalMessages.git
cd TerminalMessages

cargo build --target x86_64-pc-windows-gnu --release     # Windows with GNU requirements
cargo build --target x86_64-pc-windows-msvc --release    # Windows default
cargo build --target x86_64-unknown-linux-gnu --release  # Linux
```

## API

```c
struct ProgressBar {
    char* start;
    char* end;
    char* character;
    char* empty;
    unsigned short int size;
};

print_all_state();

add_state(char* state_name, char* character_symbol, char* color);

add_rgb_state(char* state_name, char* character_symbol, unsigned char red, unsigned char green, unsigned char blue);

messagef(
    char* message,
    char* state_name,
    unsigned char pourcent,
    char* start,
    char* end,
    struct ProgressBar* progressbar,
    unsigned char add_progressbar,
    unsigned char oneline_progress
);
// message is required, others arguments are optional and can be NULL or 0
```

## Links

 - [DLL/SharedObject](https://github.com/mauricelambert/TerminalMessages/releases/latest/)

## Licence

Licensed under the [GPL, version 3](https://www.gnu.org/licenses/).
