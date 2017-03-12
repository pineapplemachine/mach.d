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

/// Base class for file operation exceptions that apply to one file path.
class FilePathException: FileException{
    string path;
    this(in string base, string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(base ~ " \"" ~ path ~ "\".", next, line, file);
        this.path = path;
    }
}

/// Base class for file operation exceptions that apply to a source and a
/// destination file path.
class FileSrcDstException: FileException{
    string source;
    string destination;
    this(in string base, string source, string destination, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(base ~ " from \"" ~ source ~ "\" to \"" ~ destination ~ "\".", next, line, file);
        this.source = source;
        this.destination = destination;
    }
}



/// Exception thrown when failing to seek a position in a file.
class FileSeekException: FileException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to seek file.", next, line, file);
    }
}

/// Exception thrown when failing to sync a file stream.
class FileSyncException: FileException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to sync file.", next, line, file);
    }
}



/// Exception thrown when failing to get information about a file path.
class FileStatException: FilePathException{
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to stat file", path, next, line, file);
    }
}

/// Exception thrown when failing to get the size of a file.
class FileSizeException: FilePathException{
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to get size of file", path, next, line, file);
    }
}

/// Exception thrown when failing to open a file stream.
class FileOpenException: FilePathException{
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to open file", path, next, line, file);
    }
}

/// Exception thrown when failing to remove the file at a path.
class FileRemoveException: FilePathException{
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to remove file", path, next, line, file);
    }
}

/// Exception thrown when failing to set permissions on a file.
class FileSetPermissionsException: FilePathException{
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to set permissions on file", path, next, line, file);
    }
}

/// Exception thrown when failing to set time information for a file.
class FileSetTimeException: FilePathException{
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to set time information on file", path, next, line, file);
    }
}



/// Exception thrown when failing to rename a file.
class FileRenameException: FileSrcDstException{
    this(string source, string destination, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to rename file", source, destination, next, line, file);
    }
}

/// Exception thrown when failing to copy a file.
class FileCopyException: FileSrcDstException{
    this(string source, string destination, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to copy file", source, destination, next, line, file);
    }
}



/// Exception thrown when failing to get the current directory path.
class FileGetCurrentDirException: FileException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to get current directory.", next, line, file);
    }
}

/// Exception thrown when failing to change the current directory.
class FileChangeDirException: FilePathException{
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to set current directory", path, next, line, file);
    }
}

/// Exception thrown when failing to create a directory at a path.
class FileCreateDirException: FilePathException{
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to create directory", path, next, line, file);
    }
}

/// Exception thrown when failing to remove the directory at a path.
class FileRemoveDirException: FilePathException{
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to remove directory", path, next, line, file);
    }
}
