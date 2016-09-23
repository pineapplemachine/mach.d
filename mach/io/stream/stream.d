module mach.io.stream.stream;

private:

import mach.traits : isArray, isIterable;
import mach.error : ThrowableMixin;

public:
    


class StreamException: Exception{
    mixin ThrowableMixin!`Failure performing stream operation.`;
}
class StreamReadException: StreamException{
    mixin ThrowableMixin!`Failure reading from stream.`;
}
class StreamWriteException: StreamException{
    mixin ThrowableMixin!`Failure writing to stream.`;
}



enum bool isStream(T) = is(T: Stream);
enum bool isInputStream(T) = is(T: InputStream);
enum bool isOutputStream(T) = is(T: OutputStream);
enum bool isIOStream(T) = isInputStream!T && isOutputStream!T;



/// Convenience mixin for stream interfaces.
static string StreamSupportMixin(string[] supported...){
    import std.string : join;
    import std.algorithm : map, canFind;
    static immutable string[] SUPPORT_OPTIONS = [
        "haseof", "haslength", "hasposition", "canseek", "canreset"
    ];
    return join(
        map!((support) => ("static enum bool " ~ support ~ " = " ~ (
            supported.canFind(support) ? "true" : "false"
        ) ~ ";"))(SUPPORT_OPTIONS)
    );
}

/// A common streaming interface for interacting with different forms of storage.
interface Stream{
    /// Is eof a meaningful operation for this stream?
    static bool haseof = false;
    /// Get whether the end of the stream has been reached.
    @property bool eof();
    
    /// Is length a meaningful property for this stream?
    static bool haslength = false;
    /// Get the length of this stream.
    @property size_t length();
    
    /// Is position a meaningful property for this stream?
    static bool hasposition = false;
    /// Get the current position in the stream.
    @property size_t position();
    
    /// Is seeking a meaningful operation for this stream?
    static bool canseek = false;
    /// Set the current position in the stream.
    @property void position(in size_t index);
    
    /// Is resetting a meaningful operation for this stream?
    static bool canreset = false;
    /// Reset the position in the stream to its beginning.
    void reset();
    
    /// Is the stream currently active, e.g. does it have a valid target?
    @property bool active();
    /// Close the stream, after which the stream object becomes inactive.
    void close();
    
    final bool opCast(T: bool)(){
        return this.active & !(this.haseof && this.eof);
    }
}

/// A stream which can be read from.
interface InputStream : Stream{
    void flush();
    size_t readbufferraw(void* buffer, size_t size, size_t count);
    final size_t readbuffer(T)(T* buffer, size_t count = 1){
        return this.readbufferraw(buffer, T.sizeof, count);
    }
    final size_t readbuffer(T)(T[] buffer){
        return this.readbuffer!T(buffer.ptr, buffer.length);
    }
    /// Read a single value of an arbitrary type. Not an especially meaningful
    /// operation for anything other than primitives and structs.
    final T read(T)(){
        T value;
        auto result = this.readbuffer!T(&value, 1);
        if(result != T.sizeof) throw new StreamReadException();
        return value;
    }
    /// ditto
    final T[] read(T)(size_t count){
        T[] values;
        values.reserve(count);
        foreach(size_t i; 0 .. count) values ~= this.read!T;
        return values;
    }
}
/// A stream which can be written to.
interface OutputStream : Stream{
    void sync();
    size_t writebufferraw(void* buffer, size_t size, size_t count);
    final size_t writebuffer(T)(in T* buffer, size_t count = 1){
        return this.writebufferraw(cast(void*) buffer, T.sizeof, count);
    }
    final size_t writebuffer(T)(in T[] buffer){
        return this.writebuffer!T(buffer.ptr, buffer.length);
    }
    final void write(T)(in auto ref T value) if(!isArray!T){
        auto result = this.writebuffer(&value, 1);
        if(result != T.sizeof) throw new StreamWriteException();
    }
    final void write(Iter)(in Iter values) if(isIterable!Iter){
        foreach(value; values) this.write!(typeof(value))(value);
    }
}

/// A stream which can be both read from and written to.
interface IOStream : InputStream, OutputStream {
    //
}
