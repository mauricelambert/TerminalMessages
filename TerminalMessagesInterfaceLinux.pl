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
    my ($message, $state, $pourcent, $start, $end, %progress_values, $add_progressbar, $oneline_progress) = @_;

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
messagef("test", "TEST", 50, " - ", "\n\n", %my_progress, 1, 1);
messagef("test", "TEST2", 80, " - ", "\n\n");
