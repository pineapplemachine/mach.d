module mach.text.escape.exceptions;

private:

import mach.text.utf : utf8encode;

public:



/// Base class for exceptions thrown when failing to escape or unescape strings.
class EscapeException: Exception{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, null);
    }
}

/// Exception thrown when escaping a character or string fails.
class CharEscapeException: EscapeException{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Character cannot be encoded using the current settings.", null, line, file);
    }
}

/// Base exception thrown when unescaping a string fails.
class StringUnescapeException: EscapeException{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to unescape string: " ~ message, next, line, file);
    }
}

/// Thrown when invalid UTF is encountered while unescaping a string.
class StringUnescapeUTFException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Invalid UTF.", next, line, file);
    }
}

/// Thrown when unexpected EOF is encountered while unescaping a string.
class StringUnescapeEOFException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Unexpected end of input.", next, line, file);
    }
}

/// Thrown when an unknown escape sequence is encountered while unescaping
/// a string.
class StringUnescapeUnknownException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Unrecognized escape sequence.", next, line, file);
    }
}

/// Thrown when invalid hex is encountered while unescaping a string.
class StringUnescapeHexException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to parse hexadecimal escape sequence.", next, line, file);
    }
}

/// Thrown when an invalid HTML5 name is encountered while unescaping a string.
class StringUnescapeNameException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Invalid named character entity.", next, line, file);
    }
}
