# mach.traits


This module provides a variety of templates which primarily regard
the inspection of types.


## mach.traits.array


The `isArray` template may be used to determine whether an input type is a
static or dynamic array.

``` D
static assert(isArray!(int[4]));
static assert(isArray!(string));
static assert(!isArray!(float));
```


The `isArrayOf` template evaluates true when an input type is an array of
elements of a given type.

``` D
static assert(isArrayOf!(int, int[4]));
static assert(isArrayOf!(immutable char, string));
static assert(!isArrayOf!(int, float[]));
```


The `isStaticArray` and `isDynamicArray` templates may be used to determine
whether a type is a statically-sized or dynamic array, respectively.

``` D
static assert(isStaticArray!(int[4]));
static assert(isDynamicArray!(string));
```


## mach.traits.classes


The `isClass` template can be used to determine whether some type is implemented
as a class, as opposed to being a struct or a primitive.

``` D
static assert(isClass!(Object));
static assert(!isClass!(int));
```


## mach.traits.common


This module provides the `CommonType` and `hasCommonType` templates.
These can be used to find the common implicit type among multiple
potentially different types, and whether such a common type exists.

When the input types do not have any common type, the `CommonType`
template will produce the `void` type as output.

``` D
static assert(hasCommonType!(ubyte, uint, ulong));
static assert(is(CommonType!(ubyte, uint, ulong) == ulong));
```

``` D
static assert(!hasCommonType!(int, int[]));
static assert(is(CommonType!(int, int[]) == void));
```


## mach.traits.pointer


The `PointerType` template accepts a pointer type as input and aliases to
the type that the pointer refers to.

It also provides an overload of the `isPointer` template which can be used
to determine whether a pointer refers to a type satisfying some predicate
template.

``` D
static assert(is(PointerType!(int*) == int));
static assert(is(PointerType!(string**) == string*));
```

``` D
import mach.traits.primitives : isIntegral, isFloatingPoint;
static assert(isPointer!(isIntegral, int*));
static assert(isPointer!(isFloatingPoint, float*));
```


## mach.traits.primitivesizes


This module implements the `LargerType`, `SmallerType`, `LargestType`, and
`SmallestType` templates.
They can be used to get differently-sized primitives of the same type,
where the type is unsigned or signed integer, character, float, or imaginary or
complex number.

``` D
static assert(is(LargestType!char == dchar));
static assert(is(LargestType!float == real));
static assert(is(SmallestType!wchar == char));
static assert(is(SmallestType!real == float));
```

``` D
static assert(is(LargerType!int == long));
static assert(is(LargerType!char == wchar));
static assert(is(SmallerType!int == short));
static assert(is(SmallerType!wchar == char));
```

``` D
static assert(!is(LargerType!dchar)); // Fails because there is no larger type!
static assert(!is(SmallerType!ubyte)); // Fails because there is no smaller type!
```


The `LargestTypeOf` and `SmallestTypeOf` templates accept any number of types as
template arguments, and evaluate to the largest/smallest type provided, as
judged by comparisons of `sizeof`.
When multiple inputs have the same size, the output is that input which appears
earliest in the sequence of inputs.

``` D
static assert(is(LargestTypeOf!(int, short, byte) == int));
static assert(is(SmallestTypeOf!(int, short, byte) == byte));
```


## mach.traits.qualifiers


This module implements the `Unqual`, `isUnqual`, and `Qualify` templates for
manipulating the qualifiers `immutable`, `shared`, `inout`, and `const` that
may be associated with types.

The `Unqual` template aliases an inputted type with all of its qualifiers
stripped.

``` D
static assert(is(Unqual!(const int) == int));
static assert(is(Unqual!(shared inout int) == int));
static assert(is(Unqual!(int) == int));
```


The `isUnqual` template compares two or more types for equality, regardless
of differing qualifiers.

``` D
static assert(isUnqual!(const int, immutable int));
static assert(isUnqual!(string, shared string));
static assert(!isUnqual!(float, double));
```


The `Qualify` template takes two types and outputs the second type with
the same qualifiers as the first type.

``` D
static assert(is(Qualify!(const int, string) == const string));
static assert(is(Qualify!(shared inout int, string) == shared inout string));
static assert(is(Qualify!(shared int, immutable string) == shared string));
static assert(is(Qualify!(int, shared const string) == string));
```


