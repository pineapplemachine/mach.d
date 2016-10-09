module mach.io.stream.asarray;

private:

import mach.traits : hasNumericLength;
import mach.text : text;
import mach.io.stream.exceptions;
import mach.io.stream.io;
import mach.io.stream.templates;

public:



/// Get the contents of a stream as an array.
auto asarray(Element = char, Stream)(auto ref Stream source) if(
    isFiniteInputStream!Stream
){
    Element[] array;
    static if(hasNumericLength!Stream && isTellStream!Stream){ // Known length
        array.length = (source.length - source.position) / Element.sizeof;
        auto result = source.readbuffer(array);
        if(result != array.length){
            throw new StreamReadException(text(
                "Failed to get stream contents as array. Expected ", array.length,
                " elements but found ", result, "."
            ));
        }
    }else{ // Unknown but finite length
        while(!source.eof){
            Element element;
            auto result = source.readbuffer(&element);
            if(result != 1) break;
            array ~= element;
        }
    }
    return array;
}



/// Get the up to the first so many elements of a stream as an array.
auto asarray(Element = char, Stream)(auto ref Stream source, in size_t limit) if(
    isInputStream!Stream
){
    Element[] array;
    static if(hasNumericLength!Stream){
        static if(isTellStream!Stream) auto length = source.length - source.position;
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



version(unittest){
    private:
    import std.path;
    import mach.test;
    import mach.io.stream.filestream : FileStream;
    enum string TestPath = __FILE__.dirName ~ "/range.txt";
}
unittest{
    tests("Stream as array", {
        tests("Implicit length", {
            auto stream = FileStream(TestPath, "rb");
            auto array = stream.asarray;
            testeq(array.length, 85);
            testeq(array[0..32], "I am used to validate unittests.");
            stream.close;
        });
        tests("Explicit length", {
            tests("Shorter than stream", {
                auto stream = FileStream(TestPath, "rb");
                auto array = stream.asarray(32);
                testeq(array.length, 32);
                testeq(array, "I am used to validate unittests.");
                stream.close;
            });
            tests("Longer than stream", {
                auto stream = FileStream(TestPath, "rb");
                auto array = stream.asarray(100);
                testeq(array.length, 85);
                testeq(array[0..32], "I am used to validate unittests.");
                stream.close;
            });
        });
    });
}
