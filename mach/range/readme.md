# mach.range

This package contains numerous functions which operate on ranges and iterables. This documentation is by no means exhaustive. For more detailed explanations of arguments and examples of usage, please refer to the source of the modules themselves. Each module concludes with unittests, often rather thorough, which should be able to provide an effective description of how its functions work.

## mach.range.asarray

The `asarray` method can be used to turn a lazily-evaluated sequence into a fully in-memory array.

If the range has a known length, then that will be used to make array construction more efficient.

``` D
auto range = rangeof(0, 1, 2, 3); // Range containing the elements 0, 1, 2, 3.
auto array = range.asarray;
assert(array.length == 4);
assert(array == [0, 1, 2, 3]);
```

``` D
auto range = finiterangeof(4, 0); // A range of four 0s.
auto array = range.asarray;
assert(array.length == 4);
assert(array == [0, 0, 0, 0]);
```

To create an array from an infinite range, an explicit maximum length must be specified as an argument to `asarray`. Otherwise, the maximum length argument is optional.

``` D
auto range = infrangeof('?'); // An infinite range of '?'.
auto array = range.asarray(3);
assert(array == "???");
```

``` D
auto range = rangeof(0, 1, 2, 3); // Range containing the elements 0, 1, 2, 3.
auto array = range.asarray(2); // Array containing the first two elements.
assert(array.length == 2);
assert(array == [0, 1]);
```

Calling `asarray` for a type that is already an array will simply return the argument.

``` D
auto array = [0, 1, 2];
assert(array.asarray is array);
```

## mach.range.asrange

Get a range for enumerating elements belonging to a range, or an object which is valid as a range via its own `asrange` property. This package provides default implementations for static, dynamic, and associative arrays.

Every function in this library which requires a range accepts any iterable valid as a range and calls `asrange` for that iterable to acquire a range. It is strongly recommended that code utilizing or extending this library duplicate this pattern in its own functions which operate upon ranges.

``` D
int[] array = [0, 1, 2, 3];
auto range = array.asrange;
assert(range.front == 0);
assert(range.back == 3);
assert(range.length == 4);
```

``` D
int[4] array = [0, 1, 2, 3];
auto range = array.asrange;
assert(range.front == 0);
assert(range.back == 3);
assert(range.length == 4);
```

``` D
int[string] array = ["one": 1, "two": 2, "three": 3];
auto range = array.asrange;
assert(range.length == 3);
// Note that order of elements cannot be guaranteed, hence `any`.
assert(range.any!(e => e.key == "one" && e.value == 1));
```

Collections in this library implement their own `asrange` methods, allowing those collections to be passed directly to functions which operate upon ranges. (Or, more strictly speaking, upon iterables which are valid as ranges.)

``` D
auto list = new LinkedList!int([0, 1, 2, 3]);
auto range = list.asrange;
assert(range.equals([0, 1, 2, 3]));
assert(list.map!(e => e + 1).equals([1, 2, 3, 4]));
assert(list.filter!(e => e % 2).equals([1, 3]));
```

Calling `asrange` for a type that is already a range will simply return the argument.

``` D
auto range = rangeof(0, 1, 2, 3);
assert(range.asrange is range);
```

## mach.range.chain

The `chain` function returns a range which enumerates the contents of several iterables sequentially. It is possible to chain either a sequence of iterables passed in as multiple arguments, or to chain the iterables contained within an iterable of identically-typed iterables.

``` D
assert(["D", " ", "Man"].chain.equals("D Man"));
assert(chain("D", " ", "Man").equals("D Man"));
```

The `chain` function should be able to reliably determine which case you intended, but in case not you can explicitly use `chainiters` to chain a sequence of iterables passed as variadic arguments and `chainiter` to chain the iterables contained within a single passed iterable.

``` D
assert(["D", " ", "Man"].chainiter.equals("D Man"));
assert(chainiters("D", " ", "Man").equals("D Man"));
```

## mach.range.chunk

The `chunk` function breaks an iterable into sequential chunks of the specified size. If the iterable is not evenly divisible by the given chunk size, then the final element of the chunk range will be shorter than that given size.

``` D
auto range = "abc123xyz!!".chunk(3);
assert(range[0] == "abc");
assert(range[1] == "123");
assert(range[2] == "xyz");
assert(range[3] == "!!"); // Shorter because range isn't evenly divisble by 3.
assert(range.length == 4);
```

## mach.range.compare

The `compare` function offers a way to compare the contents of two iterables using a predicate function which accepts both an element from the first and the second range.

``` D
assert([0, 1, 2].compare!((a, b) => (a == b - 1))([1, 2, 3]));
```

This module also provides an `equals` function, which constitutes the most immediately obvious use case of the `compare` function.

``` D
assert([0, 1, 2].equals([0, 1, 2]));
assert(rangeof(0, 1, 2).equals([0, 1, 2]));
```

## mach.range.consume

The `consume` function consumes a range. This is primarily useful for ranges which may modify state while they are being enumerated.

For example, the `tap` function adds a callback for each element of an input iterable. The callback is only evaluated as that element is popped from the range.

``` D
int count;
// Increment `count` every time an element is popped.
auto range = [0, 1, 2, 3].tap!((e){count++;});
assert(count == 0);
range.consume;
assert(count == 4);
```

## mach.range.contains

The `contains` function can be used to determine whether some iterable contains any elements satisfying a predicate, or any values being equal to a given argument.

``` D
assert("hello".contains!(ch => ch == 'h'));
assert(!"hello".contains!(ch => ch == 'x'));
```

``` D
assert("hello".contains('h'));
assert(!"hello".contains('x'));
```

## mach.range.distinct

The range returned by `distinct` uses an associative array to omit repeated elements from the iterable used to construct it. The function optionally accepts a transformation function which derives a key from an element to determine uniqueness, rather than the element itself. Note that the key must be hashable.

``` D
assert("hello world".distinct.equals("helo wrd"));
```

``` D
// Use each element itself as the uniqueness key.
assert([2, 1, 2, 11, 10, 12].distinct.equals([2, 1, 11, 10, 12]));
// Use (element % 10) as the uniqueness key.
assert([2, 1, 2, 11, 10, 12].distinct!(e => e % 10).equals([2, 1, 10]));
```

## mach.range.each

The `each` function eagerly applies a function to each element in an iterable.

For a lazy-evaluated equivalent, where the function is applied only as a range is consumed, see `tap`.

``` D
string hello = "";
"hello".each!(e => hello ~= e);
assert(hello == "hello");
```

## mach.range.ends

This module provides `head` and `tail` functions to get the leading and trailing elements of an iterable.

The `head` function will operate on any range.

``` D
assert("hello".head(3).equals("hel"));
```

The `tail` function can only operate on random-access ranges with length.

``` D
assert("hello".tail(3).equals("llo"));
```

## mach.range.enumerate

Given an input iterable, the `enumerate` function returns a range wrapping each element in a struct with both the index in the iterable at which the element was encountered, and the element itself.

The elements of the range act like tuples.

``` D
auto range = "hello".enumerate;
assert(range.front.index == 0);
assert(range.front.value == 'h');
foreach(index, value; range){
    assert("hello"[index] == value);
}
```

## mach.range.filter

The `filter` function enumerates only those elements of an input iterable matching a predicate.

``` D
auto range = "h e l l o".filter!(ch => ch != ' ');
assert(range.equals("hello"));
```

## mach.range.find

This module provides `findfirst`, `findlast`, and `findall` functions for retrieving the indexes and values of either elements or substrings of an input iterable.

The `findfirst` and `findlast` functions are eagerly evaluated. The `findall` function is lazily evaluated; it returns a range for enumerating over the results of the operation.

The `find` function defined in the module is an alias of `findfirst`.

Examples of using these functions to find elements:

``` D
auto str = "hello world";
auto l = str.find('l');
assert(l.exists);
assert(l.index == 2);
assert(l.value == 'l');
auto e = str.find!(ch => ch != 'h');
assert(e.exists);
assert(e.index == 1);
auto x = str.find('x');
assert(!x.exists);
```

``` D
auto str = "hello world";
auto l = str.findlast('l');
assert(l.exists);
assert(l.index == 9);
assert(l.value == 'l');
auto x = str.find('x');
assert(!x.exists);
```

``` D
auto str = "hello world";
auto range = str.findall('l');
assert(range.front.index == 2);
assert(range.front.value == 'l');
range.popFront();
assert(range.front.index == 3);
range.popFront();
assert(range.front.index == 9);
range.popFront();
assert(range.empty);
```

Examples of using these functions to find substrings:

``` D
auto str = "this is a test, yes a test";
auto first = str.find("test");
assert(first.exists);
assert(first.index == 10);
assert(first.value == "test");
```

``` D
auto str = "this is a test, yes a test";
auto last = str.findlast("test");
assert(last.exists);
assert(last.index == 22);
assert(last.value == "test");
```

``` D
auto str = "this is a test, yes a test";
auto range = str.findall("test");
assert(range.front.index == 10);
assert(range.front.value == "test");
range.popFront();
assert(range.front.index == 22);
assert(range.front.value == "test");
range.popFront();
assert(range.empty);
```

## mach.range.join

The `join` function can be used to join iterable elements of an input iterable with a separator. The separator can be either an element of the joined iterables, or an iterable of elements implicitly convertible to the element type of the joined iterables.

Its complement is the `split` function.

``` D
assert(["hello", "world"].join(' ').equals("hello world"));
assert(["x", "y", "z"].join(", ").equals("x, y, z"));
```

## mach.range.map

The `map` function creates a range for which each element is the result of a transformation applied to the corresponding element of the input iterable.

``` D
assert([0, 1, 2, 3].map!(e => e + 1).equals([1, 2, 3, 4]));
assert([-1, 0, 1].map!(e => e >= 0).equals([false, true, true]));
```

It's also possible to compose a `map` function which operates on more than one input iterable. The range requires a transformation function which accepts as arguments an element from each input. The resulting range is only as long as the shortest input iterable.

This usage of `map` is conceptually similar to zipping several iterables and mapping the zipped iterable. (It's worth noting that internally `map` is not implemented this way; rather `zip` is implemented as an abstraction of this function.)

``` D
auto inputa = [0, 1, 2];
auto inputb = [3, 4, 5];
assert(map!((a, b) => (a + b))(inputa, inputb).equals([3, 5, 7]));
```

## mach.range.ngrams

The `ngrams` function can be used to generate n-grams given an input iterable.

The length of each n-gram is given as a template argument. Calling `ngrams!2` enumerates bigrams, `ngrams!3` enumerates trigrams, and so on.

``` D
assert("hello".ngrams!2.equals(["he", "el", "ll" ,"lo"]));
```

One of the more practical use cases for this function is to generate n-grams from a sequence of words.

``` D
auto text = "hello how are you";
auto words = text.split(' ');
auto bigrams = words.ngrams!2;
assert(bigrams.equals([["hello", "how"], ["how", "are"], ["are", "you"]]));
```

## mach.range.pad

The `padfront` and `padback` functions can be used to pad the beginning or end of an input iterable with a given element, such that the total length of the returned range matches the length given at initialization.

``` D
assert("12".padfront('0', 4).equals("0012"));
assert("12".padback('0', 4).equals("1200"));
```

## mach.range.reduce

This module provides both eager and lazy implementations of the reduce higher- order function, `reduceeager` and `reducelazy`. The functions enumerate over an input iterable and use a passed reduction function to accumulate a value.

The `reduceeager` function is also accessible by its alias `reduce`, as eager reduction is the more commonly-used form of the reduce function.

``` D
assert([0, 1, 2, 3].reduce!((a, b) => (a + b)) == 6);
assert([0, 1, 2, 3].reduceeager!((a, b) => (a + b)) == 6);
```

``` D
assert([0, 1, 2, 3].reducelazy!((a, b) => (a + b)).asarray == [0, 1, 3, 6]);
```

## mach.range.retro

The `retro` function can be used to enumerate the contents of an input iterable in reverse order.

``` D
assert([0, 1, 2].retro.equals([2, 1, 0]));
assert("hello".retro.equals("olleh"));
```

## mach.range.split

The `split` function splits an input iterable on occurrences of an element or of a substring. It is a complement to the `join` function.

``` D
assert("hello world".split(' ').equals(["hello", "world"]));
assert("x, y, z".split(", ").equals(["x", "y", "z"]));
```

## mach.range.strip

This module provides functions for stripping the frontmost and/or backmost elements of a range that meet a predicate. The functions are `stripfront`, `stripback`, and `stripboth`. The `stripboth` function can also be referred to using the `strip` alias.

``` D
assert("  hello world ".strip!(ch => ch == ' ').equals("hello world"));
```

``` D
assert("__hello__".stripfront('_').equals("hello__"));
assert("__hello__".stripback('_').equals("__hello"));
assert("__hello__".stripboth('_').equals("hello"));
```

## mach.range.tap

The `tap` function returns a range which performs some function for each element as it's consumed.

See the `each` function for an eagerly-evaluated equivalent.

``` D
int count;
// Increment `count` every time an element is popped.
auto range = [0, 1, 2, 3].tap!((e){count++;});
assert(count == 0);
range.consume;
assert(count == 4);
```

## mach.range.walk

This module implements the `walklength`, `walkindex`, and `walkslice` functions. These can be used to acquire the length, the value at an index, and a slice of an input iterable, respectively, by actually traversing the input.

This is useful for ranges that do not actually implement `length`, `opIndex`, or `opSlice` because traversal is the only way to actually determine them.

``` D
// Range iterates the numbers 0 to 10.
// This range doesn't implement length, opIndex, or opSlice because they
// can't be evaluated except by traversal.
auto range = recur!(n => n + 1, n => n == 10)(0);
assert(range.walklength == 10);
assert(range.walkindex(0) == 0);
assert(range.walkslice(0, 3).equals([0, 1, 2]));
```

## mach.range.zip

The `zip` function accepts any number of input iterables. Elements of the returned range are each a tuple containing the elements of the zipped inputs. The zipped range is only as long as the shortest input.

``` D
auto range = zip("abc", "xyz");
assert(range.front == tuple('a', 'x'));
range.popFront();
assert(range.front == tuple('b', 'y'));
range.popFront();
assert(range.front == tuple('c', 'z'));
range.popFront();
assert(range.empty);
```
