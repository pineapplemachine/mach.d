# mach.text.cstring


This package contains functions for working with cstrings, or null-terminated
strings.
The `tocstring` and `fromcstring` functions can be used to covert character
arrays to and from null-terminated strings, and the `cstringlength` function
can be used to determine the length in code units of a null-terminated string.

``` D
assert("hello".tocstring.cstringlength == 5);
assert("world\0".ptr.fromcstring == "world");
```


## mach.text.cstring.convert


The `tocstring` and `fromcstring` functions can be used to acquire a null-
terminated string from some input string, and a regular string from a pointer
to a null-terminated string, respectively.

`tocstring` returns a value of type `CString`, which imitates a string but
can be passed to functions which require a pointer.

``` D
assert("hello".tocstring.payload == "hello\0");
assert("world\0".ptr.fromcstring == "world");
```


`tocstring` optionally accepts a template parameter specifying how the output
should be encoded. The default is UTF-8, indicated by passing `char`.
Passing `wchar` would cause the output to be encoded in UTF-16, and `dchar`
in UTF-32.

``` D
assert("hello".tocstring!wchar.payload == "hello\0"w);
assert("hello".tocstring!dchar.payload == "hello\0"d);
```


`fromcstring` optionally accepts a limit, where characters beyond the length
limit are cut off. This can be used to prevent very long strings from causing
performance problems, if the full content of the string is not important in
that case.

If no limit is given, then the function will proceed indefinitely, until a
null byte is found. (Or, perhaps, when a memory error results from attempting
to accumulate such a long string.)

``` D
assert("hello\0".ptr.fromcstring!4 == "hell"); // Cuts off after the fourth character.
```


## mach.text.cstring.length


The `cstringlength` function can be used to determine the length of a
null-terminated string by traversing it.

``` D
assert("hello world\0".ptr.cstringlength == "hello world".length);
```


The function can also be called with wchar or dchar strings as its input.

``` D
assert("hello\0"w.ptr.cstringlength == 5);
assert("world\0"d.ptr.cstringlength == 5);
```


