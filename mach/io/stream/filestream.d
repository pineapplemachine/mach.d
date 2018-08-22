module mach.io.stream.filestream;

private:

import mach.error : ErrnoException;
import mach.io.file.sys : FileHandle, Seek;
import mach.io.file.sys : fopen, fclose, fread, fwrite, fflush;
import mach.io.file.sys : fsync, fseek, ftell, tmpfile, rewind;
import mach.io.file.stat : Stat;
import mach.io.stream.exceptions;
import mach.io.file.exceptions : FileSeekException;

import core.stdc.stdio : fgetc, ungetc, EOF;

public:



struct FileStream{
    alias Seek = .Seek;
    alias Handle = FileHandle;
    
    Handle target;
    
    this(Handle target){
        this.target = target;
    }
    this(string path, in char[] mode = "rb"){
        this(fopen(path, mode));
    }
    
    static FileStream temp(){
        auto file = tmpfile();
        if(!file) throw new StreamException(
            "Failed to create temporary file", new ErrnoException
        );
        return FileStream(file);
    }
    
    @property bool active(){
        return this.target !is null;
    }
    
    size_t readbufferv(void* buffer, size_t size, size_t count) in{
        assert(this.active);
    }body{
        return size * fread(buffer, size, count, this.target);
    }
    size_t writebufferv(void* buffer, size_t size, size_t count) in{
        assert(this.active);
    }body{
        return size * fwrite(buffer, size, count, this.target);
    }
    
    void flush() @trusted in{assert(this.active);} body{
        auto result = fflush(this.target);
        if(result != 0) throw new StreamFlushException(new ErrnoException);
    }
    void sync() in{assert(this.active);} body{
        fsync(this.target);
    }
    
    @property size_t length() in{assert(this.active);} body{
        try{
            auto pos = this.position;
            scope(exit) this.position = pos;
            this.seek(0, Seek.End);
            return this.position;
        }catch(StreamException e){
            throw new StreamException("Failed to get stream length.", e);
        }
    }
    
    @property bool eof() in{assert(this.active);} body{
        // https://stackoverflow.com/a/2082772/4099022
        // https://stackoverflow.com/a/6283787/4099022
        auto const c = fgetc(this.target);
        ungetc(c, this.target);
        return c == EOF;
    }
    
    @property size_t position() in{assert(this.active);} body{
        auto tell = ftell(this.target);
        if(tell < 0) throw new StreamTellException(new ErrnoException);
        return cast(size_t) tell;
    }
    @property void position(in size_t index) in{assert(this.active);} body{
        this.seek(index, Seek.Set);
    }
    
    void seek(in size_t offset, in Seek origin = Seek.Set) in{
        assert(this.active);
    }body{
        try{
            fseek(this.target, offset, origin);
        }catch(FileSeekException e){
            throw new StreamSeekException(e);
        }
    }
    
    size_t skip(in size_t count) in{assert(this.active);} body{
        try{
            auto before = ftell(this.target);
            if(before < 0) throw new StreamTellException(new ErrnoException);
            this.seek(count, Seek.Cur);
            auto after = ftell(this.target);
            if(after < 0) throw new StreamTellException(new ErrnoException);
            return after - before;
        }catch(StreamException e){
            throw new StreamSkipException(e);
        }
    }
    
    void reset() in{assert(this.active);} body{
        rewind(this.target);
    }
    
    void close() in{assert(this.active);} body{
        auto result = fclose(this.target);
        if(result != 0) throw new StreamCloseException(new ErrnoException);
        this.target = null;
    }
    
    @property auto stat(){
        return Stat(this.target);
    }
}



version(unittest){
    private:
    import std.path;
    import mach.test;
    import mach.io.stream.io;
    import mach.io.stream.templates;
    enum string TestPath = __FILE_FULL_PATH__.dirName ~ "/filestream.txt";
}
unittest{
    tests("File stream", {
        static assert(isIOStream!FileStream);
        tests("Read", {
            auto stream = FileStream(TestPath, "rb");
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
            stream.write(int(0x12345678));
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
            testeq(stream.read!int, 0x12345678);
            testeq(true, stream.eof);
            testfail({stream.read!char;});
            stream.close();
        });
    });
}
