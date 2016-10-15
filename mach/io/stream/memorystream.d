module mach.io.stream.memorystream;

private:

import mach.sys.memory : memmove;
import mach.error : enforcebounds;

public:



static auto asstream(T)(T[] array, size_t pos = 0){
    return MemoryStream!(!is(T == const) && !is(T == immutable))(array, pos);
}
static auto asstream(T)(T* ptr, size_t memlength, size_t pos = 0){
    return MemoryStream!(!is(T == const) && !is(T == immutable))(ptr, memlength, pos);
}



/// Provides a stream interface for reading and writing data in memory.
struct MemoryStream(bool mutable){
    /// The location in memory to read to and write from.
    ubyte* ptr = null;
    /// The size of the portion of memory to read to and write from.
    size_t memlength = 0;
    /// The current position of the stream in memory.
    size_t pos = 0;
    
    this(T)(T[] array, size_t pos = 0){
        this(array.ptr, array.length * T.sizeof, pos);
    }
    this(T)(T* ptr, size_t memlength, size_t pos = 0){
        this.ptr = cast(ubyte*) ptr;
        this.memlength = memlength * T.sizeof;
        this.pos = pos;
    }
    
    @property bool active() const{
        return this.ptr !is null;
    }
    void close() in{assert(this.active);} body{
        this.ptr = null;
        this.memlength = 0;
        this.pos = 0;
    }
    
    /// True when the stream's position has met or exceeded its length.
    @property bool eof() const in{assert(this.active);} body{
        return this.pos >= this.memlength;
    }
    
    /// The length of the stream in bytes.
    @property auto length() const in{assert(this.active);} body{
        return this.memlength;
    }
    /// The number of bytes remaining to be read or written before EOF.
    @property auto remaining() const in{assert(this.active);} body{
        return this.memlength - this.pos;
    }
    
    alias opDollar = length;
    
    /// Get the current position in the stream.
    @property auto position() const in{assert(this.active);} body{
        return this.pos;
    }
    /// Set the current position in the stream.
    @property void position(in size_t pos) in{
        assert(this.active);
        enforcebounds(pos, this);
    }body{
        this.pos = pos;
    }
    
    /// Reset the stream's position to its beginning.
    void reset() in{assert(this.active);} body{
        this.pos = 0;
    }
    
    size_t readbufferv(void* buffer, size_t size, size_t count) in{
        assert(this.active);
    }body{
        immutable goal = count * size;
        immutable cap = goal <= this.remaining ? goal : this.remaining;
        immutable actual = cap % size == 0 ? cap : cap - cap % size;
        memmove(buffer, this.ptr + this.pos, actual);
        this.pos += actual;
        return actual;
    }
    static if(mutable) size_t writebufferv(void* buffer, size_t size, size_t count) in{
        assert(this.active);
    }body{
        immutable goal = count * size;
        immutable cap = goal <= this.remaining ? goal : this.remaining;
        immutable actual = cap % size == 0 ? cap : cap - cap % size;
        memmove(this.ptr + this.pos, buffer, actual);
        this.pos += actual;
        return actual;
    }
    
    /// Get a byte at an index.
    auto opIndex(in size_t index) in{
        assert(this.active);
        enforcebounds(index, this);
    }body{
        return this.ptr[index];
    }
    /// Set a byte at an index.
    static if(mutable) auto opIndexAssign(in ubyte value, in size_t index) in{
        assert(this.active);
        enforcebounds(index, this);
    }body{
        return this.ptr[index] = value;
    }
    /// Get as a slice the stream's bytes from a low until a high index.
    auto opSlice(in size_t low, in size_t high) in{
        assert(low >= 0 && high >= low && high <= this.length);
    }body{
         return this.ptr[low .. high];
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.io.stream.io;
    import mach.io.stream.templates;
}
unittest{
    tests("Memory stream", {
        static assert(isIOStream!(MemoryStream!true));
        static assert(isInputStream!(MemoryStream!false));
        static assert(!isOutputStream!(MemoryStream!false));
        tests("Read", {
            auto stream = "Hello World".asstream;
            static assert(isInputStream!(typeof(stream)));
            static assert(!isOutputStream!(typeof(stream)));
            testeq(stream.length, 11);
            char[] buffer = new char[5];
            stream.readbuffer(buffer);
            testeq(buffer, "Hello");
            testeq(stream.read!char, ' ');
            stream.readbuffer(buffer);
            testeq(buffer, "World");
        });
        tests("Write", {
            auto data = new char[5];
            auto stream = data.asstream;
            static assert(isIOStream!(typeof(stream)));
            stream.writebuffer("hello");
            testeq(data, "hello");
            stream.position = 0;
            stream.write('y');
            testeq(data, "yello");
        });
    });
    
}
