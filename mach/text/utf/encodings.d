module mach.text.utf.encodings;

private:

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
