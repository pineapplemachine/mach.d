# mach.text.html.namedchar

This package can be used to go back and forth between code point sequences and their names as designated by HTML5.

The full list of named sequences can be found here: https://www.w3.org/TR/html5/syntax.html#named-character-references

Here's a simple example of usage:

``` D
import mach.text.html.namedchar;
/// Get whether the code point or code point sequence has a name.
assert(NamedChar.isnamed("á"));
/// Get the name of a code point or code point sequence.
/// Some inputs have multiple valid names, in which case one name is returned.
assert(NamedChar.getname("á") == "aacute");
/// Get whether a string is a valid code point sequence name.
assert(NamedChar.isname("aacute"));
/// Get a code point sequence by name.
assert(NamedChar.getpoints("aacute") == "á"d);
```
