module mach.text.utf.exceptions;

private:

/++ Docs

This module implements the various exception types that may be thrown by
functions in the `mach.text.utf` package.
All such exceptions inherit from the base `UTFException` class.
Encoding errors result in a `UTFEncodeException` and decoding errors result
in a `UTFDecodeException`.

+/

public:



/// Base class for UTF encoding and decoding exceptions.
class UTFException: Exception{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
}



/// Exception thrown when encoding a UTF string fails.
class UTFEncodeException: UTFException{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Encountered invalid code while when attempting to encode UTF string.", null, line, file);
    }
}



/// Exception thrown when decoding a UTF-encoded string fails.
class UTFDecodeException: UTFException{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, next, line, file);
    }
    auto enforce(T)(auto ref T cond) const{
        if(!cond) throw this;
        return cond;
    }
}

/// Exception thrown when decoding a UTF-encoded string fails
/// as the result of an unexpected end-of-input.
class UTFDecodeEOFException: UTFDecodeException{
    this(string encoding, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered unexpected EOF while decoding " ~ encoding ~ " string.", null, line, file);
    }
}

/// Exception thrown when decoding a UTF-encoded string fails
/// as the result of a malformed code point.
class UTFDecodeInvalidException: UTFDecodeException{
    this(string encoding, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered malformed code point while decoding " ~ encoding ~ " string.", null, line, file);
    }
}
