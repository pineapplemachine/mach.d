module mach.io.file.sys;

private:

import core.stdc.stdio : FILE;
import core.stdc.stdio : SEEK_CUR, SEEK_END, SEEK_SET;
import mach.traits : isString;
import mach.error : ErrnoException, SysErrorException;
import mach.text.cstring : tocstring;
import mach.io.file.attributes : Attributes;
import mach.io.file.stat : Stat;
import mach.io.file.common;
import mach.io.file.exceptions;

version(Windows){
    extern (C) nothrow @nogc FILE* _wfopen(in wchar* filename, in wchar* mode);
}
version(CRuntime_Microsoft){
    extern(C) @nogc nothrow int _fseeki64(FileHandle, long, int);
}

public:



version(CRuntime_Microsoft){
    alias off_t = long;
}else version(Windows){
    alias off_t = int;
}else version(Posix){
    public import core.sys.posix.stdio : off_t;
}else{
    static assert(false, "Unsupported platform.");
}



public import core.stdc.stdio : fclose, fread, fwrite, fflush, ftell, feof;
public import core.stdc.stdio : fileno, tmpfile, rewind;



bool fhandlevalid(FileHandle file){
    return file !is null && file.fileno >= 0;
}



void fseek(FileHandle file, long offset, Seek origin = Seek.Set){
    if(file is null) throw new FileSeekException();
    version(CRuntime_Microsoft){
        alias seek = _fseeki64;
    }else version(Windows){
        import core.stdc.stdio : fseek;
        alias seek = fseek;
    }else version(Posix){
        import core.sys.posix.stdio : fseeko;
        alias seek = fseeko;
    }else{
        static assert(false, "Unsupported platform.");
    }
    auto result = seek(file, cast(off_t) offset, origin);
    if(result != 0) throw new FileSeekException(new ErrnoException);
}



auto fopen(Path)(auto ref Path path, in char[] mode = "rb") if(isString!Path){
    auto pathz = path.tocstring!FSChar;
    version(Windows){
        // Get mode as a null-terminated wstring, but don't worry about encoding
        immutable(wchar)[] modez;
        modez.reserve(mode.length + 1);
        foreach(const ch; mode) modez ~= ch;
        modez ~= wchar(0);
        auto filehandle = _wfopen(pathz, modez.ptr);
    }else version(Posix){
        import core.sys.posix.stdio : cfopen = fopen;
        const(char)[] modez = mode ~ '\0';
        auto filehandle = cfopen(pathz, modez.ptr);
    }
    if(filehandle is null){
        throw new FileOpenException(path, new ErrnoException);
    }else{
        version(CRuntime_Microsoft){
            // MSVC libc append ('a') behavior is inconsistent with dmc.
            // See also https://github.com/dlang/phobos/pull/3160
            import core.sys.windows.stat : struct_stat, fstat;
            bool append, update;
            foreach(ch; mode){
                append = append | (ch == 'a');
                update = update | (ch == '+');
            }
            if(append && !update){
                try{
                    fseek(filehandle, 0, Seek.End);
                }catch(FileSeekException e){
                    throw new FileOpenException(path, e);
                }
            }
        }
        return filehandle;
    }
}



enum Seek: int{
    Cur = SEEK_CUR, /// Relative to the current position in the file
    Set = SEEK_SET, /// Relative to the beginning of the file
    End = SEEK_END, /// Relative to the end of the file (Support dubious)
}



void fsync(FileHandle file) @trusted{
    if(!file.fhandlevalid) throw new FileSyncException();
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



void rename(in string src, in string dst){
    auto srcz = src.tocstring!FSChar;
    auto dstz = dst.tocstring!FSChar;
    version(Windows){
        import core.sys.windows.winbase : MoveFileExW, MOVEFILE_REPLACE_EXISTING;
        if(!MoveFileExW(srcz, dstz, MOVEFILE_REPLACE_EXISTING)){
            throw new FileRenameException(src, dst, new SysErrorException);
        }
    }else{
        import core.stdc.stdio : crename = rename;
        if(crename(srcz, dstz) != 0){
            throw new FileRenameException(src, dst, new ErrnoException);
        }
    }
}



void copyfile(in string src, in string dst){
    auto srcz = src.tocstring!FSChar;
    auto dstz = dst.tocstring!FSChar;
    version(Windows){
        import core.sys.windows.winbase : CopyFileW;
        if(!CopyFileW(srcz, dstz, false)){
            throw new FileCopyException(src, dst, new SysErrorException);
        }
    }else{
        import core.stdc.stdio : fopen, fclose, feof, fread, fwrite, fileno;
        import core.sys.posix.sys.stat : stat_t, mode_t, time_t, fstat, fchmod;
        import core.sys.posix.utime : utime, utimbuf;
        // Read source file
        auto infile = fopen(srcz, "rb".tocstring!char);
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
        auto outfile = fopen(dstz, "wb".tocstring!char);
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
        if(fchmod(outfile.fileno, cast(mode_t) stat.st_mode) != 0){
            throw new FileCopyException(
                src, dst, new FileSetPermissionsException(dst, new ErrnoException)
            );
        }
        // Set timestamps
        utimbuf time = void;
        time.actime = cast(time_t) stat.st_atime;
        time.modtime = cast(time_t) stat.st_mtime;
        if(utime(dstz, &time) != 0) throw new FileCopyException(
            src, dst, new FileSetTimeException(dst, new ErrnoException)
        );
    }
}



void rmfile(in string path){
    auto pathz = path.tocstring!FSChar;
    version(Windows){
        import core.sys.windows.winbase : DeleteFileW, MOVEFILE_REPLACE_EXISTING;
        if(!DeleteFileW(pathz)){
            throw new FileRemoveException(path, new SysErrorException);
        }
    }else{
        import core.stdc.stdio : cremove = remove;
        if(cremove(pathz) != 0){
            throw new FileRemoveException(path, new ErrnoException);
        }
    }
}



/// Get whether the given path refers to any existing file.
bool exists(in string path){
    version(Windows){
        // https://blogs.msdn.microsoft.com/oldnewthing/20071023-00/?p=24713/
        return Attributes(path).valid;
    }else{
        // http://stackoverflow.com/a/230070/3478907
        auto pathz = path.tocstring!char;
        import core.sys.posix.sys.stat : stat, stat_t;
        stat_t st; return stat(pathz, &st) == 0;
    }
}



/// Returns true when the path exists and refers to a file.
bool isfile(in string path){
    version(Windows){
        immutable attr = Attributes(path);
        return attr.valid && attr.isfile;
    }else{
        immutable stat = Stat(path);
        return stat.valid && stat.mode.isfile;
    }
}

/// Returns true when the path exists and refers to a directory.
bool isdir(in string path){
    version(Windows){
        immutable attr = Attributes(path);
        return attr.valid && attr.isdir;
    }else{
        immutable stat = Stat(path);
        return stat.valid && stat.mode.isdir;
    }
}

/// Returns true when the path exists and refers to a symbolic link.
bool islink(in string path){
    version(Windows){
        immutable attr = Attributes(path);
        return attr.valid && attr.islink;
    }else{
        immutable stat = Stat(path);
        return stat.valid && stat.mode.islink;
    }
}

/// Get the size of a file in bytes.
/// Throws a `FileSizeException` when the operation fails, probably because
/// the given path did not exist.
auto filesize(in string path){
    version(Posix){
        immutable stat = Stat(path);
        if(stat.valid) return stat.size;
        else throw new FileSizeException(path, new ErrnoException);
    }else{
        try{
            auto file = fopen(path, "rb");
            scope(exit) fclose(file);
            fseek(file, 0, Seek.End);
            return ftell(file);
        }catch(FileException e){
            throw new FileSizeException(path, e);
        }
    }
}



/// Set the current working directory.
void chdir(in string path){
    auto pathz = path.tocstring!FSChar;
    version(Windows){
        import core.sys.windows.winbase : SetCurrentDirectoryW;
        if(!SetCurrentDirectoryW(pathz)){
            throw new FileChangeDirException(path, new SysErrorException);
        }
    }else{
        import core.sys.posix.unistd : cchdir = chdir;
        if(cchdir(pathz) != 0){
            throw new FileChangeDirException(path, new ErrnoException);
        }
    }
}



/// Create a directory.
void mkdir(in string path){
    auto pathz = path.tocstring!FSChar;
    version(Windows){
        // https://msdn.microsoft.com/en-us/library/windows/desktop/aa363855(v=vs.85).aspx
        import core.sys.windows.winbase : CreateDirectoryW;
        if(!CreateDirectoryW(pathz, null)){
            throw new FileMakeDirException(path, new SysErrorException);
        }
    }else{
        import core.sys.posix.sys.stat : cmkdir = mkdir;
        if(cmkdir(pathz, 0x1ff) != 0){
            throw new FileMakeDirException(path, new ErrnoException);
        }
    }
}



/// If the directory doesn't already exist, create it.
void ensuredir(in string path){
    auto pathz = path.tocstring!FSChar;
    version(Windows){
        // https://msdn.microsoft.com/en-us/library/windows/desktop/aa363855(v=vs.85).aspx
        import core.sys.windows.winbase : CreateDirectoryW, GetLastError;
        import core.sys.windows.winerror : ERROR_ALREADY_EXISTS;
        if(!CreateDirectoryW(pathz, null)){
            if(GetLastError() != ERROR_ALREADY_EXISTS){
                throw new FileMakeDirException(path, new SysErrorException);
            }
        }
    }else{
        import core.sys.posix.sys.stat : cmkdir = mkdir;
        import core.stdc.errno : errno, EEXIST, EISDIR;
        if(cmkdir(pathz, 0x1ff) != 0){
            if(errno != EEXIST && errno != EISDIR){
                throw new FileMakeDirException(path, new ErrnoException);
            }
        }
    }
    if(!isdir(path)){
        throw new FileMakeDirException(path);
    }
}



void rmdir(in string path){
    auto pathz = path.tocstring!FSChar;
    version(Windows){
        // https://msdn.microsoft.com/en-us/library/windows/desktop/aa363855(v=vs.85).aspx
        import core.sys.windows.winbase : RemoveDirectoryW;
        if(!RemoveDirectoryW(pathz)){
            throw new FileRemoveDirException(path, new SysErrorException);
        }
    }else{
        import core.sys.posix.unistd : crmdir = rmdir;
        if(crmdir(pathz) != 0){
            throw new FileRemoveDirException(path, new ErrnoException);
        }
    }
}



string currentdir(){
    version(Windows){
        // https://msdn.microsoft.com/en-us/library/windows/desktop/aa364934(v=vs.85).aspx
        import core.sys.windows.winbase : GetCurrentDirectoryW;
        import core.sys.windows.windows : DWORD;
        import mach.sys.memory : malloc, memfree;
        import mach.text.utf : utf8encode;
        import mach.range.asarray : asarray;
        wchar[512] buffer = void;
        auto result = GetCurrentDirectoryW(cast(DWORD) buffer.length, buffer.ptr);
        if(result == 0){
            throw new FileGetCurrentDirException(new SysErrorException);
        }else if(result < buffer.length){
            return buffer[0 .. result].utf8encode.asarray!(immutable char);
        }else{
            auto buffer2 = malloc!wchar(result);
            scope(exit) memfree(buffer2);
            auto result2 = GetCurrentDirectoryW(result, buffer2);
            if(result2 == 0 || result2 >= result){
                throw new FileGetCurrentDirException(new SysErrorException);
            }else{
                return buffer2[0 .. result2].utf8encode.asarray!(immutable char);
            }
        }
    }else{
        import core.sys.posix.unistd : getcwd;
        import mach.sys.memory : memfree;
        import mach.text.cstring : cstringlength;
        auto result = getcwd(null, 0);
        if(result is null) throw new FileGetCurrentDirException(new ErrnoException);
        scope(exit) memfree(result);
        return cast(string) result[0 .. cstringlength(result)].idup;
    }
}



// TODO
//auto exepath(){
//}



private version(unittest){
    import std.path;
    import mach.test;
    import mach.error.mustthrow : mustthrow;
    enum string CurrentPath = __FILE_FULL_PATH__.dirName;
    enum string TestPath = CurrentPath ~ "/sys.txt";
    enum string FakePath1 = CurrentPath ~ "/nope_not_a_real_file";
    enum string FakePath2 = CurrentPath ~ "/nope_not_a_real_file.txt";
    enum string UnicodePath = CurrentPath ~ "/file/traverse/unicodeツ.txt";
}

unittest{ /// Exists
    assert(exists("."));
    assert(exists(TestPath));
    assert(!exists(""));
    assert(!exists(FakePath1));
    assert(!exists(FakePath2));
}

unittest{ /// Handle is valid
    assert(!fhandlevalid(null));
    auto file = fopen(TestPath, "ab");
    assert(fhandlevalid(file));
    file.fclose;
    assert(!fhandlevalid(file));
}

unittest{ /// Sync
    auto file = fopen(TestPath, "ab");
    assert(!file.feof);
    assert(file.ftell == 85);
    fsync(file);
    assert(!file.feof);
    assert(file.ftell == 85);
    file.fclose;
    mustthrow!FileSyncException({
        fsync(file); // Attempt to sync closed file
    });
    mustthrow!FileSyncException({
        fsync(null); // Attempt to sync invalid file
    });
}

unittest{ /// File size
    assert(filesize(TestPath) == 85);
    mustthrow!FileSizeException({
        filesize(FakePath1);
    });
    mustthrow!FileSizeException({
        filesize(FakePath2);
    });
}

unittest{ /// Attributes
    assert(isfile(TestPath));
    assert(!isfile(CurrentPath));
    assert(isdir(CurrentPath));
    assert(!isdir(TestPath));
    assert(!isfile(FakePath1));
    assert(!isdir(FakePath1));
    assert(!isfile(FakePath2));
    assert(!isdir(FakePath2));
    assert(!isfile(""));
    assert(!isdir(""));
}

unittest{ /// Get/set current directory
    version(Windows) enum ChPath = "C:\\Program Files";
    else enum ChPath = "/usr/bin";
    if(exists(ChPath)){
        chdir(ChPath);
        assert(currentdir() == ChPath);
    }else{
        import mach.io.stdio : stdio;
        stdio.errorln(
            "Unable to test chdir and currentdir because path ",
            "\"", ChPath, "\" does not exist."
        );
    }
}
