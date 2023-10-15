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

// rustc RustDemonstrationLinux.rs

use std::ptr::null;
use std::ffi::c_char;
use std::ffi::c_uchar;
use std::ffi::CString;
use std::mem::transmute;
use std::os::raw::c_void;

#[repr(C)]
struct ProgressBar {
    start: *const c_char,
    end: *const c_char,
    character: *const c_char,
    empty: *const c_char,
    size: i16,
}

fn main() {
    let libname = CString::new("./libTerminalMessages.so").unwrap();

    let function1_name = CString::new("messagef").unwrap();
    let function2_name = CString::new("add_state").unwrap();
    let function3_name = CString::new("add_rgb_state").unwrap();
    let function4_name = CString::new("print_all_state").unwrap();

    let test_string = CString::new("test").unwrap();
    let test_state = CString::new("TEST").unwrap();
    let test2_state = CString::new("TEST2").unwrap();
    let characterT = CString::new("T").unwrap();
    let character2 = CString::new("2").unwrap();
    let color = CString::new("cyan").unwrap();
    let start = CString::new(" - ").unwrap();
    let end = CString::new("\n\n").unwrap();

    let progress_start = CString::new("[").unwrap();
    let progress_end = CString::new("]").unwrap();
    let progress_character = CString::new("#").unwrap();
    let progress_empty = CString::new("-").unwrap();

    let progress = ProgressBar {
        start: progress_start.into_raw(),
        end: progress_end.into_raw(),
        character: progress_character.into_raw(),
        empty: progress_empty.into_raw(),
        size: 30,
    };

    unsafe {
        let terminalmessages = dlopen(libname.as_ptr(), 1);

        let messagef = dlsym(terminalmessages, function1_name.as_ptr());
        let add_state = dlsym(terminalmessages, function2_name.as_ptr());
        let add_rgb_state = dlsym(terminalmessages, function3_name.as_ptr());
        let print_all_state = dlsym(terminalmessages, function4_name.as_ptr());

        let messagef_ptr: extern "C" fn(*const c_char, *const c_char, c_uchar, *const c_char, *const c_char, *const c_void, c_uchar, c_uchar) -> c_void = transmute(messagef);
        let add_state_ptr: extern "C" fn(*const c_char, *const c_char, *const c_char) -> c_void = transmute(add_state);
        let add_rgb_state_ptr: extern "C" fn(*const c_char, *const c_char, c_uchar, c_uchar, c_uchar) -> c_void = transmute(add_rgb_state);
        let print_all_state_ptr: extern "C" fn() -> c_void = transmute(print_all_state);

        let progress_ptr = &progress as *const ProgressBar as *const c_void;

        messagef_ptr(test_string.as_ptr(), null(), 0, null(), null(), null(), 0, 0);
        add_state_ptr(test_state.as_ptr(), characterT.as_ptr(), color.as_ptr());
        add_rgb_state_ptr(test2_state.as_ptr(), character2.as_ptr(), 188, 76, 53);
        print_all_state_ptr();
        messagef_ptr(test_string.as_ptr(), test_state.as_ptr(), 20, start.as_ptr(), end.as_ptr(), progress_ptr, 1, 1);
        messagef_ptr(test_string.as_ptr(), test2_state.as_ptr(), 50, start.as_ptr(), end.as_ptr(), null(), 1, 0);

        dlclose(terminalmessages);
    }
}

#[link(name = "dl")]
extern "C" {
    fn dlopen(filename: *const i8, flag: i32) -> *mut c_void;
    fn dlsym(handle: *mut c_void, symbol: *const i8) -> *mut c_void;
    fn dlclose(handle: *mut c_void) -> i32;
}
