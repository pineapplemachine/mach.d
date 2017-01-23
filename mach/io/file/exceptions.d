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



class FileSeekException: FileException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to seek file.", next, line, file);
    }
}



alias FileStatException = FilePathExceptionTemplate!"Failed to stat file";
alias FileSizeException = FilePathExceptionTemplate!"Failed to get file size";
alias FileSyncException = FilePathExceptionTemplate!"Failed to sync file";
alias FileOpenException = FilePathExceptionTemplate!"Failed to open file";
alias FileRemoveException = FilePathExceptionTemplate!"Failed to remove file";
alias FileRenameException = FileSrcDstExceptionTemplate!"Failed to rename file";
alias FileCopyException = FileSrcDstExceptionTemplate!"Failed to copy file";

alias FileSetPermissionsException = FilePathExceptionTemplate!"Failed to set file permissions";
alias FileSetTimeException = FilePathExceptionTemplate!"Failed to set file time information";

alias FileChangeDirException = FilePathExceptionTemplate!"Failed to change current directory";
alias FileMakeDirException = FilePathExceptionTemplate!"Failed to create directory";
alias FileRemoveDirException = FilePathExceptionTemplate!"Failed to remove directory";

class FileGetCurrentDirException: FileException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to get current directory.", next, line, file);
    }
}



template FilePathExceptionTemplate(string message){
    class FilePathExceptionTemplate: FileException{
        string path;
        
        this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
            super(text(message, "."), next, line, file);
            this.path = path;
        }
        this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
            super(text(message, " \"", path, "\"."), next, line, file);
            this.path = path;
        }
        this(string info, string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
            super(text(message, " \"", path, "\": ", info), next, line, file);
            this.path = path;
        }
    }
}

template FileSrcDstExceptionTemplate(string message){
    class FileSrcDstExceptionTemplate: FileException{
        string src, dst;
        
        this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
            super(text(message, "."), next, line, file);
            this.src = src; this.dst = dst;
        }
        this(string src, string dst, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
            super(text(message, " \"", src, "\" to \"", dst, "\"."), next, line, file);
            this.src = src; this.dst = dst;
        }
        this(string info, string src, string dst, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
            super(text(message, " \"", src, "\" to \"", dst, "\": ", info), next, line, file);
            this.src = src; this.dst = dst;
        }
    }
}
