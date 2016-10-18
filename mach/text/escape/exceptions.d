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
    dchar ch;
    this(dchar ch, size_t line = __LINE__, string file = __FILE__){
        super(
            "Failed to escape character. Character " ~
            "'" ~ (cast(string) ch.utf8encode.chars) ~ "' " ~
            "cannot be encoded using these settings.",
            null, line, file
        );
        this.ch = ch;
    }
}

/// Base exception thrown when unescaping a string fails.
class StringUnescapeException: EscapeException{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to unescape string: " ~ message, next, line, file);
    }
}

/// Thrown when unexpected EOF is encountered while unescaping a string.
class StringUnescapeEOFException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Unexpected end of input.", next, line, file);
    }
    static void enforce(T)(auto ref T cond){
        if(!cond) throw new typeof(this);
    }
}
/// Thrown when an unknown escape sequence is encountered while unescaping
/// a string.
class StringUnescapeUnknownException: StringUnescapeException{
    char initial;
    this(char initial, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Unrecognized escape sequence with initial char '" ~ initial ~ "'.", next, line, file);
        this.initial = initial;
    }
    static void enforce(T)(auto ref T cond, char initial){
        if(!cond) throw new typeof(this)(initial);
    }
}
/// Thrown when invalid hex is encountered while unescaping a string.
class StringUnescapeHexException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to parse hexadecimal escape sequence.", next, line, file);
    }
}
/// Thrown when invalid octal is encountered while unescaping a string.
class StringUnescapeOctException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to parse octal escape sequence.", next, line, file);
    }
}
/// Thrown when an invalid HTML5 name is encountered while unescaping a string.
class StringUnescapeInvalidNameException: StringUnescapeException{
    string name;
    this(string name, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Invalid named escape sequence \"\\&" ~ name ~ ";\".", next, line, file);
        this.name = name;
    }
    static void enforce(T)(auto ref T cond, string name){
        if(!cond) throw new typeof(this)(name);
    }
}
/// Thrown when an unterminated HTML5 name is encountered while unescaping a string.
class StringUnescapeUnterminatedNameException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered unterminated named escape sequence.", next, line, file);
    }
    static void enforce(T)(auto ref T cond){
        if(!cond) throw new typeof(this);
    }
}
