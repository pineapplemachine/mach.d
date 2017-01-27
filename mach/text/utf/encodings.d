module mach.text.utf.encodings;

private:

import mach.traits : isCharacter;

/++ Docs

This module implements the `UTFEncoding` enum, which enumerates all
recognized UTF encodings.

+/

public:



/// An enumeration of recognized UTF encodings.
enum UTFEncoding{
    UTF8, /// UTF-8 encoding
    UTF16, /// UTF-16 encoding, endianness unknown/irrelevant
    UTF16LE, /// UTF-16 encoding, little-endian
    UTF16BE, /// UTF-16 encoding, big-endian
    UTF32, /// UTF-32 encoding, endianness unknown/irrelevant
    UTF32LE, /// UTF-32 encoding, little-endian
    UTF32BE, /// UTF-32 encoding, big-endian
}



template UTFEncodingForChar(T) if(isCharacter!T){
    static if(T.sizeof == 1){
        enum UTFEncodingForChar = UTFEncoding.UTF8;
    }else static if(T.sizeof == 2){
        enum UTFEncodingForChar = UTFEncoding.UTF16;
    }else static if(T.sizeof == 4){
        enum UTFEncodingForChar = UTFEncoding.UTF32;
    }else{
        static assert(false); // Shouldn't happen
    }
}
