###################
#    This file implements an interface for TerminalMessages with Powershell (with Add-Type and CSharp)
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

$source = @"
using System.Runtime.InteropServices;

namespace TerminalMessages
{
    [StructLayout(LayoutKind.Sequential)]
    public struct ProgressBar
    {
        public string start;
        public string end;
        public string character;
        public string empty;
        public int size;
    }

    public class TerminalMessagesInterface
    {
        [DllImport("TerminalMessages.dll")]
        private static extern void messagef(
            string message,
            string state,
            int pourcent,
            string start,
            string end,
            ref ProgressBar progress,
            int add_progressbar,
            int oneline_progress
        );

        public static void c_messagef(
            string message,
            string state = null,
            int pourcent = 0,
            string start = null,
            string end = null,
            ProgressBar progress = new ProgressBar(),
            int add_progressbar = 0,
            int oneline_progress = 0
        ) {
            if (progress.size == 0)
            {
                progress.size = 25;
                progress.start = "[";
                progress.end = "]";
                progress.character = "#";
                progress.empty = "-";
                messagef(message, state, pourcent, start, end, ref progress, add_progressbar, oneline_progress);
                return;
            }
            messagef(message, state, pourcent, start, end, ref progress, add_progressbar, oneline_progress);
        }

        [DllImport("TerminalMessages.dll")]
        public static extern void add_rgb_state(string state_name, string character, int red, int green, int blue);

        [DllImport("TerminalMessages.dll")]
        public static extern void add_state(string state_name, string character, string color);

        [DllImport("TerminalMessages.dll")]
        public static extern void print_all_state();
    }
}
"@

Add-Type -TypeDefinition $source -Language CSharp 

if ($MyInvocation.CommandOrigin -eq 'Runspace') {
    $progress = [TerminalMessages.ProgressBar]::new()
    $progress.start = "["
    $progress.end = "]"
    $progress.character = "#"
    $progress.empty = "-"
    $progress.size = 30

    [TerminalMessages.TerminalMessagesInterface]::c_messagef("test")
    [TerminalMessages.TerminalMessagesInterface]::add_state("TEST", "T", "cyan")
    [TerminalMessages.TerminalMessagesInterface]::add_rgb_state("TEST2", "2", 188,  76, 53)
    [TerminalMessages.TerminalMessagesInterface]::print_all_state()
    [TerminalMessages.TerminalMessagesInterface]::c_messagef("test", "TEST", 50, " - ", "`n`n", $progress, 1, 1)
    [TerminalMessages.TerminalMessagesInterface]::c_messagef("test", "TEST2", 80, " - ", "`n`n")
}