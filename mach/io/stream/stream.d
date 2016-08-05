module mach.io.stream.stream;

private:

//

public:

/// Convenience mixin for stream interfaces.
static string StreamSupportMixin(string[] supported...){
    import std.string : join;
    import std.algorithm : map, canFind;
    static immutable string[] SUPPORT_OPTIONS = [
        "haseof", "haslength", "hasposition", "canseek", "canreset"
    ];
    return join(
        map!((support) => ("static bool " ~ support ~ " = " ~ (
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
    size_t readbuffer(void* buffer, size_t size, size_t count);
    final size_t readbuffer(T)(T* buffer, size_t count){
        return this.readbuffer(buffer, T.sizeof, count);
    }
    final size_t readbuffer(T)(T[] buffer){
        return this.readbuffer!T(buffer.ptr, buffer.length);
    }
}
/// A stream which can be written to.
interface OutputStream : Stream{
    void sync();
    size_t writebuffer(void* buffer, size_t size, size_t count);
    final size_t writebuffer(T)(T* buffer, size_t count){
        return this.writebuffer(buffer, T.sizeof, count);
    }
    final size_t writebuffer(T)(T[] buffer){
        return this.writebuffer!T(buffer.ptr, buffer.length);
    }
}

/// A stream which can be both read from and written to.
interface IOStream : InputStream, OutputStream {
    //
}



// TODO

//struct StreamRange(Source, Element) if(is(Source: Stream)){
//    Source source;
//    Unqual!Element cachedfront;
    
//    static if(is(Source: InputStream)){
//        @property Element front(){
//            return this.cachedfront;
//        }
//        void popFront(){
//            this.source.readbuffer(&this.cachedfront);
//        }
//    }
//    static if(is(Source: OutputStream)){
        
//    }
//}
