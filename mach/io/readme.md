# mach.io


This package implements functionality for outputting and inputting data to and
from the outside world, e.g. standard input/ouput and file input/output.


## mach.io.stdio


This module provides an abstraction for common uses of the stdin, stdout, and
stderr, streams as implemented in `mach.io.stream.stdiostream`.

It defines an `stdio` namespace with several methods:
- `write`, `writeln`, and `flushout` for interacting with stdout.
- `error`, `errorln`, and `flusherr` for interacting with stderr.
- `read` and `readln` for interacting with stdin.

The `stdio.write`, `stdio.writeln`, `stdio.error`, and `stdio.errorln` methods
accept any number of arguments, which are all converted to strings using
`mach.text.str` and then concatenated.
The resulting string is outputted to stdout or stderr and, in the case of
`stdio.writeln` and `stdio.errorln`, also terminated by a newline character.

``` D
stdio.writeln("Hello, world!");
stdio.errorln("Oh no!");
```

`stdio.read` returns a range for enumerating the contents of the stdin stream.
By default, the range has elements of type `char`.
The method optionally accepts a template argument defining the element type,
for when a type other than `char` is desired.

The `stdio.readln` method acquires data from stdin until a newline character
is encountered. It always returns a string.

``` D
stdio.writeln("What is your name?");
string name = stdio.readln();
stdio.writeln("Hello, ", name, "!");
```


## mach.io.stream


This package implements various stream types for reading or writing data,
and provides tools for operating upon those streams.


