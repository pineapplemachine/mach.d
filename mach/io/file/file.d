module mach.io.file.file;

private:

import mach.io.stream.filestream : FileStream;

public:



class File{
    static auto open(string path, in char[] mode = "rb"){
        return new FileStream(path, mode);
    }
    static auto read(string path){
        return File.open(path, "rb");
    }
    static auto write(string path){
        return File.open(path, "w+b");
    }
    static auto append(string path){
        return File.open(path, "ab");
    }
    static auto temp(){
        return FileStream.temp();
    }
}
