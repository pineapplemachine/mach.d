# mach.io.stream

This package contains functionality for stream IO, incuding file and stdio streams.

## Stream types

An input stream is one which implements at minimum `readbufferv` and `eof`.
An output stream is one which implements at minimum `writebufferv` and `eof`.

For example, `FileStream` implements these methods like so:

``` D
struct StdInStream{
    size_t readbufferv(void* buffer, size_t size, size_t count){
        return fread(buffer, size, count, this.target);
    }
    size_t writebufferv(void* buffer, size_t size, size_t count){
        return fwrite(buffer, size, count, this.target);
    }
    @property bool eof() in{assert(this.active);} body{
        return cast(bool) feof(this.target);
    }
}
```

Other standard methods and properties include:

- `length` for getting the total number of bytes in the stream.
- `remaining` for getting the number of bytes yet to be read from the stream before eof.
- `position` implemented as a property for getting and/or setting the current position in the stream.
- `reset` for rewinding to the beginning of the stream.
- `close` for closing a stream when it's no longer needed.
- `active` for determining whether a stream that can be closed is currently open.
- `flush` for flushing uncommitted changes to an underlying buffer.

## Modules

Here's a brief description of what purpose each module serves.

### Stream types

#### mach.io.stream.filestream

Defines a stream type for reading or writing files.

#### mach.io.stream.stdiostream

Defines stream types for reading stdin and writing to stdout and stderr.

### Working with streams

#### mach.io.stream.asarray

Defines `asarray` for stream types.

#### mach.io.stream.asrange

Defines `asrange` for stream types.

#### mach.io.stream.exceptions

Defines exceptions for failed stream operations.

#### mach.io.stream.io

The only IO methods streams need to implement are `readbufferv` in the case of
input streams and `writebufferv` in the case of output streams, which accept
a `void*` pointer, a unit size, and a unit count. This module defines the sorts
of abstractions you might need to work with these methods in a less messy
capacity.

#### mach.io.stream.templates

Defines templates that can be used to determine whether a type is a stream and,
if so, what sort of stream it is and what operations it supports.
