module mach.traits.string;

private:

import std.traits : Unqual;
import mach.traits.element : hasUnqualElementType;
import mach.traits.index : canIndex, IndexType;
import mach.traits.iter : isIterable;

public:



/// Get whether a type is valid as an iterable of chars, dchars, or wchars.
template isString(T...) if(T.length == 1){
    enum bool isString = isCharString!T || isDCharString!T || isWCharString!T;
}

/// /// Get whether a type is valid as an iterable of chars.
template isCharString(T...) if(T.length == 1){
    enum bool isCharString = isIterable!T && hasUnqualElementType!(char, T);
}
/// /// Get whether a type is valid as an iterable of dchars.
template isDCharString(T...) if(T.length == 1){
    enum bool isDCharString = isIterable!T && hasUnqualElementType!(dchar, T);
}
/// Get whether a type is valid as an iterable of wchars.
template isWCharString(T...) if(T.length == 1){
    enum bool isWCharString = isIterable!T && hasUnqualElementType!(wchar, T);
}



/// Get whether a type is an iterable valid as a range of chars, dchars, or wchars.
template isStringRange(T...) if(T.length == 1){
    import mach.range.asrange : validAsRange;
    enum bool isStringRange = isString!T && validAsRange!T;
}



/// Get whether a type is valid as a random-access iterable of chars, dchars, or
/// wchars.
template isRandomAccessString(T...) if(T.length == 1){
    static if(isString!T && canIndex!(T, size_t)){
        alias X = Unqual!(IndexType!(T, size_t));
        enum bool isRandomAccessString = (
            is(X == char) || is(X == dchar) || is(X == wchar)
        );
    }else{
        enum bool isRandomAccessString = false;
    }
}

/// Get whether a type is valid as a random-access iterable of chars.
template isRandomAccessCharString(T...) if(T.length == 1){
    static if(isCharString!T && canIndex!(T[0], size_t)){
        enum bool isRandomAccessCharString = is(Unqual!(IndexType!(T[0], size_t)) == char);
    }else{
        enum bool isRandomAccessCharString = false;
    }
}
/// Get whether a type is valid as a random-access iterable of dchars.
template isRandomAccessDCharString(T...) if(T.length == 1){
    static if(isDCharString!T && canIndex!(T[0], size_t)){
        enum bool isRandomAccessDCharString = is(Unqual!(IndexType!(T[0], size_t)) == dchar);
    }else{
        enum bool isRandomAccessDCharString = false;
    }
}
/// Get whether a type is valid as a random-access iterable of wchars.
template isRandomAccessWCharString(T...) if(T.length == 1){
    static if(isWCharString!T && canIndex!(T[0], size_t)){
        enum bool isRandomAccessWCharString = is(Unqual!(IndexType!(T[0], size_t)) == wchar);
    }else{
        enum bool isRandomAccessWCharString = false;
    }
}



version(unittest){
    private:
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
    static assert(isCharString!("hi"));
    static assert(isCharString!(string));
    static assert(isString!(char[]));
    static assert(isString!(char[10]));
    static assert(isCharString!(CharRange));
    static assert(!isCharString!(dstring));
    static assert(!isCharString!(wstring));
    static assert(!isCharString!(int[]));
    static assert(!isCharString!(int));
}
unittest{
    static assert(isDCharString!("hi"d));
    static assert(isDCharString!(dstring));
    static assert(isString!(dchar[]));
    static assert(isString!(dchar[10]));
    static assert(isDCharString!(DCharRange));
    static assert(!isDCharString!(string));
    static assert(!isDCharString!(wstring));
    static assert(!isDCharString!(int[]));
    static assert(!isDCharString!(int));
}
unittest{
    static assert(isWCharString!("hi"w));
    static assert(isWCharString!(wstring));
    static assert(isString!(wchar[]));
    static assert(isString!(wchar[10]));
    static assert(isWCharString!(WCharRange));
    static assert(!isWCharString!(string));
    static assert(!isWCharString!(dstring));
    static assert(!isWCharString!(int[]));
    static assert(!isWCharString!(int));
}
unittest{
    static assert(isString!("hi"));
    static assert(isString!("hi"d));
    static assert(isString!("hi"w));
    static assert(isString!(string));
    static assert(isString!(dstring));
    static assert(isString!(wstring));
    static assert(isString!(char[]));
    static assert(isString!(dchar[]));
    static assert(isString!(wchar[]));
    static assert(isString!(CharRange));
    static assert(isString!(DCharRange));
    static assert(isString!(WCharRange));
    static assert(!isString!(char));
    static assert(!isString!(int));
    static assert(!isString!(int[]));
    static assert(!isString!(void));
}
unittest{
    static assert(isRandomAccessString!("hi"));
    static assert(isRandomAccessString!("hi"d));
    static assert(isRandomAccessString!("hi"w));
    static assert(isRandomAccessString!(string));
    static assert(isRandomAccessString!(dstring));
    static assert(isRandomAccessString!(wstring));
    static assert(!isRandomAccessString!(CharRange));
    static assert(!isRandomAccessString!(DCharRange));
    static assert(!isRandomAccessString!(WCharRange));
    static assert(!isRandomAccessString!(char));
    static assert(!isRandomAccessString!(int));
    static assert(!isRandomAccessString!(int[]));
    static assert(!isRandomAccessString!(void));
}
