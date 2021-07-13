# fakeProc

Small TCL package to allow for easy faking of procs in unit tests.

It supports faking procs and commands in a given namespace.

## Usage

Use `::fakeProc::procFake` to create a proc fake for a given proc (e.g. in a test `-setup` script), and reset the same with `::fakeProc::resetProc` or `::fakeProc::resetAllProcs` (e.g. in a test `-cleanup` script).

### Examples

Setup in a tcltest file:

```tcl
package require fakeProc 1.0

# ... #

namespace eval ::myModule::test {

    # ... #

    namespace import ::fakeProc::procFake
    namespace import ::fakeProc::resetAllProcs

    # ... #

    test myModule-x.x {fake myProc1} -body {

	# myProc2 depends on myProc1, which accepts no args
        myProc2 one two three

    } -setup {

        # We want myProc1 to return nothing in this test
        procFake ::myModule::myProc1 {} {
            return
        }

        # ... #

    } -cleanup {
        # Restore myProc1 (and all others)
        resetAllProcs
    }
```


Using the `*` arg flag to create fake using the default formal args:

```tcl
    test myModule-x.x {fake myProc2} -body {

	# myProc3 depends on myProc2, which accepts three args
        myProc3 foo

    } -setup {

        # If '*' is the sole arg procFake uses the default arg specification of the
        # original myProc2, including any default args
        procFake ::myModule::myProc2 {*} {
            return "this is a fake which accepts all the same args"
        }

        # ... #

    } -cleanup {
        resetAllProcs
    }
```


**NOTE**: using the `*` arg flag for a command fake sets the fake formal args as
`args` and corresponding arg values must be accessed via it


```tcl
    test myModule-x.x {fake puts} -body {

	# myProc4 depends on the puts command
        myProc4 foo

    } -setup {

        # This will work to access the "string" arg of a puts call
        procFake ::myModule::puts {*} {
            set s [lindex $args end]
            return "Call to puts with string: $s"
        }

        # This will NOT work (the fake proc has no formal arg "string")
        procFake ::myModule::puts {*} {
            set s $string
            return "Call to puts with string: $s"
        }

    } -cleanup {
        resetAllProcs
    }
```
