module mach.io.arraystream;

private:

import mach.io.stream : IOStream, StreamSupportMixin;

public:

class ArrayStream(T) : IOStream {
    mixin(StreamSupportMixin(
        "ends", "haslength", "hasposition", "canseek", "canreset"
    ));
    
    size_t index;
    T[] target;
    
    this(T[] target){
        this(target, 0);
    }
    this(T[] target, size_t index = 0){
        this.target = target;
        this.index = index;
    }
    
    void flush(){
        return;
    }
    size_t readbuffer(X)(X[] buffer){
        size_t bufferlength = buffer.length * X.sizeof;
        ubyte* src = cast(ubyte*) this.target.ptr;
        ubyte* dst = cast(ubyte*) buffer.ptr;
        size_t count = 0;
        while((this.index < this.length) & (count < bufferlength)){
            dst[count++] = src[this.index++];
        }
        return count;
    }
    
    void sync(){
        return;
    }
    size_t writebuffer(X)(in X[] buffer){
        size_t bufferlength = buffer.length * X.sizeof;
        ubyte* src = cast(ubyte*) buffer.ptr;
        ubyte* dst = cast(ubyte*) this.target.ptr;
        size_t count = 0;
        while((this.index < this.length) & (count < bufferlength)){
            dst[this.index++] = src[count++];
        }
        return count;
    }
    
    @property bool eof(){
        return this.index >= this.length;
    }
    /++
        Get length of target array in bytes. By way of explanation:
        ArrayStream!ubyte(array).length == array.length;
        ArrayStream!int(array).length == array.length * 4;
    +/
    @property size_t length(){
        assert(this.active);
        return this.target.length * T.sizeof;
    }
    @property size_t position(){
        return this.index;
    }
    @property void position(in size_t index){
        assert((index >= 0) & (index < this.length));
        this.index = index;
    }
    void reset(){
        this.index = 0;
    }
    
    @property bool active(){
        return this.target !is null;
    }
    void close(){
        this.target = null;
    }
}

version(unittest) import mach.error.test;
unittest{
    tests("ArrayStream", {
        ubyte[6] target;
        auto stream = new ArrayStream!ubyte(target);
        
        stream.position = 1;
        ubyte[] writedata = [1, 2, 3];
        while(!stream.eof) stream.writebuffer(writedata);
        testeq(target, [0, 1, 2, 3, 1, 2]);
        
        ubyte[3] readdata;
        stream.position = 0;
        stream.readbuffer(readdata);
        testeq(readdata, [0, 1, 2]);
        stream.readbuffer(readdata);
        testeq(readdata, [3, 1, 2]);
    });
}
