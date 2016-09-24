module mach.io.file.sys;

private:

import core.stdc.stdio : FILE;
import core.stdc.stdio : SEEK_CUR, SEEK_END, SEEK_SET;
import std.internal.cstring : tempCString;
import mach.error : ErrnoException;
import mach.text : text;
import mach.io.file.common;
import mach.io.file.exceptions;

public:



public import core.stdc.stdio : fclose, fread, fwrite, fflush, fseek, ftell, feof;
public import core.stdc.stdio : fileno, tmpfile, rewind;



auto fopen(string path, in char[] mode = "rb"){
    version(Windows){
        import core.stdc.stdio : cfopen = fopen;
    }else version(Posix){
        import core.sys.posix.stdio : cfopen = fopen;
    }
    auto cpath = path.tempCString!char();
    auto cmode = mode.tempCString!char();
    auto result = cfopen(cpath, cmode);
    if(result is null){
        throw new FileOpenException(path, new ErrnoException);
    }else{
        return result;
    }
}



enum Seek: int{
    Cur = SEEK_CUR, /// Relative to the current position in the file
    Set = SEEK_SET, /// Relative to the beginning of the file
    End = SEEK_END, /// Relative to the end of the file (Support dubious)
}



void fsync(FileHandle file) @trusted in{
    assert(file, "Can't sync unopened file.");
}body{
    version(Windows){
        import core.sys.windows.winbase : FlushFileBuffers, GetLastError;
        auto result = FlushFileBuffers(file.winhandle);
        if(result == 0) throw new FileSyncException(GetLastError());
    }else{
        import core.sys.posix.unistd : fsync;
        auto result = fsync(file.fileno);
        if(result != 0) throw new FileSyncException(result);
    }
}



void rename(string src, string dst){
    auto fsrc = src.tempCString!FSChar();
    auto fdst = dst.tempCString!FSChar();
    version(Windows){
        import core.sys.windows.winbase : MoveFileExW, MOVEFILE_REPLACE_EXISTING;
        if(!MoveFileExW(fsrc, fdst, MOVEFILE_REPLACE_EXISTING)){
            throw new FileRenameException(src, dst);
        }
    }else{
        import core.stdc.stdio : crename = rename;
        if(crename(fsrc, fdst) != 0){
            throw new FileRenameException(src, dst, new ErrnoException);
        }
    }
}



void remove(string path){
    auto fpath = path.tempCString!FSChar();
    version(Windows){
        import core.sys.windows.winbase : DeleteFileW, MOVEFILE_REPLACE_EXISTING;
        if(!DeleteFileW(fpath)){
            throw new FileRemoveException(path);
        }
    }else{
        import core.stdc.stdio : cremove = remove;
        if(cremove(fpath) != 0){
            throw new FileRemoveException(oath, new ErrnoException);
        }
    }
}



bool exists(string path){
    auto fpath = path.tempCString!FSChar();
    version(Windows){
        // https://blogs.msdn.microsoft.com/oldnewthing/20071023-00/?p=24713/
        import core.sys.windows.winbase : GetFileAttributesW;
        import core.sys.windows.winnt : INVALID_FILE_ATTRIBUTES;
        return GetFileAttributesW(fpath) != INVALID_FILE_ATTRIBUTES;
    }else{
        // http://stackoverflow.com/a/230070/3478907
        import core.sys.posix.sys.stat : stat, stat_t;
        stat_t st; return stat(fpath, &st) == 0;
    }
}



//bool isdir(string path){
//}



version(unittest){
    private:
    import std.path;
    import mach.test;
    enum string TestPath = __FILE__.dirName ~ "/sys.txt";
    enum string DelMePath = __FILE__.dirName ~ "/deleteme";
}
unittest{
    tests("Exists", {
        test(exists("."));
        test(exists(TestPath));
        test(!exists("not a real path"));
        test(!exists(DelMePath));
    });
    tests("Sync", {
        auto file = fopen(TestPath, "ab");
        testf(file.feof);
        testeq(file.ftell, 85);
        fsync(file);
        testf(file.feof);
        testeq(file.ftell, 85);
        file.fclose;
        testfail({fsync(file);}); // Attempt to sync closed file
        testfail({fsync(FileHandle.init);}); // Attempt to sync nonexistent file
    });
}
