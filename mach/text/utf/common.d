module mach.text.utf.common;

private:

//

public:



/// Base class for UTF exceptions.
class UTFException: Exception{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
}
