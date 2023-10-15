###################
#    This file implements an interface for TerminalMessages with Perl on Windows
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

use feature 'say';
use Cwd qw(abs_path);
use File::Spec;
use Win32::API;
use Win32::API::Struct;

Win32::API::Struct->typedef('ProgressBar', qw(
    char* start;
    char* end;
    char* character;
    char* empty;
    short size;
));

my $default_progress = Win32::API::Struct->new('ProgressBar'); 
$default_progress->{start} = "|";
$default_progress->{end} = "|";
$default_progress->{character} = "█";
$default_progress->{empty} = " ";
$default_progress->{size} = 20;

Win32::API->Import(abs_path(File::Spec->canonpath('TerminalMessages.dll')), 'void *messagef(
    char* message,
    char* state_name,
    unsigned char pourcent,
    char* start,
    char* end,
    ProgressBar* progressbar,
    unsigned char add_progressbar,
    unsigned char oneline_progress
);');

Win32::API->Import(abs_path(File::Spec->canonpath('TerminalMessages.dll')), 'void *print_all_state();');
Win32::API->Import(abs_path(File::Spec->canonpath('TerminalMessages.dll')), 'void *add_state(char* state_name, char* character_symbol, char* color);');
Win32::API->Import(abs_path(File::Spec->canonpath('TerminalMessages.dll')), 'void *add_rgb_state(char* state_name, char* character_symbol, unsigned char red, unsigned char green, unsigned char blue);');

sub perl_messagef {
    my ($message, $state, $pourcent, $start, $end, $add_progressbar, $oneline_progress, %progress_values) = @_;

    my $progress;
    my $size = keys %progress_values;
    if ($size == 0) {
        $progress = $default_progress;
    } else {
        $progress = Win32::API::Struct->new('ProgressBar');
        $progress->{start} = $progress_values{start};
        $progress->{end} = $progress_values{end};
        $progress->{character} = $progress_values{character};
        $progress->{empty} = $progress_values{empty};
        $progress->{size} = $progress_values{size};
    }

    messagef($message, $state, $pourcent, $start, $end, $progress, $add_progressbar, $oneline_progress);
}

my %my_progress = (start => "[", end => "]", character => "#", empty => "-", size => 30);

perl_messagef("test");
add_state("TEST", "T", "cyan");
add_rgb_state("TEST2", "2", 188, 76, 53);
print_all_state();
perl_messagef("test", "TEST", 50, " - ", "\n\n", 1, 1, %my_progress);
perl_messagef("test", "TEST2", 80, " - ", "\n");
perl_messagef("Press enter...", "TODO", 80, "", " ", 0, 1, %my_progress);
my $string = <STDIN>;
