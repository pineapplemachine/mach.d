module mach.text.json.exceptions;

private:

import mach.text.text : text;

public:



/// Base class for exceptions thrown by json operations.
class JsonException : Exception{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
}

/// Thrown when attempting to perform an operation upon a json value
/// that is unsupported by that type.
class JsonInvalidOperationException : JsonException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Operation unsupported by type.", next, line, file);
    }
}

/// Base class for exceptions encountered while decoding json.
class JsonParseException : JsonException{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, next, line, file);
    }
}

/// Base class for exceptions encountered while decoding json,
/// for which position in the input string is meaningful data.
class JsonParsePositionalException : JsonParseException{
    size_t jline;
    size_t jpos;
    this(string message, size_t jline, size_t jpos, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(
            text(message, " at ", jline, ':', jpos, '.'),
            next, line, file
        );
        this.jline = jline;
        this.jpos = jpos;
    }
}

/// Thrown when json decoding encouters an unexpected EOF.
class JsonParseEOFException : JsonParseException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered unexpected EOF", next, line, file);
    }
}

/// Thrown when json decoding expects an EOF, but finds trailing characters.
class JsonParseTrailingException : JsonParsePositionalException{
    this(size_t jline, size_t jpos, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Expected EOF but found additional data", jline, jpos, next, line, file);
    }
}

/// Thrown when json decoding encounters an unexpected character.
class JsonParseUnexpectedException : JsonParsePositionalException{
    this(size_t jline, size_t jpos, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered unexpected data", jline, jpos, next, line, file);
    }
    this(string expected, size_t jline, size_t jpos, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(text("Encountered unexpected data; expected ", expected), jline, jpos, next, line, file);
    }
}

/// Thrown when json decoding encounters an unterminated string literal.
class JsonParseUnterminatedStrException : JsonParsePositionalException{
    this(size_t jline, size_t jpos, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered unterminated string literal", jline, jpos, next, line, file);
    }
}

/// Thrown when json decoding encounters an invalid escape sequence in a string literal.
class JsonParseEscSeqException : JsonParsePositionalException{
    this(size_t jline, size_t jpos, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered invalid escape sequence in string literal", jline, jpos, next, line, file);
    }
}

/// Thrown when json decoding encounters a malformed numeric literal.
class JsonParseNumberException : JsonParsePositionalException{
    this(size_t jline, size_t jpos, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered malformed numeric literal", jline, jpos, next, line, file);
    }
}

/// Thrown when json decoding encounters a repeated object key.
class JsonParseDupKeyException : JsonParsePositionalException{
    string key;
    this(string key, size_t jline, size_t jpos, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(text("Encountered duplicate key \"", key, '"'), jline, jpos, next, line, file);
        this.key = key;
    }
}
