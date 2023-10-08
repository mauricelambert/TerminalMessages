###################
#    This file implements an interface for TerminalMessages with Powershell (without Add-Type and CSharp)
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

function GetProcAddress () {
    Param ($module, $procedure_name)

    return $GetProcAddress_func.Invoke(
        $null,
        @(
            [System.Runtime.InteropServices.HandleRef](New-Object System.Runtime.InteropServices.HandleRef(
                (New-Object IntPtr),
                $module
            )),
            $procedure_name
        )
    )
}

function get_function_from_c_pointer () {
    Param ($function_pointer, $delegate_type)

    return [System.Runtime.InteropServices.Marshal]::GetDelegateForFunctionPointer(
        $function_pointer,
        $delegate_type
    )
}

function get_constructor () {
    Param ([System.Reflection.Emit.TypeBuilder] $_util_delegate_type_builder, [Type[]] $parameters_types)

    return $_util_delegate_type_builder.DefineConstructor(
        'RTSpecialName, HideBySig, Public',
        [System.Reflection.CallingConventions]::Standard,
        $parameters_types
    ).SetImplementationFlags('Runtime, Managed')
}

function get_delegate_type () {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [Type[]] $parameters_types,
        [Parameter(Position = 1)] [Type] $return_type = [Void]
    )

    $_util_delegate_type_builder = [AppDomain]::CurrentDomain.DefineDynamicAssembly(
        (New-Object System.Reflection.AssemblyName('ReflectedDelegate')),
        [System.Reflection.Emit.AssemblyBuilderAccess]::Run
    ).DefineDynamicModule(
        'InMemoryModule',
        $false
    ).DefineType(
        'MyDelegateType',
        'Class, Public, Sealed, AnsiClass, AutoClass',
        [System.MulticastDelegate]
    )

    get_constructor $_util_delegate_type_builder $parameters_types
    $_util_delegate_type_builder.DefineMethod(
        'Invoke',
        'Public, HideBySig, NewSlot, Virtual',
        $return_type,
        $parameters_types
    ).SetImplementationFlags('Runtime, Managed')

    return $_util_delegate_type_builder.CreateType()
}

function LoadLibrary () {
    Param ($library_path)
    return $LoadLibrary_function.Invoke($library_path)
}

function func_get_delegate_type {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [Type[]] $var_parameters,
        [Parameter(Position = 1)] [Type] $var_return_type = [Void]
    )

    $var_type_builder = [AppDomain]::CurrentDomain.DefineDynamicAssembly((New-Object System.Reflection.AssemblyName('ReflectedDelegate')), [System.Reflection.Emit.AssemblyBuilderAccess]::Run).DefineDynamicModule('InMemoryModule', $false).DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
    $var_type_builder.DefineConstructor(
        'RTSpecialName, HideBySig, Public',
        [System.Reflection.CallingConventions]::Standard,
        $var_parameters
    ).SetImplementationFlags('Runtime, Managed')
    $var_type_builder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $var_return_type, $var_parameters).SetImplementationFlags('Runtime, Managed')

    return $var_type_builder.CreateType()
}

function get_c_function_from_powershell () {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [System.IntPtr] $library,
        [Parameter(Position = 1, Mandatory = $True)] [String] $function_name,
        [Parameter(Position = 2, Mandatory = $True)] [Type[]] $parameters_types,
        [Parameter(Position = 3)] [Type] $return_type
    )

    $function_address = GetProcAddress $library $function_name
    $delegate_function = get_delegate_type $parameters_types $return_type
    return get_function_from_c_pointer $function_address $delegate_function
}

function get_c_module_function_from_powershell () {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [String] $library_name,
        [Parameter(Position = 1, Mandatory = $True)] [String] $function_name,
        [Parameter(Position = 2, Mandatory = $True)] [Type[]] $parameters_types,
        [Parameter(Position = 3)] [Type] $return_type
    )

    $library = LoadLibrary $library_name
    return get_c_function_from_powershell $library $function_name $parameters_types $return_type
}

function GetLastError () {
    return $GetLastError_function.Invoke([IntPtr]::Zero)
}

function GetStringPointer () {
    Param ([Parameter(Position = 0, Mandatory = $True)] [String] $string)
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
    $length = $bytes.Length
    $string_address = $VirtualAlloc_function.Invoke([IntPtr]::Zero, $length, 0x3000, 0x04)
    [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $string_address, $length)
    return $string_address
}

function CreateProcessBar () {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [String] $start,
        [Parameter(Position = 1, Mandatory = $True)] [String] $end,
        [Parameter(Position = 2, Mandatory = $True)] [String] $character,
        [Parameter(Position = 3, Mandatory = $True)] [String] $empty,
        [Parameter(Position = 4, Mandatory = $True)] [UInt64] $size
    )
    $start_address = GetStringPointer $start
    $start_bytes = [System.BitConverter]::GetBytes($start_address.ToInt64())
    $end_address = GetStringPointer $end
    $end_bytes = [System.BitConverter]::GetBytes($end_address.ToInt64())
    $character_address = GetStringPointer $character
    $character_bytes = [System.BitConverter]::GetBytes($character_address.ToInt64())
    $empty_address = GetStringPointer $empty
    $empty_bytes = [System.BitConverter]::GetBytes($empty_address.ToInt64())
    $size_bytes = [System.BitConverter]::GetBytes($size)

    $progress = $VirtualAlloc_function.Invoke([IntPtr]::Zero, 40, 0x3000, 0x04)

    [System.Runtime.InteropServices.Marshal]::Copy($start_bytes, 0, $progress, 8)
    [System.Runtime.InteropServices.Marshal]::Copy($end_bytes, 0, [IntPtr]($progress.ToInt64() + 8), 8)
    [System.Runtime.InteropServices.Marshal]::Copy($character_bytes, 0, [IntPtr]($progress.ToInt64() + 16), 8)
    [System.Runtime.InteropServices.Marshal]::Copy($empty_bytes, 0, [IntPtr]($progress.ToInt64() + 24), 8)
    [System.Runtime.InteropServices.Marshal]::Copy($size_bytes, 0, [IntPtr]($progress.ToInt64() + 32), 8)

    return $progress
}

function print_all_state () {
    $print_all_state_function.Invoke([IntPtr]::Zero)
}

function add_state () {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [String] $state_name,
        [Parameter(Position = 1, Mandatory = $True)] [String] $character,
        [Parameter(Position = 2, Mandatory = $True)] [String] $color
    )

    $add_state_function.Invoke($state_name, $character, $color)
}

function add_rgb_state () {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [String] $state_name,
        [Parameter(Position = 1, Mandatory = $True)] [String] $character,
        [Parameter(Position = 2, Mandatory = $True)] [IntPtr] $red,
        [Parameter(Position = 3, Mandatory = $True)] [IntPtr] $green,
        [Parameter(Position = 4, Mandatory = $True)] [IntPtr] $blue
    )

    $add_rgb_state_function.Invoke($state_name, $character, $red, $green, $blue)
}

function messagef () {
    Param (
        [Parameter(Position = 0, Mandatory = $True)] [String] $message,
        [Parameter(Position = 1)] [String] $state_name = "OK",
        [Parameter(Position = 3)] [IntPtr] $pourcent = [IntPtr]::Zero,
        [Parameter(Position = 4)] [String] $start = "",
        [Parameter(Position = 5)] [String] $end = "`n",
        [Parameter(Position = 6)] [IntPtr] $progress = [IntPtr]::Zero,
        [Parameter(Position = 7)] [IntPtr] $add_progressbar = [IntPtr]::Zero,
        [Parameter(Position = 8)] [IntPtr] $oneline_progress = [IntPtr]::Zero
    )

    $messagef_function.Invoke($message, $state_name, $pourcent, $start, $end, $progress, $add_progressbar, $oneline_progress)
}

$_util_get_method = (
    [AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }
).GetType('Microsoft.Win32.UnsafeNativeMethods')

$GetProcAddress_func = $_util_get_method.GetMethod(
    'GetProcAddress',
    [reflection.bindingflags] "Public,Static",
    $null,
    [System.Reflection.CallingConventions]::Any,
    @(
        (New-Object System.Runtime.InteropServices.HandleRef).GetType(),
        [string]
    ),
    $null
)

$GetModuleHandle_func = $_util_get_method.GetMethod('GetModuleHandle')

$kernel32 = $GetModuleHandle_func.Invoke($null, @("kernel32.dll"))

$LoadLibrary_function = get_c_function_from_powershell $kernel32 "LoadLibraryA" @([String]) ([IntPtr])
$GetLastError_function = get_c_function_from_powershell $kernel32 "GetLastError" @([IntPtr]) ([IntPtr])
$VirtualAlloc_function = get_c_function_from_powershell $kernel32 "VirtualAlloc" @([IntPtr], [UInt32], [UInt32], [UInt32]) ([IntPtr])

$terminalmessages = LoadLibrary ".\TerminalMessages.dll"

$print_all_state_function = get_c_function_from_powershell $terminalmessages "print_all_state" @([IntPtr]) ([Void])
$add_state_function = get_c_function_from_powershell $terminalmessages "add_state" @([String], [String], [String]) ([Void])
$add_rgb_state_function = get_c_function_from_powershell $terminalmessages "add_rgb_state" @([String], [String], [IntPtr], [IntPtr], [IntPtr]) ([Void])
$messagef_function = get_c_function_from_powershell $terminalmessages "messagef" @([String], [String], [IntPtr], [String], [String], [IntPtr], [IntPtr], [IntPtr]) ([Void])

if ($MyInvocation.CommandOrigin -eq 'Runspace') {
    add_state "TEST" "T" "cyan"
    add_rgb_state "TEST2" "2" 188 76 53
    print_all_state

    $progress = CreateProcessBar "[" "]" "#" "-" 30

    messagef "test"
    messagef "test" "TEST" 50 " - " "`n`n" $progress 1 1
    messagef "test" "TEST2" 80
}
