###################
#    This file implements an interface for TerminalMessages with Perl on Linux
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

package ProgressBar;

use FFI::Platypus::Record;

record_layout_1(
  'string rw' => 'start',
  'string rw' => 'end',
  'string rw' => 'character',
  'string rw' => 'empty',
  'short'     => 'size',
);

my $ffi = FFI::Platypus->new(
  api => 2,
  lib => './libTerminalMessages.so',
);
$ffi->type("record(ProgressBar)" => 'ProgressBar');
my $messagef_progress = $ffi->function( messagef => ['string', 'string', 'int', 'string', 'string', 'ProgressBar*', 'int', 'int'] => 'void' );

use DynaLoader;
use FFI;

my $terminalmessages = DynaLoader::dl_load_file('./libTerminalMessages.so');
my $messagef_addr = DynaLoader::dl_find_symbol($terminalmessages, 'messagef');
my $add_state_addr = DynaLoader::dl_find_symbol($terminalmessages, 'add_state');
my $add_rgb_state_addr = DynaLoader::dl_find_symbol($terminalmessages, 'add_rgb_state');
my $print_all_state_addr = DynaLoader::dl_find_symbol($terminalmessages, 'print_all_state');

DynaLoader::dl_install_xsub('print_all_state', $print_all_state_addr);

sub messagef {
    my ($message, $state, $pourcent, $start, $end, $add_progressbar, $oneline_progress, %progress_values) = @_;

    my $progress;
    my $size = keys %progress_values;
    if ($size != 0) {
        $progress = ProgressBar->new(
            start => $progress_values{start},
            end => $progress_values{end},
            character => $progress_values{character},
            empty => $progress_values{empty},
            size => $progress_values{size},
        );
        $messagef_progress->call($message, $state, $pourcent, $start, $end, $progress, $add_progressbar, $oneline_progress);
    } else {
        FFI::call($messagef_addr, "cvppCppoCC", $message, $state, $pourcent, $start, $end, $progress, $add_progressbar, $oneline_progress);
    }
}

sub add_state {
    my ($state_name, $character, $color) = @_;
    FFI::call($add_state_addr, "cvppp", $state_name, $character, $color);
}

sub add_rgb_state {
    my ($state_name, $character, $red, $green, $blue) = @_;
    FFI::call($add_rgb_state_addr, "cvppCCC", $state_name, $character, $red, $green, $blue);
}

my %my_progress = (start => "[", end => "]", character => "#", empty => "-", size => 30);

messagef("test");
add_state("TEST", "T", "cyan");
add_rgb_state("TEST2", "2", 188, 76, 53);
print_all_state();
messagef("test", "TEST", 50, " - ", "\n\n", 1, 1, %my_progress);
messagef("test", "TEST2", 80, " - ", "\n\n");

messagef("Press enter...", "TODO", 0, "", "", 0, 1, %my_progress);
my $string = <STDIN>;
