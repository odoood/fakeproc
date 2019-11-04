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
    namespace export procFake resetProc

    variable BACKUPNS {::fakeProc::backup}
    variable FAKED_NAMES {}
}

proc ::fakeProc::resetProc {name} {

    variable FAKED_NAMES

    set name [string trim $name]

    # Ensure name is fully-qualified (starts with "::")
    if {[string range $name 0 1] ne "::"} {
        error "Name not fully-qualified: '$name'"
    }

    # Ensure name has been faked (check list of names)
    if {[lsearch -exact $FAKED_NAMES $name] < 0} {
        error "No fake created for '$name'"
    }

    return
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

    # Ensure namespace exists
    set nspace [namespace qualifiers $name]
    set ntail [namespace tail $name]

    if {![namespace exists $nspace]} {
        error "Unknown namespace: '$nspace'"
    }

    set useDefArgs [expr {$args eq "*"}]
    set procSource {}

    # If command exists take a backup
    if {[namespace which $name] eq $name} {

        # Move original proc to the backup namespace with a relative name from
        # the fully-qualified name
        set backup [GetBackupName $name]

        rename $name $backup

        set procSource $backup

    } elseif {[namespace which "::$ntail"] ne ""} {

        # If there is a global version of the proc name set that as source
        set procSource "::$ntail"
    }

    # Set the default args value according to the source proc
    if {$useDefArgs} {

        set args "args"

        if {$procSource ne {}} {
            set args [info args $procSource]

            # Get the default values and set them in the list of args
            for {set i 0} {$i < [llength $args]} {incr i} {

                set arg [lindex $args $i]

                # If arg has default value set the item in the list to the form
                # for default formal arguments
                if {[info default $procSource $arg defVal]} {
                    lset args $i [concat $arg $defVal]
                }
            }
        }
    }

    # Create the fake proc
    proc $name $args $body

    return
}



# Get the backup name for a proc (without checking existence)
proc ::fakeProc::GetBackupName {name} {
    variable BACKUPNS
    return $BACKUPNS$name
}
