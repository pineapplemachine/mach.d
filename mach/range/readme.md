# mach.range


This package implements a variety of functions for performing operations
upon iterables, typically either ranges or ones that are valid as ranges.
The majority of functions that are possible to implement as lazy sequences
do in fact return ranges.

Please note that fully documenting this package is a work in progress.
If a module isn't documented here, comments and unit tests in the module
source should hopefully provide sufficient explanation of usage and
functionality.


## mach.range.asarray


The `asarray` function can be applied to an iterable to produce a fully
in-memory array of its contents.

When the input is known to be finite, the function can be evaluated with the
iterable as the only argument.

Note that when the input is itself an array, the function returns `array.dup`.

``` D
import mach.range.filter : filter;
auto range = [0, 1, 2, 3].filter!(n => n % 2);
auto array = range.asarray;
assert(array == [1, 3]);
```

``` D
import mach.range.rangeof : rangeof;
auto array = rangeof(0, 1, 2, 3).asarray;
assert(array == [0, 1, 2, 3]);
```


For known finite inputs, the `asarray` function can receive an optional
argument indicating maximum length;
any elements in the input past that length will be excluded from the array.
For infinite inputs, the maximum length argument is mandatory.

When the input is itself an array, the function returns `slice.dup` where
`slice` is the first so many elements of the array, as determined by the
specified maximum length.

``` D
import mach.range.rangeof : rangeof;
auto array = rangeof(0, 1, 2, 3).asarray(2);
assert(array == [0, 1]);
```

``` D
import mach.range.repeat : repeat;
auto range = [0, 1, 2].repeat; // Repeat infinitely
auto array = range.asarray(5);
testeq(array, [0, 1, 2, 0, 1]);
```

``` D
import mach.range.repeat : repeat;
auto range = [0, 1, 2].repeat; // Repeat infinitely
static assert(!is(typeof(
    range.asarray // Fails because a maximum length is not provided.
)));
```


The `asarray` function is also implemented for associative arrays.
The constructed array is a sequence of key, value pairs represented
by the `KeyValuePair` type defined in `mach.types.keyvaluepair`.

``` D
auto array = ["hello": "world"].asarray;
assert(array.length == 1);
assert(array[0].key == "hello");
assert(array[0].value == "world");
```


## mach.range.asrange


Many iterables, though they are not themselves ranges, should logically be
valid as ranges. For example, though an array is not itself a range, a range
can be created which enumerates its elements.

The `asrange` method may be implemented for any type; for example, the
collections in `mach.collect` typically have an `asrange` method.
The purpose of this package is to provide default `asrange` implementations
for primitive types: Specifically, arrays and associative arrays.
`asrange` is additionally implemented for ranges, in this case the function
simply returns its input.

Functions in mach which require a range to operate upon accept any iterable
valid as a range and internally call `asrange` with that iterable in order
to acquire a range. It is strongly recommended that code utilizing or extending
this library duplicate this pattern in its own functions operating upon ranges.

``` D
// Acquire a range from an array.
auto range = [0, 1, 2, 3].asrange;
assert(range.front == 0);
assert(range.back == 3);
```

``` D
// Acquire a range from an associative array.
auto range = ["hello": "world"].asrange;
assert(range.length == 1);
assert(range.front.key == "hello");
assert(range.front.value == "world");
foreach(key, value; range){
    // The ranges produced for associative arrays
    // can be enumerated like associative arrays.
}
```

``` D
/// Acquire a range from a range.
import mach.range.rangeof : rangeof;
auto range = rangeof(0, 1, 2, 3);
assert(range.asrange is range);
```


## mach.range.asstaticarray


The `asstaticarray` function can be used to produce a static array from either
a list of variadic arguments, or from an iterable whose length is known at
compile time.

``` D
int[4] array = asstaticarray(0, 1, 2, 3);
assert(array == [0, 1, 2, 3]);
```

``` D
import mach.range.rangeof : rangeof;
auto range = rangeof!int(0, 1, 2, 3);
int[4] array = range.asstaticarray!4;
assert(array == [0, 1, 2, 3]);
```


When constructing a static array from an iterable, `asstaticarray` will produce
an error if the actual length of the input iterable does not match the expected
length.
Except for in release mode, the function throws an `AsStaticArrayError` by way
of reporting this error. In release mode, the conditionals required to perform
this error reporting are ommitted.

``` D
import mach.range.rangeof : rangeof;
import mach.error.mustthrow : mustthrow;
auto range = rangeof!int(0, 1, 2, 3);
mustthrow!AsStaticArrayError({
    range.asstaticarray!10; // Fails because of incorrect length.
});
```


## mach.range.chain


The `chain` function serves two similar but differing purposes.
It accepts a sequence of iterables as arguments, producing a range which
enumerates the elements of the inputs in sequence.
Or it accepts an iterable of iterables, producing a range which
enumerates the elements of the input's own elements in sequence.

``` D
import mach.range.compare : equals;
// Chain several iterables
assert(chain("hello", " ", "world").equals("hello world"));
// Chain an iterable of iterables
assert(["hello", " ", "world"].chain.equals("hello world"));
```


Though the `chain` function should in almost all cases be able to discern
intention, the package provides `chainiter` and `chainiters` functions when
it becomes necessary to explicitly specify which form of chaining is desired.

``` D
import mach.range.compare : equals;
assert(chainiters("hello", " ", "world").equals("hello world"));
```

``` D
import mach.range.compare : equals;
assert(chainiter(["hello", " ", "world"]).equals("hello world"));
```


## mach.range.chunk


The `chunk` function returns a range for enumerating sequential chunks of an
input, its first argument being the input iterable and its second argument being
the size of the chunks to produce.
If the iterable is not evenly divisible by the given chunk size, then the
final element of the chunk range will be shorter than the given size.

The input iterable must support slicing and have numeric length. The outputted
range is bidirectional, has `length` and `remaining` properties, allows random
access and slicing operations, and can be saved.

``` D
auto range = "abc123xyz!!".chunk(3);
assert(range.length == 4);
assert(range[0] == "abc");
assert(range[1] == "123");
assert(range[2] == "xyz");
// Final chunk is shorter because the input wasn't evenly divisble by 3.
assert(range[3] == "!!");
```


## mach.range.compareends


The `headis` and `tailis` functions can be used to compare the leading or
trailing elements of one iterable to another, respectively.
The first argument to either function is an iterable to be searched in,
and the second argument is the subject to be searched for. In the case of
`headis`, the leading elements of the first iterable must be equal to all the
elements of the second. In the case of `tailis`, the trailing elements of
the first iterable must be equal to all the elements of the second.

Note that attempting to call either function with two infinite iterables will
result in a compile error.

``` D
assert("hello world".headis("hello"));
assert("hello world".tailis("world"));
```

``` D
// An iterable always begins with an empty one.
assert("greetings".headis(""));
assert("salutations".tailis(""));
```

``` D
// A finite iterable never begins or ends with an infinite one.
import mach.range.rangeof : infrangeof;
assert(!"yo".headis(infrangeof('k')));
assert(!"hi".tailis(infrangeof('k')));
```


Both functions optionally accept a comparison function as a template argument.
By default, the comparison between elements of the inputs is simple equality.

``` D
import mach.text.ascii : tolower;
alias compare = (a, b) => (a.tolower == b.tolower);
assert("Hello World".headis!compare("HELLO"));
```


## mach.range.consume


The `consume` function consumes an input iterable.
This is primarily useful for ranges which may modify state while they are
being enumerated.

For example, the `tap` function adds a callback for each element of an input
iterable. The callback is only evaluated as that element is popped from the
range.

``` D
import mach.range.tap : tap;
int count = 0;
// Increment `count` every time an element is popped.
auto range = [0, 1, 2, 3].tap!((e){count++;});
assert(count == 0);
range.consume; // Consume the range
assert(count == 4);
```


The module also provides a `consumereverse` function for performing the same
consumption operation, but in reverse.

``` D
import mach.range.tap : tap;
string str = "";
auto range = "forwards".tap!((ch){str ~= ch;});
assert(str == "");
range.consumereverse;
assert(str == "sdrawrof");
```


## mach.range.contains


This module implements a `contains` function capable of searching an input
iterable for an element satisfying a predicate, for an element equal to an
input, or for a substring.

``` D
// Search for an equivalent element.
assert("hello".contains('h'));
assert(!"hello".contains('x'));
```

``` D
// Search for an element satisfying a predicate.
import mach.text.ascii : isupper;
assert("upper CASE".contains!isupper);
assert(!"lower case".contains!isupper);
```

``` D
// Search for a substring.
assert("hello world".contains("hello"));
assert("hello world".contains("world"));
assert(!"hello world".contains("nope"));
```

``` D
// Search for a case-insensitive substring.
import mach.text.ascii : tolower;
alias compare = (a, b) => (a.tolower == b.tolower);
assert("Hello World".contains!compare("HELLO"));
assert(!"Hello World".contains!compare("Nope"));
```


## mach.range.distinct


This module implements a `distinct` function, which enumerates only the unique
elements of an input iterable.

Uniqueness is dictated by keys, which must be hashable.
A transformation function for acquiring these keys can optionally be provided
as a template argument; by default the elements are themselves used as the
keys.

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


The `each` function eagerly evaluates a function for every element in
an iterable. The function to be applied is passed as a template argument, and
it must accept a single element from the iterable as its input.
Its lazily-evaluated equivalent is `tap`, defined in `mach.range.tap`.

``` D
string hello = "";
"hello".each!(e => hello ~= e);
assert(hello == "hello");
```


The module also implements an `eachreverse` function, which operates the same
as `each`, except elements are evaluated in reverse order.

``` D
string greetings = "";
"sgniteerg".eachreverse!(e => greetings ~= e);
assert(greetings == "greetings");
```


## mach.range.elementcount


A notable difference between ranges and other iterables in mach is that while
they both indicate the number of elements they contain with the `length`
property, for a partially-consumed range that property no longer represents
the number of elements that should be expected to be handled when, from that
state, enumerating the range. To get the number of elements that enumerating
a range in its present state would result in, the `remaining` property is used.

The `elementcount` function is intended as a way to get the number of elements
that iteration would turn up, e.g. via `foreach`, given the current state of
the input. For ranges the function returns the `remaining` property and for
other types it returns the `length` property.
The function isn't valid for ranges that don't have a numeric `remaining`
property or for other types that don't have a numeric `length`.

``` D
assert("hello".elementcount == 5);
assert([0, 1, 2, 3].elementcount == 4);
```

``` D
import mach.range.rangeof : rangeof;
auto range = rangeof(0, 1, 2, 3);
assert(range.elementcount == 4);
range.popFront();
assert(range.elementcount == 3); // Correct even for partially-consumed ranges.
```


## mach.range.ends


This module implements `head` and `tail` functions, which produce ranges for
enumerating the front or back elements of a range, up to a specified limit.
The length of a range returned by `head` or `tail` is either the limit passed
to the function or the length of its input, whichever is shorter.

The `head` function will work for any input iterable valid as a range.
`tail` will work only for inputs with random access and known numeric length.

``` D
import mach.range.compare : equals;
assert("hello world".head(5).equals("hello"));
assert("hello world".tail(5).equals("world"));
```

``` D
import mach.range.compare : equals;
assert([0, 1, 2].head(10).equals([0, 1, 2]));
```


## mach.range.enumerate


This module implements an `enumerate` function, which returns a range whose
elements are those of its source iterable, wrapped in a type that includes,
in addition to an element of the source iterable, a zero-based index
representing the location of that element within the iterable.

The elements of the range returned by `enumerate` behave like tuples.

``` D
auto array = ["hi", "how", "are", "you"];
foreach(index, element; array.enumerate){
    assert(element == array[index]);
}
```

``` D
auto range = ["zero", "one", "two"].enumerate;
assert(range.front.index == 0);
assert(range.front.value == "zero");
```


When the input iterable is bidirectional, so is the range outputted by
`enumerate`. The range provides `length` and `remaining` properties when
the input does, and propagates infiniteness. It supports random access and
slicing operators when the input iterable supports them, as well as
removal of elements.

The `enumerate` range allows mutation of its front and back elements, as well
as random access writing, using the element type of its input iterable.
They cannot be assigned using the element type of the range itself.

``` D
auto array = [0, 1, 2, 3];
auto range = array.enumerate;
// Values can be reassigned using the element type of the input iterable.
range.front = 10;
assert(range.front.value == 10);
range.back = 20;
assert(range.back.value == 20);
// But not using the element type of the `enumerate` range.
static assert(!is(typeof({
    range.front = range.back;
})));
```


## mach.range.filter


This module implements the
[filter higher-order function](https://en.wikipedia.org/wiki/Filter_(higher-order_function))
for iterable inputs.

The `filter` function produces a range enumerating only those elements of an
input iterable which satisfy its predicate.
The predicate is passed as a template argument, and the input iterable can be
anything that is valid as a range.

The range returned by `filter` supports bidirectionality, saving, removal,
and mutation when the input range supports them. Infiniteness is similarly
propagated.
The range does not provide `length` or `remaining` properties, as the only way
to determine those values in advance is to traverse the outputted sequence.
To acquire these properties, or to get a slice or element at an index, the
`walklength`, `walkindex`, and `walkslice` functions in `mach.range.walk` may
be used.

``` D
import mach.range.compare : equals;
auto range = [0, 1, 2, 3, 4].filter!(n => n % 2 == 0);
assert(range.equals([0, 2, 4]));
```

``` D
import mach.range.compare : equals;
auto range = "h e l l o".filter!(ch => ch != ' ');
assert(range.equals("hello"));
```


## mach.range.first


This module implements `first` and `last` functions for finding the first or
the last element of some iterable meeting a predicate function.
The predicate function is passed as a template argument for `first` and `last`
or, if the argument is omitted, a default function matching any element is
used.
(In this case, the functions simply retrieve the first or last element in the
iterable.)

Note that while `last` will work for any iterable, the implementation is
necessarily inefficient for inputs that are not bidirectional.

``` D
assert([0, 1, 2].first == 0);
assert([0, 1, 2].first!(n => n % 2) == 1);
```

``` D
assert([0, 1, 2].last == 2);
assert([0, 1, 2].last!(n => n % 2) == 1);
```


`first` and `last` can optionally be called with a fallback value to be returned
when no element of the input satisfies the predicate function, or when the
input iterable is empty.

``` D
assert([0, 1, 2].first!(n => n > 10)(-1) == -1);
assert([0, 1, 2].last!(n => n > 10)(-1) == -1);
```

``` D
auto empty = new int[0];
assert(empty.first(1) == 1);
assert(empty.last(1) == 1);
```


If in these cases a fallback is not provided, an error is produced:
`first` throws a `NoFirstElementError` and `last` a `NoLastElementError`.

``` D
import mach.error.mustthrow : mustthrow;
mustthrow!NoFirstElementError({
    [0, 1, 2].first!(n => n > 10); // No elements satisfy the predicate.
});
```


## mach.range.flatten


Where an iterable is an iterable of iterables, the `flatten` function
sequentially enumerates the elements of each iterable within that input
iterable, down to the lowest level of nesting. When the input is an iterable
whose elements are not themselves iterables, `flatten` simply returns its input.

The effect of this is that the elements of an output produced by `flatten` will
never be iterables.

Except for the case where `flatten` returns its input, the function returns
a range, lazily enumerating the flattened contents.

``` D
// Flatten an array of arrays of ints, producing a sequence of ints.
import mach.range.compare : equals;
int[][] array = [[0, 1, 2], [3], [4, 5]];
assert(array.flatten.equals([0, 1, 2, 3, 4, 5]));
```

``` D
// Flatten an array of strings, producing a string.
import mach.range.compare : equals;
assert(["hello", " ", "world"].flatten.equals("hello world"));
```

``` D
// Flatten an array of arrays of arrays of ints, producing a sequence of ints.
import mach.range.compare : equals;
int[][][] array = [[[0, 1], [2]], [[3], [], [4, 5]]];
assert(array.flatten.equals([0, 1, 2, 3, 4, 5]));
```


## mach.range.join


The `join` function accepts an iterable of iterables, then enumerates the
contents of those nested iterables in sequence, interrupting the output
with a separator whenever a nested iterable ends or begins.

The first argument accepted by `join` is the iterable of iterables to be
joined, and the second argument is the separator to insert between its
constituent iterables. The separator may either be an iterable with the
same element type as the iterables in the input iterable, or may be an
element of the type that such an iterable would possess.

`join` is most commonly used to manipulate strings; when using it for this
purpose mind that the outputted iterable is lazily-evaluated, and a function
like `asarray` from `mach.range.asarray` will be needed to create an in-memory
string from the range.

Its complement is `split`, in `mach.range.split`.

``` D
// Join on a separator that is an element of the constituent iterables.
import mach.range.compare : equals;
assert(["hello", "how", "are", "you"].join(' ').equals("hello how are you"));
```

``` D
// Join on a separator that is also an iterable.
import mach.range.compare : equals;
assert(["100", "200", "300"].join("___").equals("100___200___300"));
```


Though the default behavior is to insert the separator only in between
elements, and not at the beginning or the end of the range, the `join`
function accepts optional template arguments which may alter this behavior.

``` D
import mach.range.compare : equals;
// Include the separator at the front of the output.
assert(["abc", "xyz"].join!(true, false)('.').equals(".abc.xyz"));
// Include the separator at the back of the output.
assert(["abc", "xyz"].join!(false, true)('.').equals("abc.xyz."));
// Include the separator at the front and back of the output.
assert(["abc", "xyz"].join!(true, true)('.').equals(".abc.xyz."));
```


## mach.range.logical


This module provides `any`, `all`, and `none` functions which operate based on
whether elements in an input iterable satisfy a predicate.
`any` returns true when at least one element satisfies the predicate.
`all` returns true when no element fails to satisfy the predicate.
`none` returns true when no element satisfies the predicate.

``` D
// Any element is greater than 1?
assert([0, 1, 2, 3].any!(n => n > 1));
// All elements are greater than or equal to 10?
assert([10, 11, 12, 13].all!(n => n >= 10));
// No elements are evenly divisible by 7?
assert([5, 10, 15, 20].none!(n => n % 7 == 0));
```


The predicate can be passed to these functions as a template argument.
When no predicate is passed, the default predicate evaluates truthiness
or falsiness of the elements themselves.

``` D
assert([false, false, true].any);
assert([true, true, true].all);
assert([false, false, false].none);
```


## mach.range.map


This package implements the
(map higher-order function)[https://en.wikipedia.org/wiki/Map_(higher-order_function)]
for input iterables.

The `map` function creates a range for which each element is the result of a
transformation applied to the corresponding elements of the input iterables,
where the transformation function is passed as a template argument.

`map` comes in both singular and plural varieties. Singular `map` represents
the higher-order map function in its common form, where the transformation
operates upon the elements of a single input iterable.

``` D
import mach.range.compare : equals;
auto squares = [1, 2, 3, 4].map!(n => n * n);
assert(squares.equals([1, 4, 9, 16]));
```


Plural `map` is an expansion upon that singular form, in that it accepts
multiple input iterables which are enumerated simultaneously; their
corresponding elements are passed collectively to a transformation function.

The length of a plural `map` function is equal to the length of its shortest
input. If all of the inputs are infinite, then so is the range produced
by `map`.

``` D
import mach.range.compare : equals;
auto intsa = [1, 2, 3, 4];
auto intsb = [3, 5, 7, 9];
// The transformation function must accept the same number of
// elements as there are input iterables, in this case two.
auto sums = map!((a, b) => a + b)(intsa, intsb);
// Output is a sequences of sums of elements of the input.
assert(sums.equals([4, 7, 10, 13]));
```


This plural `map` operation may be more commonly expressed as a combination of
`zip` and singular `map` functions, for example:
`auto sums = zip(intsa, intsb).map!(tup => tup[0] + tup[1]);`

Notably, the `zip` function implemented in `mach.range.zip` is in fact a
very simple abstraction of the plural `map` function.

``` D
import mach.types.tuple : tuple;
// The `zip` function in `mach.range.zip` performs this same operation.
auto zipped = map!tuple([0, 1, 2], [3, 4, 5]);
assert(zipped.front == tuple(0, 3));
```


Neither singular nor plural `map` ranges allow mutation of their elements.

The singular `map` function provides `length` and `remaining` properties when
its input iterable does. The plural `map` function provides these properties
in the case that all inputs either support the corresponding property, or are
of known infinite length.

The singular `map` function supports bidirectionality when its input does.
The plural `map` function supports bidirectionality only when all inputs
are finite, are bidirectional, and have a valid `remaining` property.

Please note that bidirectionality for plural ranges requires a potentially
nontrivial amount of overhead to account for the case where its inputs are
of varying lengths.

``` D
import mach.meta.varreduce : varmax;
auto intsa = [1, 2, 3, 4];
auto intsb = [5, 0, 4, 0, 3, 0];
auto intsc = [3, 2, 1, 1, 2];
auto range = map!varmax(intsa, intsb, intsc);
// Length is that of the shortest input.
assert(range.length == intsa.length);
// Greatest of elements [1, 5, 3]
assert(range.front == 5);
// Greatest of elements [4, 0, 1]
assert(range.back == 4);
```


## mach.range.mutate


The `mutate` function is similar to `map`, but the values produced by the
transformation function are persisted to the underlying data.

Note that in order to acquire elements in the range, the transformation
function is called and its output returned. The element in the
underlying data is only actually mutated upon popping, however.
The range's `nextfront` and `nextback` methods can be called to acquire
and mutate the front or back elements without calling the transformation
twice, which is what will happen when separately calling `range.front`
and `range.popFront`.

The range produced by `mutate` supports `length` and `remaining` when the input
does, and infiniteness is propagated. It supports bidirectionality and random
access when the input does.
The range cannot be saved or sliced, on the basis that such operations are
likely to produce unsafe behavior by calling the transformation function
for and accordingly mutating an element more than once.

``` D
import mach.range.consume : consume;
int[] array = [0, 1, 2, 3];
array.mutate!(n => n + 1).consume;
assert(array == [1, 2, 3, 4]);
```

``` D
int[] array = [5, 6, 7, 8];
auto range = array.mutate!(n => n * 2);
// The array is not actually modified when accessing elements.
assert(range.front == 10);
assert(array[0] == 5);
assert(range.back == 16);
assert(array[$-1] == 8);
assert(range[1] == 12);
assert(array[1] == 6);
// The elements are modified when popping.
range.popFront();
assert(array == [10, 6, 7, 8]);
range.popBack();
assert(array == [10, 6, 7, 16]);
```


## mach.range.next


This module provides, very simply, methods for simultaneously retrieving the
front or back element of a range and popping that element, in the form of
`nextfront` and `nextback`.

The `nextfront` method can additionally be referenced by the name `next`.

``` D
import mach.range.rangeof : rangeof;
auto range = rangeof(0, 1, 2);
assert(range.next == 0);
assert(range.next == 1);
assert(range.next == 2);
assert(range.empty);
```

``` D
import mach.range.rangeof : rangeof;
auto range = rangeof(5, 6, 7);
assert(range.nextback == 7);
assert(range.nextback == 6);
assert(range.nextback == 5);
assert(range.empty);
```


## mach.range.ngrams


The `ngrams` function can be used to generate n-grams given an input iterable.
The length of each n-gram is given as a template argument: Calling `ngrams!2`
enumerates bigrams, `ngrams!3` enumerates trigrams, and so on.

The elements of a range produced by `ngrams` are static arrays containing
a number of elements equal to the count specified using the function's
template argument.

``` D
assert("hello".ngrams!2.equals(["he", "el", "ll" ,"lo"]));
```


One of the more practical uses for this function is to generate n-grams
from a sequence of words.

``` D
import mach.range.split : split;
auto text = "hello how are you";
auto words = text.split(' ');
auto bigrams = words.ngrams!2;
assert(bigrams.equals([["hello", "how"], ["how", "are"], ["are", "you"]]));
```


When the input passed to `ngrams` provides `length` and `remaining` properties,
so does the outputted range. Infiniteness is similarly propagated.
When the input supports random access and slicing operations, so does the output.

``` D
auto range = [0, 1, 2, 3].ngrams!2;
assert(range.length == 3);
assert(range[0] == [0, 1]);
```


## mach.range.pad


This module implements the `pad` function and its derivatives, which produce
a range enumerating the contents of an input iterable, with additional elements
added to its front or back.

The `padfront` and `padback` functions can be used to perform the common
string manipulation of adding elements to the front or back such that the
total length of the output is at most or at minimum a given length.

``` D
import mach.range.compare : equals;
assert("123".padfront('0', 6).equals("000123"));
assert("345".padback('0', 6).equals("345000"));
```


Since these functions generate lazy sequences, functions like string
concatenation will require using a function like `asarray` in order to
create an in-memory array from the padded output.

``` D
import mach.range.asarray : asarray;
auto text = "hello" ~ "world".padfront('_', 7).asarray;
assert(text == "hello__world");
```


The `pad` function provides several overloads for producing an output
which enumerates the input with a given number of elements appended or
prepended to the input.

``` D
// Pad with two underscores at the front and the back.
assert("hi".pad('_', 2).equals("__hi__"));
// Pad with one underscore at the front and three at the back.
assert("yo".pad('_', 1, 3).equals("_yo___"));
// Pad with two underscores at the front and three bangs at the back.
assert("bro".pad('_', 2, '!', 3).equals("__bro!!!"));
```


## mach.range.pluck


This module implements `pluck`, which is a simple abstraction of the `map`
function in `mach.range.map`.
`pluck` can be called with a template argument indicating a property to be
extracted from each element of an input iterable, or with runtime arguments
used to index the elements of the input iterable.

``` D
import mach.range.compare : equals;
struct Test{int x; int y; int z;}
// Equivalent to `input.map!(e => e.x)`.
auto range = [Test(0, 1, 2), Test(2, 3, 4)].pluck!`x`;
assert(range.equals([0, 2]));
```

``` D
import mach.range.compare : equals;
string[] array = ["abc", "xyz", "123"];
// Equivalent to `input.map!(e => e[0])`.
assert(array.pluck(0).equals("ax1"));
```


## mach.range.recur


The `recur` function can be used to generate a range from repeatedly applying
a function to its input, either infinitely or until the output satisfies a
predicate. When such a predicate is provided, `recur` allows specifying whether
that final, matching element should be included in the outputted range via
a template argument. Alternately, the `recuri` function can be used when the
matching element should be included in the output.

``` D
import mach.range.compareends : headis;
auto range = 0.recur!(n => n + 1); // Repeatedly increment, starting at 0.
assert(range.headis([0, 1, 2, 3, 4, 5]));
```

``` D
import mach.range.compare : equals;
// Repeat until 4.
auto exclusive = 0.recur!(n => n + 1, n => n >= 4);
assert(exclusive.equals([0, 1, 2, 3]));
// Repeat until and including 4.
auto inclusive = 0.recuri!(n => n + 1, n => n >= 4);
assert(inclusive.equals([0, 1, 2, 3, 4]));
```


## mach.range.reduce


This module implements the
[reduce higher-order function](https://en.wikipedia.org/wiki/Fold_(higher-order_function))
for iterable inputs.

The `reduce` function accepts an accumulation function as its template argument,
and applies that function sequentially to the elements of an input iterable.
The function optionally accepts a seed, which sets the initial value of the
accumulator.
This module implements both `lazyreduce` and `eagerreduce`; the `reduce` symbol
aliases `eagerreduce` because it is by far the more common application of the
function.

An accumulation function must accept two arguments. The first is an accumulator,
which is either explicitly seeded or taken from the first element of the input.
The first is an element from the input. The function must return a new value
for the accumulator. The `reduce` function operates by repeatedly applying this
function, sequentially updating the accumulator value with the elements of the
input.

For example, a `sum` function can be implemented using `reduce`.

``` D
alias sum = (acc, next) => (acc + next);
assert([1, 2, 3, 4].reduce!sum(10) == 20); // With seed
```

``` D
alias sum = (acc, next) => (acc + next);
assert([5, 6, 7].reduce!sum == 18); // No seed
```


Both lazy and eager `reduce` functions will produce an error if the function
is not seeded with an initial value, and the input is empty.
In this case a `ReduceEmptyError` is thrown, except for code compiled in
release mode, for which this check is ommitted.

``` D
import mach.error.mustthrow : mustthrow;
alias sum = (acc, next) => (acc + next);
mustthrow!ReduceEmptyError({
    new int[0].reduceeager!sum;
});
mustthrow!ReduceEmptyError({
    new int[0].reducelazy!sum;
});
```


## mach.range.repeat


The `repeat` function can be used to repeat an inputted iterable either
infinitely or a specified number of times, depending on whether a limit is
passed to it.

In order for an iterable to repeated either finitely or infinitely, it must be
infinite, have random access and length, or be valid as a saving range.
Repeating an already-infinite iterable returns the selfsame iterable,
regardless of whether the repeating was intended to be finite or infinite.

When `repeat` is called for an iterable without any additional arguments,
that iterable is repeated infinitely.

``` D
import mach.range.compareends : headis;
auto range = "hi".repeat;
assert(range.headis("hihihihihi"));
```

``` D
// Fun fact: Infinitely repeated ranges are technically bidirectional.
assert("NICE".repeat.back == 'E');
```


When the function is called with an additional integer argument, that argument
dictates how many times the input will be repeated before the resulting range
is exhausted.

Finitely repeated ranges support `length` and `remaining` properties when their
inputs support them. They allow random access when the input has random access
and numeric length. All finitely and infinitely repeated ranges allow saving.

``` D
import mach.range.compare : equals;
auto range = "yo".repeat(3);
assert(range.equals("yoyoyo"));
```


The `repeat` function does not support infinitely repeating an empty iterable,
because attempting to do so would invalidate many of the compile-time checks
made possible by assuming the result of infinitely repeating an input is in
fact an infinite range.
An `InfiniteRepeatEmptyError` is thrown when this operation is attempted,
unless the code has been compiled in release mode, in which case the check is
omitted and a nastier error may occur instead.

``` D
import mach.error.mustthrow : mustthrow;
mustthrow!InfiniteRepeatEmptyError({
    "".repeat; // Can't infinitely repeat an empty input.
});
```


## mach.range.retro


The `retro` function returns a range which enumerates the elements of its input
in reverse order. Its input must be an iterable valid as a bidirectional range.

When the input iterable provides `length` and `remaining` properties, so does
the output of `retro`. Infiniteness is similarly propagated. Saving, slicing,
random access reading and writing, front and back mutability, and element
removal are supported when the inputted iterable supports them.

``` D
import mach.range.compare : equals;
assert("hello".retro.equals("olleh"));
```


## mach.range.split


The `split` returns a range enumerating portions of an input iterable as
delimited by a separator, where the separator can either be an element,
an element predicate, or a substring.
It is a complement to the `join` function in `mach.range.join`.

`split` is most commonly useful as a string manipulation function; note that
when using it this way, because its output is a range, a function such as
`asarray` in `mach.range.asarray` may be required so that the range's contents
can be placed into an in-memory array.

``` D
import mach.range.compare : equals;
// Split on occurrences of an element.
assert("hello world".split(' ').equals(["hello", "world"]));
// Split on elements meeting a predicate.
assert("1.2,3.4".split!(ch => ch == '.' || ch == ',').equals(["1", "2", "3", "4"]));
```

``` D
// Split on occurrences of a substring.
import mach.range.compare : equals;
assert("1, 2, 3".split(", ").equals(["1", "2", "3"]));
```

``` D
// Split on occurrences of a substring, given a comparison function.
import mach.range.compare : equals;
import mach.text.ascii : tolower;
// Case-insensitive character comparison
alias compare = (a, b) => (a.tolower == b.tolower);
assert("123and456AND789".split!compare("and").equals(["123", "456", "789"]));
```


## mach.range.tap


The `tap` function lazily applies a callback function to each element in an
input iterable. It accepts an input iterable valid as a range for its single
runtime argument, and it accepts a template argument representing the function
to apply to the input's elements as the range is consumed.

When the input is bidirectional, so is the range produced by `tap`.
It provides `length` and `remaining` properties when the input does,
and propagates infiniteness.
It supports random access and slicing operations when the input does.

The outputted range applies the callback upon each element being popped,
not upon access or assignment.
If the range's elements are removed, then those elements are consumed without
the callback being applied to them.

For an eagerly-evaluated analog to `tap`, see `each` in `mach.range.each`.

``` D
import mach.range.consume : consume;
string hello;
auto range = "hello".tap!((ch){hello ~= ch;});
range.consume;
assert(hello == "hello");
```

``` D
int[] array;
// Produce a range which appends to `array` as elements are consumed.
auto range = [1, 2, 3, 4].tap!((n){array ~= n;});
assert(range.front == 1);
assert(array.length == 0);
range.popFront(); // The callback is applied upon popping.
assert(array == [1]);
while(!range.empty) range.popFront();
assert(array == [1, 2, 3, 4]);
```

``` D
import mach.collect : DoublyLinkedList;
// The callback appends elements to this array.
int[] array;
// Use a range produced from a list because it supports removal of elements.
auto list = new DoublyLinkedList!int([1, 2, 3, 4]);
auto range = list.values.tap!((n){array ~= n;});
// The callback is applied to the front value upon popping it.
range.popFront();
assert(array == [1]);
// And the callback is applied to the back value upon popping it.
range.popBack();
assert(array == [1, 4]);
// When assigning elements, the callback is applied to the new value.
range.front = 10;
range.popFront();
assert(array == [1, 4, 10]);
// When removing elements, the callback is not applied.
range.removeFront();
assert(array == [1, 4, 10]);
```


## mach.range.zip


The `zip` function accepts any number of input iterables as variadic arguments
and from them produces a range of tuples, where each tuple represents the
corresponding elements in those iterables.

The length of a range returned by `zip` is equal to the length of its shortest
input.

`zip` is a very simple abstraction of the plural `map` function defined
in `mach.range.map`; see its documentation for more detailed information
regarding the range that is returned.

``` D
import mach.types : tuple;
auto range = zip("apple", "bear", "car", "dumpling");
assert(range.front == tuple('a', 'b', 'c', 'd'));
assert(range.length == 3); // Length is that of the shortest input, "car".
```

``` D
auto range = zip([0, 1, 2, 3], [0, 2, 4, 6]);
foreach(first, second; range){
    assert(first * 2 == second);
}
```


