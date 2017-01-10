module mach.text.numeric.exceptions;

private:

/++ Docs

This module implements the `NumberParseException` and `NumberWriteError`
exception types, which are thrown by some operations elsewhere in this package.

+/

public:



/// Exception raised when a number fails to parse.
/// Number parse exceptions are considered to be recoverable;
/// they can be expected to easily occur when parsing user-inputted strings.
class NumberParseException: Exception{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        this("Encountered an unexpected character or end-of-input during parsing.", next, line, file);
    }
    auto enforce(T)(auto ref T cond) const{
        if(!cond) throw this;
        return cond;
    }
}

/// Error raised when a number fails to be serialized.
/// Number write exceptions are considered to not be recoverable.
class NumberWriteError: Error{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        this("Failed to serialize number to string.", next, line, file);
    }
    auto enforce(T)(auto ref T cond) const{
        if(!cond) throw this;
        return cond;
    }
}
