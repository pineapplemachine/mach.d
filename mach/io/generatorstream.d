module mach.io.generatorstream;

private:

import mach.io.stream : InputStream, StreamSupportMixin;

public:

class GeneratorStream(T) : InputStream {
    mixin(StreamSupportMixin(
        "hasposition", "canreset"
    ));
    
    static alias Generator = T function(in size_t index, in T last);
    
    size_t index;
    Generator generator;
    T initial;
    T last;
    
    this(Generator generator, T initial){
        this.generator = generator;
        this.initial = initial;
        this.reset();
    }
    
    void reset(){
        this.last = initial;
        this.index = 0;
    }
    
    void flush(){
        return;
    }
    T step(){
        return this.last = this.generator(this.index++, this.last);
    }
    size_t readbuffer(X)(X[] buffer){
        size_t bufferlength = buffer.length * X.sizeof;
        ubyte* dst = cast(ubyte*) buffer.ptr;  
        size_t count = 0;
        while(count < bufferlength){
            T value = this.step();
            ubyte* src = cast(ubyte*) &value;
            size_t valueindex = 0;
            while((count < bufferlength) & (valueindex < T.sizeof)){
                dst[count++] = src[valueindex++];
            }
        }
        return count;
    }
    
    @property bool eof(){
        return false;
    }
    @property size_t length(){
        assert(false);
    }
    @property size_t position(){
        return this.index;
    }
    @property void position(in size_t index){
        if(index == 0) this.reset();
        else assert(false);
    }
    
    @property bool active(){
        return true;
    }
    void close(){
        return;
    }
}

version(unittest) import mach.error.test;
unittest{
    tests("GeneratorStream", {
        int[6] buffer;
        tests("Using last argument", {
            auto stream = new GeneratorStream!int(
                (index, last) => (last + 2), -2
            );
            stream.readbuffer(buffer);
            testeq(buffer, [0, 2, 4, 6, 8, 10]);
            stream.readbuffer(buffer);
            testeq(buffer, [12, 14, 16, 18, 20, 22]);
            stream.reset();
            stream.readbuffer(buffer);
            testeq(buffer, [0, 2, 4, 6, 8, 10]);
        });
        tests("Using index argument", {
            auto stream = new GeneratorStream!int(
                (index, last) => (index), 0
            );
            stream.readbuffer(buffer);
            testeq(buffer, [0, 1, 2, 3, 4, 5]);
        });
    });
}
