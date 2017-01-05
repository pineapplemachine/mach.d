module mach.traits.hash;

private:

//

public:



/// Determine whether it's possible to get the hash of some type.
enum canHash(alias T) = canHash!(typeof(T));
/// ditto
template canHash(T){
    enum bool canHash = is(typeof({
        T value = T.init;
        size_t hash = typeid(value).getHash(&value);
    }));
}



/// Get the hash of some value.
auto hash(T)(auto ref T value) if(canHash!T){
    static if(is(typeof({size_t h = value.toHash();}))){
        return value.toHash();
    }else{
        size_t gethash() @trusted{return typeid(value).getHash(&value);}
        return gethash();
    }
}



unittest{
    string str;
    static assert(canHash!str);
    static assert(canHash!string);
    static assert(canHash!int);
    static assert(!canHash!void);
}

unittest{
    string str0 = "hello world";
    string str1 = "hello world";
    string str2 = "hello worlds";
    assert(str0.hash == str1.hash);
    assert(str0.hash != str2.hash);
    assert(0.hash == 0.hash);
    assert(0.hash != 1.hash);
}
