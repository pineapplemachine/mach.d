module mach.io.stream.asarray;

private:

import mach.traits.length : hasNumericLength;
import mach.text.text : text;
import mach.io.stream.exceptions;
import mach.io.stream.io;
import mach.io.stream.templates;

/++ Docs

Implements `asarray` for streams. This function eagerly consumes the contents
of a stream and outputs those contents as an array.

The `asarray` function accepts an optional type template argument; this
argument decides what type the elements of the output array shall be.
It also accepts an additional length runtime argument, which puts a cap
on the number of elements that may be consumed from the stream.

+/

private version(unittest) {
    enum string ExampleTestPath = Path(__FILE_FULL_PATH__).directory ~ "/range.txt";
}

unittest { /// Example
    import mach.io.stream.filestream : FileStream;
    FileStream stream = FileStream(ExampleTestPath, "rb");
    char[] array = stream.asarray!char();
    assert(array.length == 85);
    assert(array[0..32] == "I am used to validate unittests.");
    stream.close();
}

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



private version(unittest) {
    import mach.io.file.path : Path;
    import mach.io.stream.filestream : FileStream;
    enum string TestPath = Path(__FILE_FULL_PATH__).directory ~ "/range.txt";
}

/// Implicit length
unittest {
    auto stream = FileStream(TestPath, "rb");
    auto array = stream.asarray;
    assert(array.length == 85);
    assert(array[0..32] == "I am used to validate unittests.");
    stream.close();
}

/// Explicit length (shorter than input)
unittest {
    auto stream = FileStream(TestPath, "rb");
    auto array = stream.asarray(32);
    assert(array.length == 32);
    assert(array == "I am used to validate unittests.");
    stream.close();
}

/// Explicit length (longer than input)
unittest {
    auto stream = FileStream(TestPath, "rb");
    auto array = stream.asarray(100);
    assert(array.length == 85);
    assert(array[0..32] == "I am used to validate unittests.");
    stream.close();
}
