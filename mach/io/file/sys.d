module mach.io.file.sys;

private:

import core.stdc.stdio : FILE;
import core.stdc.stdio : SEEK_CUR, SEEK_END, SEEK_SET;
import std.internal.cstring : tempCString;
import mach.error : ErrnoException, SysErrorException;
import mach.text : text;
import mach.io.file.attributes : Attributes;
import mach.io.file.stat : Stat;
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
        import core.sys.windows.winbase : FlushFileBuffers;
        auto result = FlushFileBuffers(file.winhandle);
        if(result == 0) throw new FileSyncException(new SysErrorException);
    }else{
        import core.sys.posix.unistd : fsync;
        auto result = fsync(file.fileno);
        if(result != 0) throw new FileSyncException(new ErrnoException);
    }
}



void rename(string src, string dst){
    auto fsrc = src.tempCString!FSChar();
    auto fdst = dst.tempCString!FSChar();
    version(Windows){
        import core.sys.windows.winbase : MoveFileExW, MOVEFILE_REPLACE_EXISTING;
        if(!MoveFileExW(fsrc, fdst, MOVEFILE_REPLACE_EXISTING)){
            throw new FileRenameException(src, dst, new SysErrorException);
        }
    }else{
        import core.stdc.stdio : crename = rename;
        if(crename(fsrc, fdst) != 0){
            throw new FileRenameException(src, dst, new ErrnoException);
        }
    }
}



void copy(string src, string dst){
    auto fsrc = src.tempCString!FSChar();
    auto fdst = dst.tempCString!FSChar();
    version(Windows){
        import core.sys.windows.winbase : CopyFileW;
        if(!CopyFileW(fsrc, fdst, false)){
            throw new FileCopyException(src, dst, new SysErrorException);
        }
    }else{
        import core.stdc.stdio : fopen, fclose, feoef, fread, fwrite, fileno;
        import core.sys.posix.sys.stat : stat_t, mode_t, fstat, fchmod;
        import core.sys.posix.sys.utime : utime, utimbuf;
        // Read source file
        auto infile = fopen(fsrc, ['r', 'b']);
        if(infile is null) throw new FileCopyException(
            src, dst, new FileOpenException(src, new ErrnoException)
        );
        scope(exit) fclose(infile);
        // Get source file stat
        stat_t stat;
        if(fstat(infile.fileno, &stat) != 0) throw new FileCopyException(
            src, dst, new FileStatException(src, new ErrnoException)
        );
        // Write destination file
        auto outfile = fopen(fdst, ['w', 'b']);
        if(outfile is null) throw new FileCopyException(
            src, dst, new FileOpenException(dst, new ErrnoException)
        );
        scope(exit) fclose(outfile);
        scope(failure) rmfile(dst);
        // Read bytes from input, write to output
        ubyte[1024] buffer;
        while(!feof(infile)){
            auto count = fread(cast(void*) buffer.ptr, ubyte.sizeof, buffer.length, infile);
            if(count) fwrite(cast(void*) buffer.ptr, ubyte.sizeof, count, outfile);
        }
        // Set permissions
        if(fchmod(outfile, cast(mode_t) stat.st_mode) != 0){
            throw new FileCopyException(
                src, dst, new FileSetPermissionsException(dst, new ErrnoException)
            );
        }
        // Set timestamps
        utimbuf time = void;
        time.actime = cast(time_t) stat.st_atime;
        time.modtime = cast(time_t) stat.st_mtime;
        if(utime(dst, time) != -1) throw new FileCopyException(
            src, dst, new FileSetTimeException(dst, new ErrnoException)
        );
    }
}



void rmfile(string path){
    auto fpath = path.tempCString!FSChar();
    version(Windows){
        import core.sys.windows.winbase : DeleteFileW, MOVEFILE_REPLACE_EXISTING;
        if(!DeleteFileW(fpath)){
            throw new FileRemoveException(path, new SysErrorException);
        }
    }else{
        import core.stdc.stdio : cremove = remove;
        if(cremove(fpath) != 0){
            throw new FileRemoveException(path, new ErrnoException);
        }
    }
}



bool exists(string path){
    version(Windows){
        // https://blogs.msdn.microsoft.com/oldnewthing/20071023-00/?p=24713/
        return Attributes(path).valid;
    }else{
        // http://stackoverflow.com/a/230070/3478907
        auto fpath = path.tempCString!FSChar();
        import core.sys.posix.sys.stat : stat, stat_t;
        stat_t st; return stat(fpath, &st) == 0;
    }
}



bool isfile(string path){
    version(Windows) return Attributes(path).isfile;
    else return Stat(path).mode.isfile;
}

bool isdir(string path){
    version(Windows) return Attributes(path).isdir;
    else return Stat(path).mode.isdir;
}

bool islink(string path){
    version(Windows) return Attributes(path).islink;
    else return Stat(path).mode.islink;
}



/// Set the current working directory.
void chdir(string path){
    auto fpath = path.tempCString!FSChar();
    version(Windows){
        import core.sys.windows.winbase : SetCurrentDirectoryW;
        if(!SetCurrentDirectoryW(fpath)){
            throw new FileChangeDirException(path, new SysErrorException);
        }
    }else{
        import core.sys.posix.unistd : cchdir = chdir;
        if(cchdir(fpath) != 0){
            throw new FileChangeDirException(path, new ErrnoException);
        }
    }
}



/// Create a directory.
void mkdir(string path){
    auto fpath = path.tempCString!FSChar();
    version(Windows){
        // https://msdn.microsoft.com/en-us/library/windows/desktop/aa363855(v=vs.85).aspx
        import core.sys.windows.winbase : CreateDirectoryW;
        if(!CreateDirectoryW(fpath, null)){
            throw new FileMakeDirException(path, new SysErrorException);
        }
    }else{
        import core.sys.posix.sys.stat : cmkdir = mkdir;
        if(cmkdir(fpath, 0x1ff) != 0){
            throw new FileMakeDirException(path, new ErrnoException);
        }
    }
}



/// If the directory doesn't already exist, create it.
void ensuredir(string path){
    auto fpath = path.tempCString!FSChar();
    version(Windows){
        // https://msdn.microsoft.com/en-us/library/windows/desktop/aa363855(v=vs.85).aspx
        import core.sys.windows.winbase : CreateDirectoryW, GetLastError;
        import core.sys.windows.winerror : ERROR_ALREADY_EXISTS;
        if(!CreateDirectoryW(fpath, null)){
            if(GetLastError() != ERROR_ALREADY_EXISTS){
                throw new FileMakeDirException(path, new SysErrorException);
            }
        }
    }else{
        import core.sys.posix.sys.stat : cmkdir = mkdir;
        import core.stdc.errno : errno, EEXIST, EISDIR;
        if(cmkdir(fpath, 0x1ff) != 0){
            if(errno != EEXIST && errno != EISDIR){
                throw new FileMakeDirException(path, new ErrnoException);
            }
        }
    }
    if(!isdir(path)){
        throw new FileMakeDirException(path);
    }
}



void rmdir(string path){
    auto fpath = path.tempCString!FSChar();
    version(Windows){
        // https://msdn.microsoft.com/en-us/library/windows/desktop/aa363855(v=vs.85).aspx
        import core.sys.windows.winbase : RemoveDirectoryW;
        if(!RemoveDirectoryW(fpath)){
            throw new FileRemoveDirException(path, new SysErrorException);
        }
    }else{
        import core.sys.posix.sys.stat : crmdir = rmdir;
        if(crmdir(fpath) != 0){
            throw new FileRemoveDirException(path, new ErrnoException);
        }
    }
}



string currentdir(){
    version(Windows){
        // https://msdn.microsoft.com/en-us/library/windows/desktop/aa364934(v=vs.85).aspx
        import core.sys.windows.winbase : GetCurrentDirectoryW;
        import core.sys.windows.windows : DWORD;
        import core.stdc.stdlib : malloc, free;
        import mach.text.utf : utfencode;
        
        auto toutf8(FSChar[] buffer){
            // Verify assumption with which this function was written
            static assert(is(FSChar == wchar));
            // Note that: Length of result will never be less than the buffer,
            // and never be more than twice the buffer's length. Most common
            // case can be expected to be 1:1.
            immutable(char)[] result;
            result.reserve(buffer.length);
            foreach(ch; buffer.utfencode){
                if(result.length == buffer.length){
                    result.reserve(buffer.length * 2);
                }
                result ~= ch;
            }
            return cast(string) result;
        }
        
        FSChar[512] buffer = void;
        auto result = GetCurrentDirectoryW(cast(DWORD) buffer.length, buffer.ptr);
        if(result == 0){
            throw new FileGetCurrentDirException(new SysErrorException);
        }else if(result < buffer.length){
            return toutf8(buffer[0 .. result]);
        }else{
            auto buffer2 = cast(FSChar*) malloc(FSChar.sizeof * result);
            scope(exit) free(buffer2);
            auto result2 = GetCurrentDirectoryW(result, buffer2);
            if(result2 == 0 || result2 >= result){
                throw new FileGetCurrentDirException(new SysErrorException);
            }else{
                return toutf8(buffer2[0 .. result2]);
            }
        }
    }else{
        import core.sys.posix.unistd : getcwd;
        import core.stdc.stdlib : free;
        import core.stdc.string : strlen;
        auto result = getcwd(null, 0);
        if(result is null) throw new FileGetCurrentDirException(new ErrnoException);
        scope(exit) free(result);
        return cast(string) result[0 .. strlen(result)].idup;
    }
}



// TODO
//auto exepath(){
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
