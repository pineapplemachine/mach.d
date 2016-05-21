module mach.io.filestream;

private:

import core.exception : AssertError;
import core.stdc.stdio : SEEK_CUR, SEEK_END, SEEK_SET;
import std.stdio : File, LockType;

import mach.io.stream : IOStream, StreamSupportMixin;

public:
    
class FileStream : IOStream {
    mixin(StreamSupportMixin(
        "ends", "haslength", "hasposition", "canseek", "canreset"
    ));
    
    File target;
    
    this(File target){
        this.target = target;
    }
    this(string name, in char[] mode = "rb"){
        this(File(name, mode));
    }
    
    static FileStream temp(){
        return new FileStream(File.tmpfile());
    }
    
    ~this(){
        this.close();
    }
    
    void flush(){
        this.target.flush();
    }
    size_t readbuffer(T)(T[] buffer){
        return this.target.rawRead(buffer).length;
    }
    
    void sync(){
        this.target.sync();
    }
    size_t writebuffer(T)(in T[] buffer){
        this.target.rawWrite(buffer);
        return buffer.length;
    }
    
    @property bool eof(){
        return this.target.eof();
    }
    @property size_t length(){
        return cast(size_t) this.target.size();
    }
    @property size_t position(){
        return cast(size_t) this.target.tell();
    }
    @property void position(in size_t index){
        this.seek(index, Seek.Set);
    }
    
    enum Seek : int {
        Cur = SEEK_CUR, /// Relative to the current position in the file
        Set = SEEK_SET, /// Relative to the beginning of the file
        End = SEEK_END, /// Relative to the end of the file (Support dubious)
    }
    void seek(size_t offset, Seek origin = Seek.Set){
        this.target.seek(offset, origin);
    }
    void skip(size_t count){
        this.seek(count, Seek.Cur);
    }
    void reset(){
        this.target.rewind();
    }
    
    enum Lock : LockType {
        Read = LockType.read,
        Write = LockType.readWrite
    }
    bool trylock(Lock type, size_t start = 0, size_t length = 0){
        return this.target.tryLock(type, start, length);
    }
    void lock(Lock type, size_t start = 0, size_t length = 0){
        this.target.lock(type, start, length);
    }
    void unlock(size_t start = 0, size_t length = 0){
        this.target.unlock(start, length);
    }
    
    @property bool active(){
        return this.target.isOpen();
    }
    void close(){
        this.target.close();
    }
}

version(unittest) import mach.error.unit;
unittest{
    tests("FileStream", {
        tests("Read", {
            auto stream = new FileStream(__FILE__, "rb");
            string header = "module mach.io.filestream"; // First line of this file
            char[] buffer = new char[header.length];
            stream.readbuffer(buffer);
            testeq(header, buffer);
            stream.close();
        });
        tests("Write", {
            auto stream = FileStream.temp();
            char[] writebuffer = cast(char[]) "HelloWorld";
            char[5] readbuffer;
            stream.writebuffer(writebuffer);
            stream.reset();
            stream.readbuffer(readbuffer);
            testeq(readbuffer, "Hello");
            stream.readbuffer(readbuffer);
            testeq(readbuffer, "World");
            stream.position = 2;
            stream.readbuffer(readbuffer);
            testeq(readbuffer, "lloWo");
            stream.close();
        });
    });
}
