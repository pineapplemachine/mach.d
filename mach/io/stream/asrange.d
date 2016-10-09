module mach.io.stream.asrange;

private:

import mach.traits : hasNumericLength;
import mach.io.stream.io;
import mach.io.stream.templates;

public:



/// Get a range for iterating over the data in a stream, where each unit is of
/// the given type.
auto asrange(Element = char, Stream)(auto ref Stream source) if(isInputStream!Stream){
    return StreamRange!(Stream, Element)(source);
}



/// Range for iterating over the contents of a stream.
struct StreamRange(Stream, Element) if(isInputStream!Stream){
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
    this(Stream source, Element cachedfront, bool empty){
        this.source = source;
        this.cachedfront = cachedfront;
        this.empty = empty;
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
            this.source.position = cast(size_t)(this.source.position - Element.sizeof);
            this.source.writebuffer(&value);
        }
    }
    
    static if(hasNumericLength!Stream){
        @property auto length(){
            return this.source.length / Element.sizeof;
        }
    }
}



version(unittest){
    private:
    import std.path;
    import mach.test;
    import mach.range : headis;
    import mach.io.stream.filestream : FileStream;
    enum string TestPath = __FILE__.dirName ~ "/range.txt";
}
unittest{
    // TODO: Use an ArrayStream or something instead of a FileStream for tests
    tests("Stream as range", {
        tests("Single-byte elements", {
            auto stream = FileStream(TestPath, "rb");
            auto range = stream.asrange!char;
            testeq(range.front, 'I');
            testeq(range.length, 85);
            test(range.headis("I am used to validate unittests."));
            stream.close;
        });
        tests("Multi-byte elements", {
            auto stream = FileStream(TestPath, "rb");
            auto range = stream.asrange!ushort;
            // TODO: The success of this test is likely endianness-dependent
            // But I haven't currently got the means to verify that assumption.
            // If this unittest inexplicably fails, it's probably because you
            // need to just unconditionally do the little endian test and trash
            // the big endian version.
            version(LittleEndian){
                testeq(range.front & 0x00ff, 'I');
                testeq((range.front & 0xff00) >> 8, ' ');
            }else{
                testeq(range.front & 0x00ff, ' ');
                testeq((range.front & 0xff00) >> 8, 'I');
            }
            stream.close;
        });
    });
}
