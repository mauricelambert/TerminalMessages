#![feature(once_cell)]

#[macro_use]
extern crate lazy_static;

use std::{sync::Mutex, collections::HashMap};
use lazy_static::lazy::Lazy;
use std::io::{stdout, Write};

/// Preconfigured ANSI colors constants
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

/// The progress bar type to create your own custom progress bars
pub struct ProgressBar {
    start: String,
    end: String,
    character: String,
    empty: String,
    size: i16,
}

impl ProgressBar {
    fn progress(&self, progress_size: i16) -> String {
        format!(
            "{start}{characters}{emptys}{end}",
            start=self.start,
            characters=self.character.repeat(progress_size.try_into().unwrap()),
            emptys=self.empty.repeat((self.size - progress_size).try_into().unwrap()),
            end=self.end,
        )
    }

    fn get_progress_size(&self, pourcent: i16) -> i16 {
        let progress_size = (pourcent as f32 / (100.0 / self.size as f32)).round() as i16;

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
pub struct RGBState {
    name: String,
    color: (u8, u8, u8),
    character: String,
}

impl _State for RGBState {
    fn as_string(&self, text: String) -> String {
        let (red, green, blue) = self.color;

        format!(
            "\x1b[38;{red};{green};{blue}m[{string}] {text}\x1b[0m",
            red=red,
            green=green,
            blue=blue,
            string=self.character,
            text=text,
        )
    }

    fn print(&self) {
        println!("{}", self.as_string(self.name));
    }
}

/// Default state type using preconfigured ANSI colors
pub struct State {
    name: String,
    color: Color,
    character: String,
}

impl _State for State {
    fn as_string(&self, text: String) -> String {
        format!(
            "\x1b[3{color}m[{character}] {text}\x1b[0m",
            color=self.color.value(),
            character=self.character,
            text=text,
        )
    }

    fn print(&self) {
        println!("{}", self.as_string(self.name));
    }
}

/// States used to print formatted and colored messages
/// States must be mutable to add your own custom states
lazy_static! {
    static ref StateOK: Mutex<State> = {
        let mut state = State{
            name: String::from("OK"),
            color: Color::Green,
            character: "+".to_string()
        };
        Mutex::new(state)
    };

    // doesn't have a size known at compile-time
    // cannot be sent between threads safely
    static ref STATES: Mutex<HashMap<&'static str, &'static Lazy<Mutex<dyn _State + 'static>>>> = {
        let mut _states = HashMap::from(
            [
                (
                    "OK",
                    Lazy::new(StateOK)
                    /*State{
                        name: String::from("OK"),
                        color: Color::Green,
                        character: "+".to_string(),
                    }*/
                ),
                (
                    "NOK",
                    State{
                        name: String::from("NOK"),
                        color: Color::Yellow,
                        character: "-".to_string(),
                    }
                ),
                (
                    "ERROR",
                    State{
                        name: String::from("ERROR"),
                        color: Color::Red,
                        character: "!".to_string(),
                    }
                ),
                (
                    "INFO",
                    State{
                        name: String::from("INFO"),
                        color: Color::Blue,
                        character: "*".to_string(),
                    }
                ),
                (
                    "TODO",
                    State{
                        name: String::from("TODO"),
                        color: Color::Purple,
                        character: "#".to_string(),
                    }
                ),
                (
                    "ASK",
                    State{
                        name: String::from("ASK"),
                        color: Color::Cyan,
                        character: "?".to_string(),
                    }
                ),
            ]
        );
        Mutex::new(_states)
    };
}

/// The default state
///
/// # Example
///
/// [ ] My default message (white)
const default_state: State = State {
    name: String::from("default"),
    color: Color::White,
    character: String::from(" "),
};

/// The default progress bar
///
/// # Example
///
/// |██████████          | (50%)
const default_progressbar: ProgressBar = ProgressBar {
    start: String::from("|"),
    end: String::from("|"),
    character: String::from("\u{2588}"),
    empty: String::from(" "),
    size: 20,
};

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
/// add_state("Test", "T", "cyan");
/// ```
pub fn add_state (key: &str, character: &str, color: &str) {
    let mut _states = STATES.lock().unwrap();
    _states.insert(
        key,
        State {
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
        }
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
/// add_rgb_state("Test", "T", 50, 200, 200);
/// ```
pub fn add_rgb_state (key: &str, string: &str, red: u8, green: u8, blue: u8) {
    let mut _states = STATES.lock().unwrap();
    _states.insert(
        key,
        RGBState {
            name: String::from(key),
            color: (red, green, blue),
            character: String::from(string),
        }
    );
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
/// printf("It's working !");
/// printf("Is not working...", "NOK", 25, " - ", "\n\n", ProgressBar{"[", "]", "#", "-", 30}, true, true);
/// ```
pub fn messagef (text: &str, state: Option<&str>, pourcent: Option<u8>, start: Option<&str>, end: Option<&str>, progressbar: Option<&ProgressBar>, add_progressbar: Option<bool>, oneline_progress: Option<bool>) {
    let to_print: String;
    
    let mut _states = STATES.lock().unwrap();
    let state = _states.get(state.unwrap_or("OK")).unwrap_or(default_state);
    let start = start.unwrap_or("");
    let end = end.unwrap_or("\n");
    let progressbar = progressbar.unwrap_or(&default_progressbar);
    
    let has_pourcent = pourcent.is_some();
    let oneline_progress = oneline_progress.is_some() && oneline_progress.unwrap();
    let add_progressbar = add_progressbar.is_none() || add_progressbar.unwrap();

    let progress_bar: String;

    if has_pourcent && add_progressbar {
        let pourcent = pourcent.unwrap();
        let temp_progressbar = format!(" {}% {}\x1b[0m{}\x1b[F", pourcent, progressbar.progress(progressbar.get_progress_size(pourcent.into())), end);

        if oneline_progress {
            String::from(String::from(temp_progressbar));
        } else {
            progress_bar = String::from(state.as_string(temp_progressbar));
        }
    } else {
        progress_bar = String::new();
    }

    if oneline_progress {
        to_print = String::from("\x1b[K".to_owned() + start + state.as_string(text) + progress_bar)
    } else {
        to_print = String::from("\x1b[K".to_owned() + start + state.as_string(text) + end + progress_bar)
    }

    print!("{}", to_print);
    stdout().flush();
}

/// Print all defined states
///
/// # Examples
///
/// ```rust
/// print_all_state();
/// ```
pub fn print_all_state () {
    default_state.print();

    let mut _states = STATES.lock().unwrap();

    for state in _states.values() {
        state.print();
    }
}

/// Main function to test the library
fn main () {
    print_all_state();
    add_rgb_state("Test1", "T", 50, 200, 200);
    add_state("Test2", "T", "cyan");
    print_all_state();

    messagef("It's working !", None, None, None, None, None, None, None);
    messagef("Is not working...", Some("NOK"), Some(25), Some(" - "), Some("\n\n"), Some(&ProgressBar{start: String::from("["), end: String::from("]"), character: String::from("#"), empty: String::from("-"), size: 30}), Some(true), Some(true));

    messagef("Test1", Some("Test1"), Some(50), Some(""), Some("\n"), Some(&ProgressBar{start: String::from("|"), end: String::from("|"), character: String::from("\u{2588}"), empty: String::from(" "), size: 30}), Some(false), Some(false));
    print!("{}", "\n");
    messagef("Test2", Some("Test2"), Some(50), Some(""), Some("\n\n"), Some(&ProgressBar{start: String::from("|"), end: String::from("|"), character: String::from("\u{2588}"), empty: String::from(" "), size: 30}), Some(false), Some(true));
}