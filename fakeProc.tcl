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
    namespace export procFake resetProc resetAllProcs

    variable BACKUPNS {::fakeProc::backup}
    variable FAKED_NAMES {}
}

# Resets all procs that have been faked
proc ::fakeProc::resetAllProcs {} {
    variable FAKED_NAMES

    foreach name $FAKED_NAMES {
        resetProc $name
    }

    return
}

proc ::fakeProc::resetProc {name} {

    variable FAKED_NAMES

    set name [string trim $name]

    # Ensure name is fully-qualified (starts with "::")
    if {[string range $name 0 1] ne "::"} {
        error "Name not fully-qualified: '$name'"
    }

    # Ensure name has been faked (check list of names)
    if {![IsProcFaked $name]} {
        error "No fake created for '$name'"
    }

    # Restore backup (if it exists, otherwise delete target)
    set backup [namespace which [GetBackupName $name]]

    rename $name {}

    if {$backup ne ""} {
        rename $backup $name
    }

    # Remove name from list
    set i [lsearch -exact $FAKED_NAMES $name]
    set FAKED_NAMES [lreplace $FAKED_NAMES $i $i]

    return
}

proc ::fakeProc::procFake {name args body} {

    variable BACKUPNS
    variable FAKED_NAMES

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
    set tail [namespace tail $name]

    if {![namespace exists $nspace]} {
        error "Unknown namespace: '$nspace'"
    }

    # Add the proc name to the faked names list
    if {![IsProcFaked $name]} {
        lappend FAKED_NAMES $name
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

    } elseif {[namespace which ::$tail] ne "" && [info procs ::$tail] ne ""} {

        # If there is a global version of the name, and it is a proc (not a std
        # Tcl command written in C) set that as source
        set procSource ::$tail
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

# Check whether a name has been faked and is in the list
proc ::fakeProc::IsProcFaked {name} {
    variable FAKED_NAMES
    return [expr {[lsearch -exact $FAKED_NAMES $name] >= 0}]
}