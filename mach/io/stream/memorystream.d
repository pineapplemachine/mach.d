module mach.io.stream.memorystream;

private:

import mach.io.file.sys : Seek;
import mach.sys.memory : memmove;
import mach.error : IndexOutOfBoundsError, InvalidSliceBoundsError;

/++ Docs

The MemoryStream type implements reading from and writing to a pointer in
memory using a stream-like interface.

+/

public:



/// Error type thrown when attempting to perform an operation upon a
/// `MemoryStream` when that stream is not active.
/// These checks are omitted in release mode; in which case you should expect
/// nasty segfaults instead.
class MemoryStreamInactiveError: Error{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Operation failed because the MemoryStream is not active.", file, line, null);
    }
}



/// Get an array as a MemoryStream.
/// The returned MemoryStream will be read-only if the array or its elements
/// are either const or immutable. Otherwise, it will be writeable.
static auto asstream(T)(T[] array, size_t pos = 0){
    return MemoryStream!(!is(T == const) && !is(T == immutable))(array, pos);
}

/// Get a pointer to some memory and a length of that memory as a MemoryStream.
/// The returned MemoryStream will be read-only if the array or its elements
/// are either const or immutable. Otherwise, it will be writeable.
static auto asstream(T)(T* ptr, size_t memlength, size_t pos = 0){
    return MemoryStream!(!is(T == const) && !is(T == immutable))(ptr, memlength, pos);
}



/// A memory stream that is able and allowed to write to the backing memory.
alias MutableMemoryStream = MemoryStream!true;

/// A memory stream referring to data that it is not allowed to change.
alias ReadOnlyMemoryStream = MemoryStream!false;

/// Provides a stream interface for reading and writing data in memory.
struct MemoryStream(bool mutable){
    alias Seek = .Seek;
    
    static if(mutable) alias Pointer = ubyte*;
    else alias Pointer = const(ubyte)*;
    
    /// The location in memory to read to and write from.
    Pointer ptr = null;
    /// The size of the portion of memory to read to and write from.
    size_t memlength = 0;
    /// The current position of the stream in memory.
    size_t pos = 0;
    
    this(T)(T[] array, size_t pos = 0){
        this(array.ptr, array.length, pos);
    }
    this(T)(T* ptr, size_t memlength, size_t pos = 0){
        this.ptr = cast(ubyte*) ptr;
        this.memlength = memlength * T.sizeof;
        this.pos = pos;
    }
    
    @property bool active() const{
        return this.ptr !is null;
    }
    void assertactive() const{
        static const error = new MemoryStreamInactiveError();
        if(!this.active) throw error;
    }
    
    void close() in{
        this.assertactive();
    }body{
        this.ptr = null;
        this.memlength = 0;
        this.pos = 0;
    }
    
    /// True when the stream's position has met or exceeded its length.
    @property bool eof() const in{
        this.assertactive();
    }body{
        return this.pos >= this.memlength;
    }
    
    /// The length of the stream in bytes.
    @property auto length() const in{
        this.assertactive();
    }body{
        return this.memlength;
    }
    /// The number of bytes remaining to be read or written before EOF.
    @property auto remaining() const in{
        this.assertactive();
    } body{
        return this.memlength - this.pos;
    }
    
    alias opDollar = length;
    
    /// Get the current position in the stream.
    @property auto position() const in{
        this.assertactive();
    }body{
        return this.pos;
    }
    /// Set the current position in the stream.
    @property void position(in size_t pos) in{
        this.assertactive();
        static const ooberror = new IndexOutOfBoundsError("Position out of bounds.");
        const checked = ooberror.enforce(pos, 0, this.length);
    }body{
        this.pos = pos;
    }
    
    /// Skip a given number of bytes. Returns the number of bytes
    /// that were actually skipped, which may be less than the number
    /// of bytes in the stream if attempting to skip past the end
    size_t skip(in size_t count) in{
        this.assertactive();
    }body{
        if(this.pos >= this.length){
            return 0;
        }else if(count >= this.length - this.pos){
            const skipped = this.length - this.pos;
            this.pos = this.length;
            return skipped;
        }else{
            this.pos += count;
            return count;
        }
    }
    
    /// Reset the stream's position to its beginning.
    void reset() in{
        this.assertactive();
    }body{
        this.pos = 0;
    }
    
    // TODO: Endianness?
    size_t readbufferv(void* buffer, in size_t size, in size_t count) in{
        this.assertactive();
        assert(buffer !is null);
    }body{
        immutable goal = count * size;
        immutable cap = goal <= this.remaining ? goal : this.remaining;
        immutable actual = cap % size == 0 ? cap : cap - cap % size;
        memmove(cast(ubyte*) buffer, this.ptr + this.pos, actual);
        this.pos += actual;
        return actual;
    }
    static if(mutable) size_t writebufferv(
        const(void)* buffer, in size_t size, in size_t count
    ) in{
        this.assertactive();
        assert(buffer !is null);
    }body{
        immutable goal = count * size;
        immutable cap = goal <= this.remaining ? goal : this.remaining;
        immutable actual = cap % size == 0 ? cap : cap - cap % size;
        memmove(this.ptr + this.pos, cast(ubyte*) buffer, actual);
        this.pos += actual;
        return actual;
    }
    
    /// Get a byte at an index.
    auto opIndex(in size_t index) in{
        this.assertactive();
        static const ooberror = new IndexOutOfBoundsError("Position out of bounds.");
        const checked = ooberror.enforce(index, 0, this.length);
    }body{
        return this.ptr[index];
    }
    /// Set a byte at an index.
    static if(mutable) auto opIndexAssign(in ubyte value, in size_t index) in{
        this.assertactive();
        static const ooberror = new IndexOutOfBoundsError("Position out of bounds.");
        const checked = ooberror.enforce(index, 0, this.length);
    }body{
        return this.ptr[index] = value;
    }
    /// Get as a slice the stream's bytes from a low until a high index.
    auto opSlice(in size_t low, in size_t high) in{
        this.assertactive();
        static const error = new InvalidSliceBoundsError();
        error.enforce(low, high, this);
    }body{
         return this.ptr[low .. high];
    }
}



private version(unittest){
    import mach.io.stream.io;
    import mach.io.stream.templates;
}

unittest {
    // Basic types
    static assert(isIOStream!(MemoryStream!true));
    static assert(isInputStream!(MemoryStream!false));
    static assert(!isOutputStream!(MemoryStream!false));
    // Types inferred by asstream
    static assert(isIOStream!(typeof(asstream((char[]).init))));
    static assert(!isOutputStream!(typeof(asstream((const(char)[]).init))));
    static assert(!isOutputStream!(typeof(asstream(const(char[]).init))));
}

/// Read-only stream
unittest {
    auto stream = "Hello World".asstream;
    // Strings can make readable streams but not writeable
    static assert(isInputStream!(typeof(stream)));
    static assert(!isOutputStream!(typeof(stream)));
    // Read the contents of the stream
    assert(stream.length == 11);
    char[] buffer = new char[5];
    stream.readbuffer(buffer);
    assert(buffer == "Hello");
    assert(stream.read!char == ' ');
    stream.readbuffer(buffer);
    assert(buffer == "World");
}

/// Write to stream
unittest {
    auto data = new char[5];
    auto stream = data.asstream;
    static assert(isIOStream!(typeof(stream)));
    stream.writebuffer("hello");
    assert(data == "hello");
    stream.position = 0;
    stream.write('y');
    assert(data == "yello");
}

/// Read and write binary data
unittest {
    auto data = new char[8];
    auto stream = MutableMemoryStream(data);
    static assert(isIOStream!(typeof(stream)));
    stream.write!int(0x12345678);
    stream.write!float(1234.567);
    stream.position = 0;
    assert(stream.read!int == 0x12345678);
    assert(stream.read!float == float(1234.567));
    assert(stream.eof);
}

/// Skip the next N bytes
unittest {
    ubyte[] data = [1, 2, 3, 4, 5, 6];
    auto stream = ReadOnlyMemoryStream(data);
    assert(stream.read!ubyte == 1);
    assert(stream.skip(3) == 3);
    assert(stream.read!ubyte == 5);
    assert(stream.skip(3) == 1); // Only 1 byte left in stream
    assert(stream.eof);
    assert(stream.skip(3) == 0); // No more bytes left in stream
}
