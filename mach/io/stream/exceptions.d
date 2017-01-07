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

/// Exception thrown when failing to set position in a stream.
class StreamSeekException: StreamException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to set position in stream.", next, line, file);
    }
}

/// Exception thrown when failing to get position in a stream.
class StreamTellException: StreamException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to get position in stream.", next, line, file);
    }
}

/// Exception thrown when failing to skip content in a stream.
class StreamSkipException: StreamException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to skip content in stream.", next, line, file);
    }
}

/// Exception thrown when failing to flush a stream.
class StreamFlushException: StreamException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to flush stream.", next, line, file);
    }
}

/// Exception thrown when failing to close a stream.
class StreamCloseException: StreamException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to close stream.", next, line, file);
    }
}
