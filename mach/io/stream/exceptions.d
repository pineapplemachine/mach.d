module mach.io.stream.exceptions;

private:

//

public:



/// Base class for exceptions thrown by failed stream operations.
class StreamException: Exception{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
}

/// Exception thrown by failed stream input operations.
class StreamReadException: StreamException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Error reading from stream.", next, line, file);
    }
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Error reading from stream: " ~ message, next, line, file);
    }
}

/// Exception thrown by failed stream output operations.
class StreamWriteException: StreamException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Error writing to stream.", next, line, file);
    }
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Error writing to stream: " ~ message, next, line, file);
    }
}
