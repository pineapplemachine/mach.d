# mach.d

A general-purpose library for the D programming language.

Distributed under the very permissive [zlib/libpng license](https://github.com/pineapplemachine/mach.d/blob/master/license).

## Overview

Be warned: "Stability" is meaningless in the context of this library. I am constantly rewriting and improving and breaking code.

That said, I take some pride in the thoroughness of this library's unit tests. Said tests are frequently verified on Win 7 with 32-bit dmd, and occassionally verified on OSX 10.9.5 with 64-bit dmd.

Maybe I'll think about a versioning system and proper releases once the content and foci of this library have been better-established, but honestly that may never happen. I'm really just writing whatever interests me, or that I need to support another project I'm persuing, and this repo is here to share with the world because FOSS is the best.

The majority of this package depends only on D's standard library, Phobos. Eventually I intend to cut ties with it completely.

The `mach.sdl` package requires some additional dependencies. See the [package readme](https://github.com/pineapplemachine/mach.d/blob/master/mach/sdl/readme.md) for details.

## Usage

The `mach` folder should be placed where you are loading dependencies from. In the case of *dmd* or *rdmd*, this is a directory passed using the `-I` argument. In the case of *dub*, this is a path added to a project using `dub add-path`.

Beware compiling mach with the `-unittest` flag when linking on Windows with Optlink; [a bug with Optlink](https://issues.dlang.org/show_bug.cgi?id=17077) causes the compilation to fail with a linker error. To compile on Windows with unit tests, the `-m32mscoff` switch must be passed to dmd/rdmd, and a version of Visual Studio including the linker must be available on the system.

See the [examples directory](https://github.com/pineapplemachine/mach.d/tree/master/examples) for some examples of how to use mach's functionality.

## Differences from Phobos

Major departures from Phobos' school of thought include:

### No auto-decoding strings

The mach library does not give special treatment to character strings. Unless otherwise specified, the functions defined throughout the library will treat an array of chars as just that - an an array of chars. The `mach.text.utf` module provides `utfencode` and `utfdecode` functions which should be called to explicitly encode and decode UTF-8 strings.

``` D
string str = "\xE3\x83\x84";
assert(str.length == 3);
auto decoded = str.utfdecode;
assert(decoded.front == 'ツ');
assert(decoded.walklength == 1);
```

### Arrays aren't ranges

Functions in this library do not necessarily accept _ranges_, they accept types which are _valid as ranges_. The distinction becomes most significant when working with arrays. Functions which accept ranges also accept types with an `asrange` property which returns an actual range. There are default `asrange` implementations for several types, including static and dynamic arrays, which functions throughout this library rely on to get a range from an inputted iterable when only a range will do.

``` D
// An array - but not a range
int[] array = [0, 1, 2, 3];
// A range which iterates over an array
auto range = array.asrange;
// Functions in this library accept either one: A range, or a type which
// is valid as a range via the `asrange` property, including arrays.
auto arrayfilter = array.filter!(n => n % 2);
auto rangefilter = range.filter!(n => n % 2);
assert(arrayfilter.equals(rangefilter));
```

Other types can become similarly valid as ranges by giving them an `asrange` method. With this other collections can become valid as ranges, too, such as the doubly-linked list type defined in `mach.collect`.

``` D
auto list = new LinkedList!int([0, 1, 2, 3]);
assert(list.filter!(n => n % 2).equals([1, 3]));
```

### Ranges are not "moving windows"

In Phobos, ranges are conceptualized as moving windows over some source of data. In mach, ranges are as stationary windows with a moving cursor or, in the case of bidirectional ranges, a pair of moving cursors.

The indexes referred to via opIndex and opSlice remain consistent even while consuming the range, as does length.

``` D
auto range = "hello".asrange;
assert(range.length == 5);
assert(range[0] == 'h');
range.popFront();
assert(range.length == 5);
assert(range[0] == 'h');
```

To get the number of elements remaining in a range, as the `length` property does in Phobos, ranges in this library support a `remaining` property which returns the number of elements the range will still iterate over.

``` D
auto range = "hello".asrange;
assert(range.remaining == 5);
range.popFront();
assert(range.remaining == 4);
```
