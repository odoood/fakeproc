# fakeProc.tcl --
#
#       Simple package for faking procs in unit tests
#
# Author: odoood (2019)
#
# License: GPLv3 (or later version); see COPYING for full license info
#
package provide fakeProc 1.0

namespace eval ::fakeProc {
    namespace export procFake

    variable BACKUPNS {::fakeProc::backup}
}

proc ::fakeProc::procFake {name args body} {

    variable BACKUPNS

    set name [string trim $name]
    if {$name eq {}} {
        error "Name cannot be empty"
    }

    # Ensure name is fully-qualified (starts with "::")
    if {[string range $name 0 1] ne "::"} {
        error "Name not fully-qualified: '$name'"
    }

    # Check that the command exists
    if {[namespace which $name] ne $name} {

        # If not found check if namespace exists
        set nspace [namespace qualifiers $name]

        if {![namespace exists $nspace]} {
            error "Unknown namespace: '$nspace'"
        }

        # If namespace exists error on command name
        error "Unknown command: '$name'"
    }

    # Move original proc to the backup namespace with a relative name the same
    # as the fully-qualified name
    set backName $BACKUPNS
    append backName $name

    rename $name $backName

    return
}
