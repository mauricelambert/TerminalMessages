//    This file implements a generic CLI for process and procedure
//    Copyright (C) 2023  TerminalMessages

//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.

//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.

//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <https://www.gnu.org/licenses/>.


use std::{sync::Mutex, collections::HashMap};
use lazy_static::lazy_static;
use std::io::{stdout, Write};

/// Preconfigured ANSI colors constants
#[derive(Clone)]
enum Color {
    Black,  // 0
    Red,    // 1
    Green,  // 2
    Yellow, // 3
    Blue,   // 4
    Purple, // 5
    Cyan,   // 6
    White,  // 7
}

impl Color {
    fn value(&self) -> i32 {
        match *self {
            Color::Black  => 0,
            Color::Red    => 1,
            Color::Green  => 2,
            Color::Yellow => 3,
            Color::Blue   => 4,
            Color::Purple => 5,
            Color::Cyan   => 6,
            Color::White  => 7,
        }
    }
}

/// The progress bar type to create your own custom progress bars from C types
#[repr(C)]
pub struct ProgressBarC {
    pub start: *const u8,
    pub end: *const u8,
    pub character: *const u8,
    pub empty: *const u8,
    pub size: u16,
}

/// The progress bar type to create your own custom progress bars
pub struct ProgressBar {
    pub start: String,
    pub end: String,
    pub character: String,
    pub empty: String,
    pub size: u16,
}

impl ProgressBar {
    fn progress(&self, progress_size: u16) -> String {
        format!(
            "{start}{characters}{emptys}{end}",
            start=self.start,
            characters=self.character.repeat(progress_size.try_into().unwrap()),
            emptys=self.empty.repeat((self.size - progress_size).try_into().unwrap()),
            end=self.end,
        )
    }

    fn get_progress_size(&self, pourcent: u16) -> u16 {
        let progress_size = (pourcent as f32 / (100.0 / self.size as f32)).round() as u16;

        if progress_size > self.size {
            self.size
        } else {
            progress_size
        }
    }
}

/// _State line to define the basis of the 'State'
/// type with signatures of specific functions
pub trait _State {
    fn as_string(&self, text: String) -> String;
    fn print(&self);
}

/// Status type to add your custom colors
#[derive(Clone)]
pub struct RGBState {
    name: String,
    color: (u8, u8, u8),
    character: String,
}

impl _State for RGBState {
    fn as_string(&self, text: String) -> String {
        let (red, green, blue) = self.color;

        format!(
            "\x1b[38;2;{red};{green};{blue}m[{string}] {text}",
            red=red,
            green=green,
            blue=blue,
            string=self.character,
            text=text,
        )
    }

    fn print(&self) {
        println!("{}", self.as_string(self.name.clone()));
    }
}

/// Default state type using preconfigured ANSI colors
#[derive(Clone)]
pub struct State {
    name: String,
    color: Color,
    character: String,
}

impl _State for State {
    fn as_string(&self, text: String) -> String {
        format!(
            "\x1b[3{color}m[{character}] {text}",
            color=self.color.value(),
            character=self.character,
            text=text,
        )
    }

    fn print(&self) {
        println!("{}", self.as_string(self.name.clone()));
    }
}

/// States used to print formatted and colored messages
/// States must be mutable to add your own custom states
lazy_static! {
    static ref STATE_OK: State = {
        State {
            name: String::from("OK"),
            color: Color::Green,
            character: "+".to_string(),
        }
    };
    static ref STATE_NOK: State = {
        State {
            name: String::from("NOK"),
            color: Color::Yellow,
            character: "-".to_string(),
        }
    };
    static ref STATE_ERROR: State = {
        State {
            name: String::from("ERROR"),
            color: Color::Red,
            character: "!".to_string(),
        }
    };
    static ref STATE_INFO: State = {
        State {
            name: String::from("INFO"),
            color: Color::Blue,
            character: "*".to_string(),
        }
    };
    static ref STATE_TODO: State = {
        State {
            name: String::from("TODO"),
            color: Color::Purple,
            character: "#".to_string(),
        }
    };
    static ref STATE_ASK: State = {
        State {
            name: String::from("ASK"),
            color: Color::Cyan,
            character: "?".to_string(),
        }
    };

    static ref STATES: Mutex<HashMap<&'static str, Box<dyn _State + Send>>> = {
        let _states: HashMap<&'static str, Box<dyn _State + Send>> = HashMap::from(
            [
                (
                    "OK",
                    Box::new(STATE_OK.clone()) as Box<dyn _State + Send>
                ),
                (
                    "NOK",
                    Box::new(STATE_NOK.clone()) as Box<dyn _State + Send>
                ),
                (
                    "ERROR",
                    Box::new(STATE_ERROR.clone()) as Box<dyn _State + Send>
                ),
                (
                    "INFO",
                    Box::new(STATE_INFO.clone()) as Box<dyn _State + Send>
                ),
                (
                    "TODO",
                    Box::new(STATE_TODO.clone()) as Box<dyn _State + Send>
                ),
                (
                    "ASK",
                    Box::new(STATE_ASK.clone()) as Box<dyn _State + Send>
                ),
            ]
        );
        Mutex::new(_states)
    };

    /// The default state
    ///
    /// # Example
    ///
    /// [ ] My default message (white)
    static ref DEFAULT_STATE: Mutex<Box<dyn _State + Send>> = {
        let _default: Box<dyn _State + Send> = Box::new(State {
            name: String::from("default"),
            color: Color::White,
            character: String::from(" "),
        });
        Mutex::new(_default)
    };

    /// The default progress bar
    ///
    /// # Example
    ///
    /// |██████████          | (50%)
    static ref DEFAULT_PROGRESSBAR: ProgressBar = ProgressBar {
        start: String::from("|"),
        end: String::from("|"),
        character: String::from("\u{2588}"),
        empty: String::from(" "),
        size: 20,
    };
}

/// Convert *char (C) to &str (Rust) to get a Rust type from DLL/SO.
///
/// # Parameters
///
/// - `string_c`          (*const u8):                 C string to convert
///
/// # Return value
///
/// - &str                (&str)                       Rust string converted from C string
///
/// # Examples
///
/// ```rust
/// rust_from_c_string(b"Hello, world!\0".as_ptr());
/// ```
fn rust_from_c_string (string_c: *const u8) -> &'static str {
    let length = strlen(string_c);
    let slice = unsafe { std::slice::from_raw_parts(string_c, length) };
    std::str::from_utf8(slice).unwrap()
}

/// This function return the C string length.
///
/// # Parameters
///
/// - `string_c`          (*const u8):                 C string
///
/// # Return value
///
/// - size                (usize)                      String length
///
/// # Examples
///
/// ```rust
/// strlen(b"Hello, world!\0".as_ptr());
/// ```
fn strlen(string_c: *const u8) -> usize {
    let mut length = 0;

    unsafe {
        while *string_c.add(length) != 0 {
            length += 1;
        }
    }

    length
}

/// Add a new state with a predefined color.
///
/// # Parameters
///
/// - `key`              (str):                        State name
/// - `character`        (str):                        Characters for formatting
/// - `color`            (str):                        Predefined color name (black, red, green, yellow, blue, purple, cyan, white)
///
/// # Examples
///
/// ```rust
/// add_state(b"Test\0".as_ptr(), b"T\0".as_ptr(), b"cyan\0".as_ptr());
/// ```
#[no_mangle]
pub extern "C" fn add_state (key_: *const u8, character_: *const u8, color_: *const u8) {
    let key = rust_from_c_string(key_);
    let color = rust_from_c_string(color_);
    let character = rust_from_c_string(character_);

    let mut _states = STATES.lock().unwrap();
    _states.insert(
        key,
        Box::new(State {
            name: String::from(key),
            color: match color {
                "black"  => Color::Black,
                "red"    => Color::Red,
                "green"  => Color::Green,
                "yellow" => Color::Yellow,
                "blue"   => Color::Blue,
                "purple" => Color::Purple,
                "cyan"   => Color::Cyan,
                "white"  => Color::White,
                _        => Color::White,
            },
            character: String::from(character),
        }) as Box<dyn _State + Send>
    );
}

/// Add a new state with a 3 byte color.
///
/// # Parameters
///
/// - `key`              (str):                        State name
/// - `string`           (str):                        Characters for formatting
/// - `red`              (int - u8):                   Red color
/// - `green`            (int - u8):                   Green color
/// - `blue`             (int - u8):                   Blue color
///
/// # Examples
///
/// ```rust
/// add_rgb_state(b"Test\0".as_ptr(), b"T\0".as_ptr(), 50, 200, 200);
/// ```
#[no_mangle]
pub extern "C" fn add_rgb_state (key_: *const u8, string_: *const u8, red: u8, green: u8, blue: u8) {
    let key = rust_from_c_string(key_);
    let string = rust_from_c_string(string_);

    let mut _states = STATES.lock().unwrap();
    _states.insert(
        key,
        Box::new(RGBState {
            name: String::from(key),
            color: (red, green, blue),
            character: String::from(string),
        }) as Box<dyn _State + Send>
    );
}

/// This function is an interface for _messagef Rust function to use it from native DLL/SO
///
/// # Parameters
///
/// - `text`             (*const u8):                        Message to print
/// - `state`            (*const u8 or NULL):                State name used to print the message
/// - `pourcent`         (int - u8):                         Number between 0 and 100 that represents progress
/// - `start`            (*const u8 or NULL):                Characters to print before color and formatting
/// - `end`              (*const u8 or NULL):                Characters to print after color and formatting
/// - `progressbar`      (ProgressBarC):                     A ProgressBarC object to customize the progress bar
/// - `add_progressbar`  (u8):                               If not 0 and pourcent is defined: add the progress bar in output
/// - `oneline_progress` (u8):                               If not 0: print one line message and progression
///
/// # Examples
///
/// ```rust
/// _messagef(b"It's working !\0".as_ptr());
/// _messagef(b"Is not working...\0".as_ptr(), b"NOK\0".as_ptr(), 25, b" - \0".as_ptr(), b"\n\n\0".as_ptr(), ProgressBarC{b"[\0".as_ptr(), b"]\0".as_ptr(), b"#\0".as_ptr(), b"-\0".as_ptr(), 30}, 1, 1);
/// ```
#[no_mangle]
pub extern "C" fn messagef (text_: *const u8, state_: *const u8, pourcent_: u8, start_: *const u8, end_: *const u8, progressbar_: *const ProgressBarC, add_progressbar_: u8, oneline_progress_: u8) {
    let text = rust_from_c_string(text_);
    let end: Option<&str>;
    let state: Option<&str>;
    let start: Option<&str>;
    let pourcent = Some(pourcent_);
    let add_progressbar: Option<bool>;
    let oneline_progress: Option<bool>;
    let progressbar: Option<&ProgressBar>;

    if end_.is_null() {
        end = None;
    } else {
        end = Some(rust_from_c_string(end_));
    }

    if state_.is_null() {
        state = None;
    } else {
        state = Some(rust_from_c_string(state_));
    }

    if start_.is_null() {
        start = None;
    } else {
        start = Some(rust_from_c_string(start_));
    }

    if add_progressbar_ == 0 {
        add_progressbar = None;
    } else {
        add_progressbar = Some(true);
    }

    if oneline_progress_ == 0 {
        oneline_progress = None;
    } else {
        oneline_progress = Some(true);
    }

    let mut _progressbar = ProgressBar{start: String::from(""), end: String::from(""), character: String::from(""), empty: String::from(""), size: 0};
    let progressbar__: &ProgressBarC;

    if progressbar_.is_null() {
        progressbar = None;
    } else {
        progressbar__ = unsafe { &(*progressbar_) };

        _progressbar.character = String::from(rust_from_c_string(progressbar__.character));
        _progressbar.empty = String::from(rust_from_c_string(progressbar__.empty));
        _progressbar.start = String::from(rust_from_c_string(progressbar__.start));
        _progressbar.end = String::from(rust_from_c_string(progressbar__.end));
        _progressbar.size = progressbar__.size;

        progressbar = Some(&_progressbar);
    }

    _messagef(text, state, pourcent, start, end, progressbar, add_progressbar, oneline_progress)
}

/// Print a message formatted and colored using ANSI characters.
///
/// # Parameters
///
/// - `text`             (str):                        Message to print
/// - `state`            (str, default value: "OK"):   State name used to print the message
/// - `pourcent`         (int - u8):                   Number between 0 and 100 that represents progress
/// - `start`            (str):                        Characters to print before color and formatting
/// - `end`              (str, default value: "\n"):   Characters to print after color and formatting
/// - `progressbar`      (ProgressBar):                A ProgressBar object to customize
/// - `add_progressbar`  (bool, default value: true):  If true and pourcent is defined: add the progress bar in output
/// - `oneline_progress` (bool, default value: false): If true: print one line message and progression
///
/// # Examples
///
/// ```rust
/// _messagef("It's working !");
/// _messagef("Is not working...", "NOK", 25, " - ", "\n\n", ProgressBar{"[", "]", "#", "-", 30}, true, true);
/// ```
pub fn _messagef (text: &str, state: Option<&str>, pourcent: Option<u8>, start: Option<&str>, end: Option<&str>, progressbar: Option<&ProgressBar>, add_progressbar: Option<bool>, oneline_progress: Option<bool>) {
    let to_print: String;
    
    let _states = STATES.lock().unwrap();
    let default_state = &DEFAULT_STATE.lock().unwrap();
    let state = _states.get(&*state.unwrap_or("OK").to_string()).unwrap_or(default_state);
    let start = start.unwrap_or("");
    let end = end.unwrap_or("\n");
    let progressbar = progressbar.unwrap_or(&DEFAULT_PROGRESSBAR);
    
    let has_pourcent = pourcent.is_some();
    let oneline_progress = oneline_progress.is_some() && oneline_progress.unwrap();
    let add_progressbar = add_progressbar.is_none() || add_progressbar.unwrap();

    let mut progress_bar: String = String::new();

    if has_pourcent && add_progressbar {
        let pourcent = pourcent.unwrap();
        let temp_progressbar = format!(" {}% {}\x1b[0m{}\x1b[F", pourcent, progressbar.progress(progressbar.get_progress_size(pourcent.into())), end);

        if oneline_progress {
            progress_bar = String::from(String::from(temp_progressbar));
        } else {
            progress_bar = String::from(state.as_string(temp_progressbar));
        }
    }

    if oneline_progress {
        to_print = String::from("\x1b[K".to_owned() + start + &state.as_string(text.to_string()) + &progress_bar)
    } else {
        to_print = String::from("\x1b[K".to_owned() + start + &state.as_string(text.to_string()) + "\n" + &progress_bar)
    }

    print!("{}", to_print);
    let _ = stdout().flush();
}

/// Print all defined states
///
/// # Examples
///
/// ```rust
/// print_all_state();
/// ```
#[no_mangle]
pub extern "C" fn print_all_state () {
    DEFAULT_STATE.lock().unwrap().print();

    let _states = STATES.lock().unwrap();

    for state in _states.values() {
        state.print();
    }
}
