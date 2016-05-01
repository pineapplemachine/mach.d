module mach.io.stream;

private:

public:

/+

    Some clever operator overloads:
    
    int i = ~stream; // read one unit
    int[] i = 5 ~stream; // read many units
    stream ~= 1; // write one unit
    stream ~= [1, 2, 3]; // write many units

+/

interface Stream{
    static bool ends = false;
    @property bool eof();
    
    static bool haslength = false;
    @property size_t length();
    
    static bool hasposition = false;
    @property void position(in size_t index);
    
    static bool canseek = false;
    @property size_t position();
    void reset();
    
    @property bool active();
    void close();
    
    final bool opCast(T: bool)(){
        return this.active & !this.eof;
    }
}

interface InputStream : Stream{
    void flush();
    size_t readbuffer(T)(T[] buffer);
}
interface OutputStream : Stream{
    void sync();
    size_t writebuffer(T)(in T[] buffer);
}

interface IOStream : InputStream, OutputStream {}








