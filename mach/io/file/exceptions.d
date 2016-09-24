module mach.io.file.exceptions;

private:

import mach.text : text;

public:



/// Base class for exceptions thrown by failed file operations.
class FileException: Exception{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
}

class FileStatException: FileException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to stat file.", next, line, file);
    }
}

class FileSyncException: FileException{
    int error;
    this(Err)(Err error, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(text("Failed to sync file, error code ", error, "."), next, line, file);
        this.error = cast(int) error;
    }
}

class FileOpenException: FileException{
    string path;
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(text("Failed to open file \"", path, "\"."), next, line, file);
        this.path = path;
    }
}

class FileRenameException: FileException{
    string src;
    string dst;
    this(string src, string dst, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(text("Failed to rename file \"", src, "\" to \"", dst, "\"."), next, line, file);
        this.src = src;
        this.dst = dst;
    }
}

class FileRemoveException: FileException{
    string path;
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(text("Failed to remove file \"", path, "\"."), next, line, file);
        this.path = path;
    }
}
