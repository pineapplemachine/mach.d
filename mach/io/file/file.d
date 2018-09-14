deprecated module mach.io.file.file;

private:

import mach.traits : isIterable;
import mach.io.stream : FileStream, write, asrange, asarray;
import mach.io.file.exceptions;
import mach.io.file.stat;
import mach.io.file.sys;

/++ Docs

This module is deprecated. Please use `mach.io.file.path` instead.

+/

public:



/// Provides clean syntax for initializing file streams.
abstract class File{
    /// Open the file at a path.
    static auto open(string path, in char[] mode = "rb"){
        return FileStream(path, mode);
    }
    
    /// Open the file at a path in read mode.
    static auto read(string path){
        return File.open(path, "rb");
    }
    /// Open the file at a path in write mode.
    static auto write(string path){
        return File.open(path, "w+b");
    }
    /// Open the file at a path in append mode.
    static auto append(string path){
        return File.open(path, "ab");
    }
    
    /// Create and open a new temporary file.
    static auto temp(){
        return FileStream.temp();
    }
    
    /// Remove a file.
    static void rename(string src, string dst){
        .rename(src, dst);
    }
    /// Remove the file or directory at a path.
    static void remove(string path){
        if(isfile(path)){
            rmfile(path);
        }else if(isdir(path)){
            rmdir(path);
        }else{
            throw new FileRemoveException(path);
        }
    }
    /// Get whether the path exists.
    static auto exists(string path){
        return .exists(path);
    }
    
    /// Get whether a path points to a file.
    static auto isfile(string path){
        return .isfile(path);
    }
    /// Get whether a path points to a directory.
    static auto isdir(string path){
        return .isdir(path);
    }
    static auto islink(string path){
        return .islink(path);
    }
    
    /// Read data from a file path as a range with elements of type T.
    static auto readfrom(T = char)(string path){
        return read(path).asrange!T;
    }
    /// Read data from a file path as an array with elements of type T.
    static auto readall(T = char)(string path){
        auto file = read(path);
        scope(exit) file.close();
        return file.asarray!T;
    }
    /// Read data from a file path as a string.
    static auto readstring(string path){
        return cast(string) typeof(this).readall(path);
    }
    /// Write some data to a file path.
    static auto writeto(T)(string path, T data) if(isIterable!T){
        auto file = write(path);
        scope(exit) file.close();
        file.write(data);
    }
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("File", {
        // TODO
    });
}