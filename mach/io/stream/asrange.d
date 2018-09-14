module mach.io.stream.asrange;

private:

import mach.traits.length : hasNumericLength;
import mach.io.stream.io;
import mach.io.stream.templates;

public:



/// Get a range for iterating over the data in a stream, where each unit is of
/// the given type.
auto asrange(Element = char, Stream)(
    auto ref Stream source
) if(isInputStream!Stream) {
    return StreamRange!(Stream, Element)(source);
}



/// Range for iterating over the contents of a stream.
struct StreamRange(Stream, Element) if(isInputStream!Stream) {
    enum bool isOutput = isOutputStream!Stream;
    enum bool isFinite = isFiniteInputStream!Stream;
    
    Stream source;
    Element cachedfront;
    static if(isFinite) bool empty;
    else enum bool empty = false;
    
    this(Stream source){
        this.source = source;
        this.popFront();
    }
    static if(isFinite){
        this(Stream source, Element cachedfront, bool empty){
            this.source = source;
            this.cachedfront = cachedfront;
            this.empty = empty;
        }
    }else{
        this(Stream source, Element cachedfront){
            this.source = source;
            this.cachedfront = cachedfront;
        }
    }
    
    @property auto front(){
        return this.cachedfront;
    }
    void popFront(){
        static if(isFinite){
            this.empty = this.source.eof;
            if(!this.empty){
                auto count = this.source.readbuffer(&this.cachedfront);
                // Ignore dangling bytes at end of stream
                if(count != 1) this.empty = true;
            }
        }else{
            this.source.readbuffer(&this.cachedfront);
        }
    }
    
    static if(isOutput && isSeekStream!Stream && isTellStream!Stream){
        static enum bool mutable = true;
        @property void front(Element value){
            this.source.position = cast(size_t) (
                this.source.position - Element.sizeof
            );
            this.source.writebuffer(&value);
        }
    }
    
    static if(hasNumericLength!Stream){
        @property auto length(){
            return this.source.length / Element.sizeof;
        }
    }
    
    static if(isClosingStream!Stream){
        void close(){
            this.source.close;
            this.empty = true;
        }
    }
}



private version(unittest) {
    import mach.range : headis;
    import mach.io.file.path : Path;
    import mach.io.stream.filestream : FileStream;
    import mach.io.stream.memorystream : ReadOnlyMemoryStream;
    enum string TestPath = Path(__FILE_FULL_PATH__).directory ~ "/range.txt";
}

/// File stream as range (single-byte elements)
unittest {
    auto stream = FileStream(TestPath, "rb");
    auto range = stream.asrange!char;
    assert(range.front == 'I');
    assert(range.length == 85);
    assert(range.headis("I am used to validate unittests."));
    range.close();
}

/// Memory stream as range (single-byte elements)
unittest {
    char[] data = ['h', 'e', 'l', 'l', 'o'];
    auto stream = ReadOnlyMemoryStream(data);
    auto range = stream.asrange!char;
    assert(range.front == 'h');
    assert(range.length == 5);
    assert(range.headis("hello"));
}

/// File stream as range (multi-byte elements)
unittest {
    auto stream = FileStream(TestPath, "rb");
    auto range = stream.asrange!ushort;
    // TODO: Will this test still pass on a big-endian system?
    // ...And is anyone ever actually going to run this code on one?
    assert((range.front & 0x00ff) == 'I');
    assert((range.front & 0xff00) >> 8 == ' ');
    range.close();
}
