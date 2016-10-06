module mach.io.stream.filestream;

private:

import mach.error : enforceerrno;
import mach.io.file.sys : FileHandle, Seek;
import mach.io.file.sys : fopen, fclose, fread, fwrite, fflush, fsync, fseek, ftell, feof, tmpfile, rewind;
import mach.io.file.stat : Stat;
import mach.io.stream.stream : IOStream;

public:



class FileStream: IOStream{
    alias Seek = .Seek;
    
    static enum bool haseof = true;
    static enum bool haslength = true;
    static enum bool hasposition = true;
    static enum bool canseek = true;
    static enum bool canskip = true;
    static enum bool canreset = true;
    
    FileHandle target;
    
    this(FileHandle target){
        this.target = target;
    }
    this(string path, in char[] mode = "rb"){
        this(fopen(path, mode));
    }
    
    static FileStream temp(){
        return new FileStream(
            enforceerrno(tmpfile(), "Failed to create temporary file.")
        );
    }
    
    ~this(){
        if(this.active) this.close();
    }
    
    override void flush() @trusted in{
        assert(this.active);
    }body{
        enforceerrno(fflush(this.target) == 0);
    }
    
    override size_t readbufferraw(void* buffer, size_t size, size_t count) in{
        assert(this.active);
    }body{
        return fread(buffer, size, count, this.target);
    }
    
    override void sync() in{
        assert(this.active);
    }body{
        fsync(this.target);
    }
    
    override size_t writebufferraw(void* buffer, size_t size, size_t count) in{
        assert(this.active);
    }body{
        return fwrite(buffer, size, count, this.target);
    }
    
    override @property bool eof() in{
        assert(this.active);
    }body{
        return cast(bool) feof(this.target);
    }
    override @property size_t length() in{
        assert(this.canseek && this.hasposition);
    }body{
        return this.active ? cast(size_t) this.stat.size : 0;
    }
    override @property size_t position() in{
        assert(this.active);
    }body{
        auto tell = ftell(this.target);
        enforceerrno(tell >= 0);
        return cast(size_t) tell;
    }
    override @property void position(in size_t index) in{
        assert(this.active);
    }body{
        this.seek(index, Seek.Set);
    }
    
    void seek(in size_t offset, in Seek origin = Seek.Set) in{
        assert(this.active);
    }body{
        enforceerrno(fseek(this.target, offset, origin) == 0);
    }
    override size_t skip(in size_t count) in{
        assert(this.active);
    }body{
        auto before = ftell(this.target);
        enforceerrno(before >= 0);
        this.seek(count, Seek.Cur);
        auto after = ftell(this.target);
        enforceerrno(after >= 0);
        return after - before;
    }
    override void reset() in{
        assert(this.active);
    }body{
        rewind(this.target);
    }
    
    override @property bool active(){
        return this.target !is null;
    }
    override void close() in{
        assert(this.active);
    }body{
        enforceerrno(fclose(this.target) == 0);
        this.target = null;
    }
    
    @property auto stat(){
        return Stat(this.target);
    }
}



version(unittest){
    private:
    import std.path;
    import mach.error.unit;
    enum string TestPath = __FILE__.dirName ~ "/filestream.txt";
}
unittest{
    tests("FileStream", {
        tests("Read", {
            auto stream = new FileStream(TestPath, "rb");
            string header = "I am used to validate unittests.";
            char[] buffer = new char[header.length];
            stream.readbuffer(buffer);
            testeq(header, buffer);
            testf(stream.eof);
            testeq(stream.position, header.length);
            testeq(stream.length, 85);
            stream.close();
        });
        tests("Write", {
            auto stream = FileStream.temp();
            char[] writebuffer = cast(char[]) "HelloWorld";
            char[5] readbuffer;
            stream.writebuffer(writebuffer);
            stream.write('X');
            stream.write("XX");
            stream.reset();
            stream.readbuffer(readbuffer);
            testeq(readbuffer, "Hello");
            stream.readbuffer(readbuffer);
            testeq(readbuffer, "World");
            stream.position = 2;
            stream.readbuffer(readbuffer);
            testeq(readbuffer, "lloWo");
            stream.readbuffer(readbuffer);
            testeq(readbuffer, "rldXX");
            testeq(stream.read!char, 'X');
            fail({stream.read!char;});
            stream.close();
        });
    });
}
