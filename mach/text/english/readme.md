# mach.text.english


This package provides functions for performing common operations with
English words.

``` D
// Get the name of a number in English
assert(100.englishnumber == "one hundred");
// Get the plural form of a singular English word
assert("hello".plural == "hellos");
// Get whether a noun would be preceded by "a" or "an"
assert("world".aan == "a");
assert("island".aan == "an");
```


## mach.text.english.numbers


The `englishnumber` can be used to get a verbose English representation of any
integer.
It optionally accepts a `EnglishNumberSettings` object as a template argument
to change its behavior.

``` D
assert(englishnumber(0) == "zero");
assert(englishnumber(1) == "one");
assert(englishnumber(-1) == "negative one");
assert(englishnumber(100) == "one hundred");
assert(englishnumber(1000) == "one thousand");
assert(englishnumber(1000000000) == "one billion");
```

``` D
enum settings = EnglishNumberSettings.Ordinal;
assert(englishnumber!settings(1) == "first");
assert(englishnumber!settings(2) == "second");
assert(englishnumber!settings(3) == "third");
assert(englishnumber!settings(999) == "nine hundred ninety-ninth");
```


