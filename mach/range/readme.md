# Overview

This package provides functions for dealing with collections of things, especially ranges.

Many of the modules come with some measure of documentation, and all of them include unit tests. In the absence of thorough documentation, the unit tests should hopefully prove sufficiently enlightening.

Here's a brief summary of some of the most useful modules included in this package:

### mach.range.asarray

Turn a lazy sequence into an eager one, in the form of an array. Supports static array creation, too, if the length of the sequence is known at compile time.

``` D
string hello_there = ["hello", "there"].join(" ").asarray;
```

### mach.range.asrange

Get a range for enumerating elements belonging to some arbitrary object. There are default implementations for static and dynamic arrays, associative arrays, and types implementing an integral-based opIndex.

``` D
assert("hello".asrange.front == 'h');
```

### mach.range.chain

Able to chain several iterables together. It is possible to chain both a sequence of iterables passed in as multiple arguments, and to chain the iterables contained within an iterable of identically-typed iterables. The `chain` method should be able to reliably determine which use case you intended, but in case not you can explicitly use `chainranges` for the former case and `chainiter` for the latter.

``` D
assert(["D", " ", "Man"].chain.asarray == "D Man");
assert(chain("D", " ", "Man").asarray == "D Man");
assert(["D", " ", "Man"].chainiter.asarray == "D Man");
assert(chainranges("D", " ", "Man").asarray == "D Man");
```

### mach.range.chunk

Break down an iterable into chunks of no larger than a specified size.

``` D
auto chunks = "abc123xyz!!".chunk(3);
assert(chunks[0] == "abc");
assert(chunks[$-1] == "!!");
```

### mach.range.contains

Check whether some iterable contains any instances of a value, or any elements satisfying a predicate.

``` D
assert("hello".contains('h'));
assert(!"hello".contains!isUpper);
```

### mach.range.distinct

Omits repeated elements from the source iterable. Can optionally accept a transformation function to apply to each element, such that the transformation is used as a key to determine uniqueness instead of the element itself.

``` D
assert("hello world".distinct.asarray == "helo wrd");
assert([1, 3, 2, 4].distinct!(n => n % 2).asarray == [1, 2]);
```

### mach.range.each

Eagerly applies a function to each element in an iterable. (For a lazily-evaluated equalivalent, see `mach.range.tap`.)

``` D
string hello_each = "";
"hello".each!(e => hello_each ~= e);
assert(hello_each == "hello");
```

### mach.range.ends

Provides `head` and `tail` functions, the former of which can be expected to work for all iterables valid as ranges and the latter of which only for iterables valid as bidirectional ranges.

``` D
assert("hello".head(3).asarray == "hel");
assert("hello".tail(3).asarray == "llo");
```

### mach.range.enumerate

Elements of an enumerated iterable are a tuple wherein the first item is an index in the sequence and the second item is the actual element of the source iterable.

``` D
foreach(index, character; "hello".enumerate){
    assert("hello"[index] == character);
}
```

### mach.range.filter

Archetypical filter higher-order function. Enumerates only those elements of a source iterable which satisfy a predicate.

``` D
assert("h e l l o!".filter!isAlpha.asarray == "hello");
```

### mach.range.find

For finding the first element, last element, or all elements matching a predicate. Also capable of performing the same operation for substrings.

Finding elements:

``` D
assert("hi".find('i').index == 1);
assert(!"hi".find('o').exists);
assert("aha!".findfirst('a').index == 0);
assert("aha!".findlast('a').index == 2);
assert("aha!".findall('a').front.index == 0);
assert("aha!".findall('a').back.index == 2);
```

Finding substrings:

``` D
assert("hello".find("el").index == 1);
assert(!"hello".find("no").exists);
assert("abcabc".findfirst("abc").index == 0);
assert("abcabc".findlast("abc").index == 3);
assert("abcabc".findall("abc").front.index == 0);
```

### mach.range.join

Inserts separators between elements of a source iterable.

``` D
assert(["a", "b", "c"].join(',').asarray == "a,b,c");
assert(["x", "y", "z"].join(", ").asarray == "x, y, z");
```

### mach.range.map

Applies a transformation to an arbitrary number of input iterables.

There is the conventional, singular form:

``` D
assert([0, 1, 2].map!(e => e + 1).asarray == [1, 2, 3]);
```

And a less conventional, plural form, which can also be thought of as applying the predicate to the result of zipping several iterables. (The map range is only as long as the shortest input, but the functions in `mach.range.pad` can be used to remedy this when undesireable.)

``` D
assert(map!((a, b) => (a + b))([0, 1, 2], [1, 4, 7]).asarray == [1, 5, 9]);
```

### mach.range.mutate

Same as a map function, except the results are also written back into the source iterable, overwriting the original values. Of course, this is only supported for iterables that actually allow modification of their contents.

The mutation is lazily-evaluated; `mach.range.consume` is used in this example to consume the range and apply the mutation to the input array's contents.

``` D
auto ints = [0, 1, 2];
ints.mutate!(e => e + 1).consume;
assert(ints == [1, 2, 3]);
```

### mach.range.ngrams

Can be used to get n-grams from a given input sequence, of course including bigrams and trigrams.

``` D
auto bigrams = "hey".ngrams!2.asarray;
assert(bigrams.length == 2);
assert(bigrams[0] == "he");
assert(bigrams[1] == "ey");
```

### mach.range.pad

Creates a range which is a source iterable preceded and/or followed by any number of some padding element.

``` D
assert("12".padfront('0', 4).asarray == "0012");
assert("12".padback('0', 4).asarray == "1200");
```

### mach.range.reduce

Provides both eager and lazy implementations of the reduce higher-order function, `reduceeager` and `reducelazy`. The `reduce` alias refers to the former, eager implementation.

``` D
assert([0, 1, 2, 3].reduce!((a, b) => (a + b)) == 6);
assert([0, 1, 2, 3].reduceeager!((a, b) => (a + b)) == 6);
assert([0, 1, 2, 3].reducelazy!((a, b) => (a + b)).asarray == [0, 1, 3, 6]);
```

### mach.range.reduction

Provides common abstractions of the reduce function, such as `sum` and `product`.

``` D
assert([2, 3, 4].sum == 9);
assert([2, 3, 4].product == 24);
```

### mach.range.retro

Iterates over something backwards, provided the source iterable supports it.

``` D
assert("hello".retro.asarray == "olleh");
```

### mach.range.split

Splits an iterable into separate iterables on each occurrence of a separator.

``` D
auto splitted = "how are you".split(" ").asarray;
assert(splitted.length == 3);
assert(splitted[0] == "how");
assert(splitted[$-1] == "you");
```

### mach.range.strip

Returns a range which is the same as a source iterable but with front and/or back elements meeting some predicate excluded.

``` D
assert("__hello__".stripfront('_').asarray == "hello__");
assert("__hello__".stripback('_').asarray == "__hello");
assert("__hello__".stripboth('_').asarray == "hello");
assert("  hello  ".stripboth!isWhite.asarray == "hello");
```

### mach.range.tap

Evaluates a function for each element in an input iterable, but only when that element is actually accessed. It is, in a way, a lazy analogue to `mach.range.each`.

``` D
auto tapcount = 0;
auto range = "hello".tap!(e => tapcount++);
assert(tapcount == 0);
range.consume();
assert(tapcount == 5);
```
