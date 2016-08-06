module mach.io.file.file;

private:

import mach.io.stream.filestream : FileStream;

public:



/// Provides clean syntax for initializing file streams.
abstract class File{
    /// Open the file at a path.
    static auto open(string path, in char[] mode = "rb"){
        return new FileStream(path, mode);
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
}
