module mach.io.stream.range;

private:

import mach.text : text;
import mach.io.stream.stream;

public:



/// Get a range for iterating over the data in a stream, where each unit is of
/// the given type.
auto asrange(Element = char, Source)(Source source) if(isInputStream!Source){
    return StreamRange!(Source, Element)(source);
}



/// Get the contents of a stream as an array.
auto asarray(Element = char, Source)(Source source) if(
    isInputStream!Source && (
        (Source.haslength && Source.hasposition) || Source.haseof
    )
){
    Element[] array;
    static if(Source.haslength && Source.hasposition){ // Known length
        array.length = (source.length - source.position) / Element.sizeof;
        auto result = source.readbuffer(array);
        if(result != array.length){
            throw new StreamReadException(text(
                "Failed to get stream contents as array. Expected ", array.length,
                " elements but found ", result, "."
            ));
        }
    }else static if(Source.haseof){ // Unknown but finite length
        while(!source.eof){
            Element element;
            auto result = source.readbuffer(&element);
            if(result != 1) break;
            array ~= element;
        }
    }else{ // Shouldn't ever happen
        static assert(false);
    }
    return array;
}

/// Get the up to the first so many elements of a stream as an array.
auto asarray(Element = char, Source)(Source source, size_t limit) if(
    isInputStream!Source
){
    Element[] array;
    static if(Source.haslength){
        static if(Source.hasposition) auto length = source.length - source.position;
        else auto length = source.length;
        length /= Element.sizeof;
        array.reserve(length < limit ? length : limit);
    }else{
        array.reserve(limit);
    }
    while(array.length < limit){
        Element element;
        auto result = source.readbuffer(&element);
        if(result != 1) break;
        array ~= element;
    }
    return array;
}



struct StreamRange(Source, Element) if(isInputStream!Source){
    enum bool isOutput = isOutputStream!Source;
    
    Source source;
    Element cachedfront;
    static if(Source.haseof) bool empty;
    else enum bool empty = false;
    
    this(Source source){
        this.source = source;
        this.popFront();
    }
    this(Source source, Element cachedfront, bool empty){
        this.source = source;
        this.cachedfront = cachedfront;
        this.empty = empty;
    }
    
    @property auto front(){
        return this.cachedfront;
    }
    void popFront(){
        static if(Source.haseof){
            this.empty = this.source.eof;
            if(!this.empty){
                auto count = this.source.readbuffer(&this.cachedfront);
                // Ignore odd bytes at end of stream
                if(count != 1) this.empty = true;
            }
        }else{
            this.source.readbuffer(&this.cachedfront);
        }
    }
    
    static if(isOutput && Source.hasposition && Source.canseek){
        static enum bool mutable = true;
        @property void front(Element value){
            this.source.position = this.source.position - Element.sizeof;
            this.source.writebuffer(&value);
        }
    }
    
    static if(Source.haslength){
        @property auto length(){
            return this.source.length / Element.sizeof;
        }
    }
}



version(unittest){
    private:
    import std.path;
    import mach.error.unit;
    import mach.range : headis;
    import mach.io.stream.filestream : FileStream;
    enum string TestPath = __FILE__.dirName ~ "/range.txt";
}
unittest{
    tests("Stream as range", {
        tests("Single-byte elements", {
            auto stream = new FileStream(TestPath, "rb");
            auto range = stream.asrange!char;
            testeq(range.front, 'I');
            testeq(range.length, 85);
            test(range.headis("I am used to validate unittests."));
            stream.close;
        });
        tests("Multi-byte elements", {
            auto stream = new FileStream(TestPath, "rb");
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
unittest{
    tests("Stream as array", {
        tests("Implicit length", {
            auto stream = new FileStream(TestPath, "rb");
            auto array = stream.asarray;
            testeq(array.length, 85);
            testeq(array[0..32], "I am used to validate unittests.");
            stream.close;
        });
        tests("Explicit length", {
            tests("Shorter than stream", {
                auto stream = new FileStream(TestPath, "rb");
                auto array = stream.asarray(32);
                testeq(array.length, 32);
                testeq(array, "I am used to validate unittests.");
                stream.close;
            });
            tests("Longer than stream", {
                auto stream = new FileStream(TestPath, "rb");
                auto array = stream.asarray(100);
                testeq(array.length, 85);
                testeq(array[0..32], "I am used to validate unittests.");
                stream.close;
            });
        });
    });
}
