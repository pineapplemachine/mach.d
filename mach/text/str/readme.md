# mach.text.str


This package implements the `str` function, which may be used to generate a
useful string representation of just about anything.

``` D
assert(str("Hello!") == "Hello!");
assert(str(1234) == "1234");
```


## mach.text.str.arrays


This module implements functions used by `str` to serialize arrays and other
iterable types; they are not intended to be called directly.


## mach.text.str.primitives


This module implements functions used by `str` to serialize various primitive
types; they are not intended to be called directly.


## mach.text.str.settings


This module defines a `StrSettings` type, which may be used to customize the
behavior of the `str` serialization function.


## mach.text.str.str


The `str` function may be used to acquire a string representation of just about
anything.
It optionally accepts a `StrSettings` object as a template argument to specify
behavior.

``` D
assert(str(100) == `100`);
assert(str(1.234) == `1.234`);
assert(str('x') == `x`);
assert(str("hello") == `hello`);
assert(str([1, 2, 3]) == `[1, 2, 3]`);
assert(str(["key": "value"]) == `["key": "value"]`);
assert(str(null) == `null`);
```

``` D
enum Enum{Hello, World}
assert(str(Enum.Hello) == `Hello`);
assert(str(Enum.World) == `World`);
```

``` D
struct MyType{
    string name;
    int x, y;
}
assert(str(MyType("hi", 1, -2)) == `{name: "hi", x: 1, y: -2}`);
```

``` D
import mach.range : map, filter;
import mach.text.ascii : toupper;
auto numrange = [0, 1, 2, 3, 4, 5, 6].map!(n => n * n).filter!(n => n % 2 == 0);
assert(str(numrange) == `[0, 4, 16, 36]`);
auto charrange = "hello world!".map!toupper;
assert(str(charrange) == `HELLO WORLD!`);
```


The default settings show a minimum of information about the type that's being
serialized.
This default preset can be referred to with `StrSettings.Default` or
`StrSettings.Concise`. The `StrSettings.Verbose` preset includes almost all
type information. Other presets include `StrSettings.Medium` and
`StrSettings.Maximum`.

``` D
assert(str!(StrSettings.Verbose)(int(100)) == `int(100)`);
assert(str!(StrSettings.Verbose)(ulong(100)) == `ulong(100)`);
assert(str!(StrSettings.Verbose)(char('x')) == `char('x')`);
```


## mach.text.str.tuples


This module implements functions used by `str` to serialize tuples;
they are not intended to be called directly.


## mach.text.str.types


This module implements functions used by `str` to serialize user-defined types;
they are not intended to be called directly.


