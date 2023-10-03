###################
#    This file implements an interface for TerminalMessages with Ruby
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

require 'fiddle'
require 'fiddle/import'

class ProgressBar
    attr_accessor :message, :state_name, :character, :empty, :size

    def initialize(message, state_name, character, empty, size)
        @message = message
        @state_name = state_name
        @character = character
        @empty = empty
        @size = size
    end
end

ProgressBarC = Fiddle::Importer::struct [
    "char* message",
    "char* state_name",
    "char* character",
    "char* empty",
    "int size",
]

FILENAME = if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM) != nil then "TerminalMessages.dll" else "libTerminalMessages.so" end

terminal_messages = nil
for path in [File.expand_path(File.dirname(__FILE__)), Dir.pwd]
    path = File.join(path, FILENAME)
    if File.file?(path)
        terminal_messages = Fiddle.dlopen(path)
    end
end

if terminal_messages.nil?
    raise 'TerminalMessages file not found !'
end

$c_messagef = Fiddle::Function.new(
    terminal_messages['messagef'],
    [
        Fiddle::TYPE_UINTPTR_T,
        Fiddle::TYPE_UINTPTR_T,
        Fiddle::TYPE_CHAR,
        Fiddle::TYPE_UINTPTR_T,
        Fiddle::TYPE_UINTPTR_T,
        Fiddle::TYPE_UINTPTR_T,
        Fiddle::TYPE_CHAR,
        Fiddle::TYPE_CHAR,
    ],
    Fiddle::TYPE_VOIDP
)

$c_print_all_state = Fiddle::Function.new(
    terminal_messages['print_all_state'],
    [],
    Fiddle::TYPE_VOIDP
)

$c_add_state = Fiddle::Function.new(
    terminal_messages['add_state'],
    [
        Fiddle::TYPE_UINTPTR_T,
        Fiddle::TYPE_UINTPTR_T,
        Fiddle::TYPE_UINTPTR_T,
    ],
    Fiddle::TYPE_VOIDP
)

$c_add_rgb_state = Fiddle::Function.new(
    terminal_messages['add_rgb_state'],
    [
        Fiddle::TYPE_UINTPTR_T,
        Fiddle::TYPE_UINTPTR_T,
        Fiddle::TYPE_CHAR,
        Fiddle::TYPE_CHAR,
        Fiddle::TYPE_CHAR,
    ],
    Fiddle::TYPE_VOIDP
)

def messagef(message, state = 0, pourcent = 0, start = 0, end_ = 0, progressbar = 0, add_progressbar = 0, oneline_progress = 0)
    if progressbar != 0
        c_progressbar = ProgressBarC.malloc()
        c_progressbar.message = Fiddle::Pointer[progressbar.message]
        c_progressbar.state_name = Fiddle::Pointer[progressbar.state_name]
        c_progressbar.character = Fiddle::Pointer[progressbar.character]
        c_progressbar.empty = Fiddle::Pointer[progressbar.empty]
        c_progressbar.size = progressbar.size
        c_ptr_progressbar = Fiddle::Pointer[c_progressbar]
    else
        c_ptr_progressbar = 0
    end

    $c_messagef.call(
        Fiddle::Pointer[message],
        Fiddle::Pointer[state],
        pourcent,
        Fiddle::Pointer[start],
        Fiddle::Pointer[end_],
        c_ptr_progressbar,
        add_progressbar,
        oneline_progress,
    )
end

def add_state(state_name, character, color)
    $c_add_state.call(
        Fiddle::Pointer[state_name],
        Fiddle::Pointer[character],
        Fiddle::Pointer[color],
    )
end

def add_rgb_state(state_name, character, red, green, blue)
    $c_add_rgb_state.call(
        Fiddle::Pointer[state_name],
        Fiddle::Pointer[character],
        red,
        green,
        blue,
    )
end

def print_all_state()
    $c_print_all_state.call()
end

if __FILE__ == $0
    messagef("Test")
    messagef("Test", "NOK", 20, "", "\n\n", ProgressBar.new("[", "]", "#", "-", 30), 1, 1)
    add_state("TEST", "T", "cyan")
    add_rgb_state("TEST2", "2", 188, 76, 53)
    print_all_state()
    messagef("Test", "TEST", 50)
    messagef("Test", "TEST2", 80)
end