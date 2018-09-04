module mach.text.fixedstring;

private:

import mach.traits.qualifiers : Unqual;

/++ Docs

This module implements a fixed-length null-terminated string type.
It supports pretty much any of the operations that you would expect from
a string type.

+/

unittest{ /// Example
    FixedString!16 hello = "Hello World";
    static assert(hello.size == 16);
    assert(hello.length == 11);
    assert(hello == "Hello World");
}

public:

/// Null-terminated string type stored in a fixed-length buffer.
struct FixedString(size_t BufferSize){
    enum size = BufferSize;
    
    // Initializes data to all null chars, unlike the default char[N]
    // initializer. Which is weird but whatever.
    char[size] data = cast(char[size]) (ubyte[size]).init;
    
    this(size_t otherSize)(in FixedString!otherSize other){
        this = other;
    }
    this(T)(in T[] str) if(is(Unqual!T == char)){
        this = str;
    }
    
    /// Get the number of characters in the string, i.e. up to the first
    /// null terminator or until the end of the buffer.
    @property size_t length() const{
        for(size_t i = 0; i < size; i++){
            if(this.data[i] == 0){
                return i;
            }
        }
        return size;
    }
    
    /// Dollar length operator override.
    size_t opDollar() const{
        return this.length;
    }
    
    /// Get a normal string value that is equivalent to this one.
    string toString() const{
        for(size_t i = 0; i < size; i++){
            if(this.data[i] == 0){
                return cast(string) this.data[0 .. i];
            }
        }
        return cast(string) this.data;
    }
    
    /// Remove and return the last character in the string.
    /// Fails if the string is empty.
    char pop(){
        const size_t length = this.length;
        assert(length > 0, "Cannot pop empty string.");
        const char ch = this.data[length];
        this.data[length] = 0;
        return ch;
    }
    
    /// Compare this value to a string.
    bool opEquals(T)(in T[] str) const if(is(Unqual!T == char)){
        if(str.length > size){
            return false;
        }
        size_t i = void;
        for(i = 0; i < size && i < str.length; i++){
            if(this.data[i] != str[i]){
                return false;
            }
        }
        return i == size || this.data[i] == 0;
    }
    /// Compare this value to another fixed-length string.
    bool opEquals(size_t otherSize)(in FixedString!otherSize other) const{
        enum lowerSize = otherSize < this.size ? otherSize : this.size;
        for(size_t i = 0; i < lowerSize; i++){
            if(this.data[i] != other.data[i]){
                return false;
            }else if(this.data[i] == 0 && other.data[i] == 0){
                return true;
            }
        }
        static if(otherSize < this.size){
            return this.data[lowerSize] == 0;
        }else static if(otherSize > this.size){
            return other.data[lowerSize] == 0;
        }else{
            return true;
        }
    }
    
    /// Get the character at an index.
    /// Access past the string length is safe; access past the size is unsafe.
    /// Access past the length with normally return a null character;
    /// this should only be different if manually set to something else.
    char opIndex(in size_t index) const{
        assert(index >= 0 && index < size);
        return this.data[index];
    }
    /// Set the character at an index.
    void opIndexAssign(in char ch, in size_t index){
        assert(index >= 0 && index < size);
        this.data[index] = ch;
    }
    
    /// Get a slice of this string as another fixed-length string.
    typeof(this) opSlice(in size_t low, in size_t high) const{
        assert(low >= 0 && high >= low && size >= high, "Invalid slice.");
        return typeof(this)(this.data[low .. high]);
    }
    
    /// Assign the contents of this string to equal another string.
    /// If the string is too long, the operation will fail.
    void opAssign(T)(in T[] str) if(is(Unqual!T == char)){
        assert(str.length <= size, "Not enough space.");
        this.data[0 .. str.length] = str[0 .. str.length];
        for(size_t i = str.length; i < size; i++){
            this.data[i] = 0;
        }
    }
    /// Assign the contents of this string to equal another FixedString.
    /// If the string is too long, the operation will fail.
    void opAssign(size_t otherSize)(in FixedString!otherSize other){
        enum lowerSize = otherSize < this.size ? otherSize : this.size;
        for(size_t i = 0; i < lowerSize; i++){
            this.data[i] = other.data[i];
        }
        static if(otherSize < this.size){
            for(size_t j = lowerSize; j < this.size; j++){
                this.data[j] = 0;
            }
        }else static if(otherSize > this.size){
            assert(other.data[this.size] == 0, "Not enough space.");
        }
    }
    
    /// Append a character to the end of the string.
    /// The function fails if there isn't enough room for the new character.
    void opOpAssign(string op: "~")(in char ch){
        const size_t length = this.length;
        assert(length < size, "Not enough space.");
        this.data[length] = ch;
    }
    /// Append another string onto the end of this one.
    /// Fails if there isn't enough room.
    void opOpAssign(string op: "~", T)(in T[] str) if(is(Unqual!T == char)){
        const size_t length = this.length;
        assert(length + str.length <= size, "Not enough space.");
        this.data[length .. length + str.length] = str;
    }
    /// Append another fixed-length string onto the end of this one.
    /// Fails if there isn't enough room.
    void opOpAssign(string op: "~", size_t otherSize)(in FixedString!otherSize other){
        const size_t thisLength = this.length;
        const size_t otherLength = other.length;
        assert(thisLength + otherLength <= size, "Not enough space.");
        this.data[thisLength .. thisLength + otherLength] = other.data[0 .. otherLength];
    }
    
    bool opCast(T: bool)(){
        return this.length > 0;
    }
    T opCast(T: inout char[size])(){
        return this.data;
    }
    T opCast(T: inout char[])(){
        return cast(T) this.data[0 .. this.length];
    }
}



// Test buffer initialization to all null chars
unittest{
    FixedString!8 str;
    for(size_t i = 0; i < 8; i++){
        assert(str[i] == 0);
    }
}

// Test basic assignment and length
unittest{
    FixedString!8 str = "TEST";
    assert(str.length == 4);
    static assert(str.size == 8);
}

// Test opIndex
unittest{
    FixedString!8 str = "TEST";
    assert(str[0] == 'T');
    assert(str[1] == 'E');
    assert(str[2] == 'S');
    assert(str[3] == 'T');
    assert(str[4] == 0);
}

// Test opEquals
unittest{
    FixedString!8 str = "TEST";
    assert(str == "TEST");
    assert(str == str);
    assert(str == FixedString!4("TEST"));
    assert(str == FixedString!6("TEST"));
    assert(str == FixedString!8("TEST"));
    assert(str == FixedString!9("TEST"));
    assert(str == FixedString!20("TEST"));
}

// Test toString
unittest{
    FixedString!8 str = "TEST";
    assert(str.toString() == "TEST");
    str = "Test    ";
    assert(str.toString() == "Test    ");
}

// Test opIndexAssign
unittest{
    FixedString!8 str = "TEST";
    assert(str == "TEST");
    str[0] = 'W';
    assert(str == "WEST");
    assert(str.length == 4);
    str[3] = 0;
    assert(str == "WES");
    assert(str.length == 3);
    str[3] = 'L';
    assert(str == "WESL");
    assert(str.length == 4);
}

// Test opSlice
unittest{
    FixedString!16 str = "Hello World";
    typeof(str) slice = str[0 .. 5];
    assert(slice == "Hello");
    assert(slice[2 .. 5] == "llo");
    assert(str[6 .. $] == "World");
}

// Test opAssign for various inputs
unittest{
    FixedString!8 str;
    str = "test";
    assert(str == "test");
    str = ['o', 'k'];
    assert(str == "ok");
    str = FixedString!4("yes");
    assert(str == "yes");
    str = FixedString!20("hello");
    assert(str == "hello");
}

// Test opOpAssign (~=)
unittest{
    FixedString!16 str = "";
    assert(str.length == 0);
    str ~= "Hello";
    assert(str == "Hello");
    str ~= ' ';
    assert(str == "Hello ");
    str ~= FixedString!6("World");
    assert(str == "Hello World");
    str ~= FixedString!1("!");
    assert(str == "Hello World!");
}

// Test opCast(T: bool)
unittest{
    assert(cast(bool) FixedString!8("") == false);
    assert(cast(bool) FixedString!8("yes") == true);
}

// Test opCast(T: char[])
unittest{
    assert(cast(string) FixedString!8("test") == "test");
    assert(cast(char[]) FixedString!8("test") == "test");
    assert(cast(char[8]) FixedString!8("test") == "test\0\0\0\0");
}
