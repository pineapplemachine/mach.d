module mach.io.stream.templates;

private:

/++ Docs

This module provides templates which can be used to determine whether a type is
a stream and, if so, what operations it supports.

`isStream` is true when either `isInputStream` or `isOutputStream` is true,
or both.

`isInputStream` is true when the type implements at least `eof` and `readbufferv`.
It indicates whether a type represents a stream which can be read from.

`isOutputStream` is true when the type implements at least `eof` and `writebufferb`.
It indicates whether a type represents a stream which can be written to.

`isIOStream` is true when the type is both an input and an output stream,
implying it at least implements `eof`, `readbufferv`, and `writebufferv`.

`isSeekStream` and `isTellStream` templates determine whether a type is a stream
where position can be set and accessed, respectively, via the type's `position`
property.

`isClosingStream` determines whether `close` is a valid operation for a stream
type. Closing streams should always be closed when they're no longer in use.

`isInfiniteInputStream` and `isFiniteInputStream` can be used to determine
whether a type is an input stream and whether it has a finite or an infinite
amount of data available to be read.
Finiteness is determined by whether the type has an `eof` property known at
compile-time to be `false`, in the same way that a range type where
`enum empty = false;` indicates an infinite range.

+/

public:



/// Determine whether a type represents a stream which can be read from.
/// Requires that the type implement `readbufferv` and `eof`.
enum bool isInputStream(T) = is(typeof({
    auto x = T.init;
    size_t count = x.readbufferv(cast(void*) null, 0, 0);
    bool eof = x.eof;
}));

/// Determine whether a type represents a stream which can be written to.
/// Requires that the type implement `writebufferv` and `eof`.
enum bool isOutputStream(T) = is(typeof({
    auto x = T.init;
    size_t count = x.writebufferv(cast(void*) null, 0, 0);
    bool eof = x.eof;
}));

/// Determine whether a type represents a stream which can be either read from
/// or written to.
enum bool isStream(T) = (
    isInputStream!T || isOutputStream!T
);

/// Determine whether a type represents a stream which can be both read from
/// and written to.
enum bool isIOStream(T) = (
    isInputStream!T && isOutputStream!T
);



/// Determine whether a type is a stream which supports seeking via setting a
/// position property.
enum bool isSeekStream(T) = isStream!T && is(typeof({
    size_t i = 0; T.init.position = i;
}));

/// Determine whether a type is a stream which provides a readable position
/// property, which must be explicitly castable to size_t.
enum bool isTellStream(T) = isStream!T && is(typeof({
    size_t pos = cast(size_t) T.init.position;
}));



/// Determine whether the stream is infinite, i.e. that eof is never reached.
enum bool isInfiniteInputStream(T) = isInputStream!T && is(typeof({
    enum bool eof = T.init.eof;
    static assert(eof is false);
}));

enum bool isFiniteInputStream(T) = (
    isInputStream!T && !isInfiniteInputStream!T
);



/// Determine whether the stream should be closed when it's no longer needed.
enum bool isClosingStream(T) = isStream!T && is(typeof({
    T.init.close;
}));



version(unittest){
    struct IStream{
        static enum bool eof = false;
        size_t readbufferv(void* buffer, size_t size, size_t count){return 0;}
    }
    struct OStream{
        static enum bool eof = false;
        size_t writebufferv(void* buffer, size_t size, size_t count){return 0;}
    }
    struct IOStream{
        static enum bool eof = false;
        size_t readbufferv(void* buffer, size_t size, size_t count){return 0;}
        size_t writebufferv(void* buffer, size_t size, size_t count){return 0;}
    }
}
unittest{
    static assert(isInputStream!IStream);
    static assert(isInputStream!IOStream);
    static assert(!isInputStream!OStream);
    static assert(!isInputStream!int);
    static assert(!isInputStream!void);
    static assert(isOutputStream!OStream);
    static assert(isOutputStream!IOStream);
    static assert(!isOutputStream!IStream);
    static assert(!isOutputStream!int);
    static assert(!isOutputStream!void);
    static assert(isStream!IStream);
    static assert(isStream!OStream);
    static assert(isStream!IOStream);
    static assert(!isStream!int);
    static assert(!isStream!void);
    static assert(isIOStream!IOStream);
    static assert(!isIOStream!IStream);
    static assert(!isIOStream!OStream);
    static assert(!isIOStream!int);
    static assert(!isIOStream!void);
}
