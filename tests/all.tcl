#
# all.tcl test runner for fakeProc tests
#

package require Tcl 8.4
package require tcltest 2.2
#package require example
::tcltest::configure -testdir \
    [file dirname [file normalize [info script]]]
eval ::tcltest::configure $argv
::tcltest::runAllTests
