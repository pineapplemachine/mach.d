module mach.traits.string;

private:

import mach.traits.element : ElementType, canGetElementType, hasElementType;
import mach.traits.index : canIndex, IndexType;
import mach.traits.iter : isIterable;
import mach.traits.range : isRange;
import mach.traits.qualifiers : Unqual, isUnqual;

public:



/// Get whether a type is an iterable of chars, dchars, or wchars.
template isString(T){
    enum bool isString = isCharString!T || isWString!T || isDString!T;
}
/// Get whether a type is an iterable of chars.
template isCharString(T){
    static if(isIterable!T && canGetElementType!T){
        enum bool isCharString = isUnqual!(ElementType!T, char);
    }else{
        enum bool isCharString = false;
    }
}
/// Get whether a type is an iterable of wchars.
template isWString(T){
    static if(isIterable!T && canGetElementType!T){
        enum bool isWString = isUnqual!(ElementType!T, wchar);
    }else{
        enum bool isWString = false;
    }
}
/// Get whether a type is an iterable of dchars.
template isDString(T){
    static if(isIterable!T && canGetElementType!T){
        enum bool isDString = isUnqual!(ElementType!T, dchar);
    }else{
        enum bool isDString = false;
    }
}



/// Get whether a type an iterable with element implicitly convertible to
/// chars, wchars, or dchars.
template isStringLike(T){
    enum bool isStringLike = isCharStringLike!T || isWStringLike!T || isDStringLike!T;
}
/// Get whether a type an iterable with element implicitly convertible to chars.
template isCharStringLike(T){
    enum bool isCharStringLike = isIterable!T && hasElementType!(char, T);
}
/// Get whether a type an iterable with element implicitly convertible to wchars.
/// Note that an iterable of chars is also valid as an iterable of wchars.
template isWStringLike(T){
    enum bool isWStringLike = isIterable!T && hasElementType!(wchar, T);
}
/// Get whether a type an iterable with element implicitly convertible to dchars.
/// Note that an iterable of chars or wchars is also valid as an iterable of dchars.
template isDStringLike(T){
    enum bool isDStringLike = isIterable!T && hasElementType!(dchar, T);
}



/// Get whether a type is an iterable valid as a range of chars, dchars, or wchars.
template validAsStringRange(T){
    import mach.range.asrange : validAsRange;
    enum bool validAsStringRange = isString!T && validAsRange!T;
}

/// Get whether a type is an iterable valid as a range of elements valid as
/// chars, dchars, or wchars.
template validAsStringRangeLike(T){
    import mach.range.asrange : validAsRange;
    enum bool validAsStringRangeLike = isStringLike!T && validAsRange!T;
}



/// Get whether a type is an iterable valid as a range of chars, dchars, or wchars.
template isStringRange(T){
    enum bool isStringRange = isString!T && isRange!T;
}

/// Get whether a type is an iterable valid as a range of elements valid as
/// chars, dchars, or wchars.
template isStringRangeLike(T){
    enum bool isStringRange = isStringLike!T && isRange!T;
}



/// Get whether a type is a random-access iterable of chars, dchars, or
/// wchars.
template isRandomAccessString(T){
    enum bool isRandomAccessString = (
        isString!T && canIndex!(T, size_t)
    );
}
/// Get whether a type is a random-access iterable of chars.
template isRandomAccessCharString(T){
    enum bool isRandomAccessCharString = (
        isCharString!T && canIndex!(T, size_t)
    );
}
/// Get whether a type is a random-access iterable of dchars.
template isRandomAccessDString(T){
    enum bool isRandomAccessDCharString = (
        isDString!T && canIndex!(T, size_t)
    );
}
/// Get whether a type is a random-access iterable of wchars.
template isRandomAccessWString(T){
    enum bool isRandomAccessWCharString = (
        isWString!T && canIndex!(T, size_t)
    );
}



/// Get whether a type is valid as a random-access iterable of chars, dchars, or
/// wchars.
template isRandomAccessStringLike(T){
    enum bool isRandomAccessStringLike = (
        isStringLike!T && canIndex!(T, size_t)
    );
}
/// Get whether a type is valid as a random-access iterable of chars.
template isRandomAccessCharStringLike(T){
    enum bool isRandomAccessCharStringLike = (
        isCharStringLike!T && canIndex!(T, size_t)
    );
}
/// Get whether a type is valid as a random-access iterable of dchars.
template isRandomAccessDStringLike(T){
    enum bool isRandomAccessDStringLike = (
        isDStringLike!T && canIndex!(T, size_t)
    );
}
/// Get whether a type is valid as a random-access iterable of wchars.
template isRandomAccessWStringLike(T){
    enum bool isRandomAccessWStringLike = (
        isWStringLike!T && canIndex!(T, size_t)
    );
}



version(unittest){
    private:
    import mach.meta.aliases : Aliases;
    template CharRangeTemplate(T){
        struct CharRangeTemplate{
            enum bool empty = false;
            @property T front(){return 'x';}
            void popFront(){}
        }
    }
    alias CharRange = CharRangeTemplate!char;
    alias DCharRange = CharRangeTemplate!dchar;
    alias WCharRange = CharRangeTemplate!wchar;
}
unittest{
    foreach(tmpl; Aliases!(isCharString, isCharStringLike)){
        static assert(tmpl!(string));
        static assert(tmpl!(char[]));
        static assert(tmpl!(char[10]));
        static assert(tmpl!(CharRange));
        static assert(!tmpl!(dstring));
        static assert(!tmpl!(wstring));
        static assert(!tmpl!(double[]));
        static assert(!tmpl!(int));
    }
    {
        static assert(!isCharString!(ubyte[4]));
        static assert(!isCharString!(ubyte[]));
        static assert(isCharStringLike!(ubyte[4]));
        static assert(isCharStringLike!(ubyte[]));
    }
}
unittest{
    foreach(tmpl; Aliases!(isWString, isWStringLike)){
        static assert(tmpl!(wstring));
        static assert(tmpl!(wchar[]));
        static assert(tmpl!(wchar[10]));
        static assert(tmpl!(WCharRange));
        static assert(!tmpl!(dstring));
        static assert(!tmpl!(double[]));
        static assert(!tmpl!(int));
    }
    {
        static assert(!isWString!(char[4]));
        static assert(!isWString!(char[]));
        static assert(!isWString!(CharRange));
        static assert(isWStringLike!(char[4]));
        static assert(isWStringLike!(char[]));
        static assert(isWStringLike!(CharRange));
    }
}
unittest{
    foreach(tmpl; Aliases!(isDString, isDStringLike)){
        static assert(isDString!(dstring));
        static assert(isString!(dchar[]));
        static assert(isString!(dchar[10]));
        static assert(isDString!(DCharRange));
        static assert(!isDString!(double[]));
        static assert(!isDString!(int));
    }
    {
        static assert(!isDString!(string));
        static assert(!isDString!(wstring));
        static assert(isDStringLike!(string));
        static assert(isDStringLike!(wstring));
    }
}
unittest{
    foreach(tmpl; Aliases!(isString, isStringLike)){
        static assert(tmpl!(string));
        static assert(tmpl!(dstring));
        static assert(tmpl!(wstring));
        static assert(tmpl!(char[]));
        static assert(tmpl!(dchar[]));
        static assert(tmpl!(wchar[]));
        static assert(tmpl!(char[4]));
        static assert(tmpl!(dchar[4]));
        static assert(tmpl!(wchar[4]));
        static assert(tmpl!(CharRange));
        static assert(tmpl!(DCharRange));
        static assert(tmpl!(WCharRange));
        static assert(!tmpl!(char));
        static assert(!tmpl!(int));
        static assert(!tmpl!(double[]));
        static assert(!tmpl!(ulong[]));
        static assert(!tmpl!(void));
    }
    {
        static assert(!isString!(ubyte[4]));
        static assert(!isString!(ubyte[]));
        static assert(!isString!(ushort[]));
        static assert(!isString!(uint[]));
        static assert(isStringLike!(ubyte[4]));
        static assert(isStringLike!(ubyte[]));
        static assert(isStringLike!(ushort[]));
        static assert(isStringLike!(uint[]));
    }
}
unittest{
    foreach(tmpl; Aliases!(isRandomAccessString, isRandomAccessStringLike)){
        static assert(tmpl!(string));
        static assert(tmpl!(dstring));
        static assert(tmpl!(wstring));
        static assert(!tmpl!(CharRange));
        static assert(!tmpl!(DCharRange));
        static assert(!tmpl!(WCharRange));
        static assert(!tmpl!(char));
        static assert(!tmpl!(int));
        static assert(!tmpl!(void));
    }
    {
        static assert(!isRandomAccessString!(uint[4]));
        static assert(!isRandomAccessString!(uint[]));
        static assert(isRandomAccessStringLike!(uint[4]));
        static assert(isRandomAccessStringLike!(uint[]));
    }
}
