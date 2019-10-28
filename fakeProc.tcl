# fakeProc.tcl --
#
#       Simple package for faking procs in unit tests
#
# Author: odoood (2019)
#
# License: GPLv3 (or later version); see COPYING for full license info
#
package provide fakeProc 1.0

namespace eval fakeProc {
    namespace export procFake
}

proc fakeProc::procFake {name args body} {

    set name [string trim $name]
    if {$name eq {}} {
        error "Name cannot be empty"
    }
}
