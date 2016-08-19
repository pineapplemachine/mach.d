module mach.text.parse.ini.properties;

private:

import std.conv : to;
import std.format : format;
import mach.traits : isIterableOf, Returns, isCallableWith;
import mach.range : pluck, each, map, flatten, sum, any, find, filter, skipindexes, asarray;
import mach.error : enforcebounds;
import mach.text.parse.ini.exceptions : IniException;

public:



class IniProperty{
    string key;
    string strvalue;
    this(IniProperty property){
        this(property.key, property.value);
    }
    this(T = string)(string key, T value){
        this.key = key;
        this.value = value;
    }
    @property T value(T = string)(){
        return this.strvalue.to!T;
    }
    @property void value(T = string)(T value){
        this.strvalue = value.to!string;
    }
    override string toString() const{
        return this.key ~ ": " ~ this.strvalue;
    }
    override bool opEquals(Object object) const{
        if(IniProperty property = cast(IniProperty) object){
            return this.key == property.key && this.strvalue == property.strvalue;
        }else{
            return false;
        }
    }
    bool opEquals(in string value) const{
        return this.strvalue == value;
    }
}



class IniProperties{
    static class PropertyException: IniException{
        this(
            string message, Throwable next = null,
            size_t line = __LINE__, string file = __FILE__
        ){
            super(message, next, line, file);
        }
    }
    static class InvalidKeyException: PropertyException{
        string key;
        this(string key, size_t line = __LINE__, string file = __FILE__){
            this.key = key;
            super("Invalid key \"%s\".".format(key), null, line, file);
        }
    }
    static class InvalidPropertyException: PropertyException{
        IniProperty property;
        @property string key(){return property.key;}
        @property T value(T = string)(){return property.value!T;}
        this(IniProperty property, size_t line = __LINE__, string file = __FILE__){
            this.property = property;
            super("Invalid property \"%s\".".format(property), null, line, file);
        }
    }
    static class IndexBoundsException: PropertyException{
        size_t index;
        this(size_t index, size_t line = __LINE__, string file = __FILE__){
            this.index = index;
            super("Index %s is out of bounds.".format(index), null, line, file);
        }
        static void enforce(
            size_t index, size_t low, size_t high,
            size_t line = __LINE__, string file = __FILE__
        ){
            if((index < low) | (index >= high)) throw new IndexBoundsException(index);
        }
    }
    
    /// For accessing properties by name with reasonable lookup time
    IniProperty[][string] map;
    /// Maintains order for properties.
    IniProperty[] list;
    /// Internal flag for whether the properties are ordered.
    bool isordered;
    
    this(bool ordered = true){
        this.ordered = ordered;
    }
    this(Iter)(Iter iter, bool ordered = true) if(isIterableOf!(Iter, IniProperty)){
        this(ordered);
        foreach(property; iter) this.add(property);
    }
    this(string[string] map){
        this(false);
        foreach(key, value; map) this.add(key, value);
    }
    
    /// Determine whether the properties map is ordered.
    @property bool ordered() const{
        return this.isordered;
    }
    /// Set whether the properties map is ordered. The operation will fail when
    /// attempting to impose order on a properties map that is unordered and not
    /// empty.
    @property void ordered(bool ordered){
        if(this.map.length == 0){
            this.isordered = ordered;
            if(!ordered) this.list = null;
        }else if(ordered){
            assert(false, "Cannot order unordered properties.");
        }
    }
    
    /// Get the number of key, value pairs.
    @property auto length() const{
        if(this.ordered) return this.list.length;
        else return this.map.values.pluck!`length`.sum;
    }
    /// Determine whether the properties object is empty.
    @property bool empty() const{
        return this.map.length == 0;
    }
    
    alias opDollar = length;
    
    IniProperty[]* has(string key){
        return key in this.map;
    }
    
    /// Get the first value associated with a key. Throws an InvalidKeyException
    /// if no such key exists.
    T get(T = string)(string key){
        if(auto props = this.has(key)) return (*props)[0].value!T;
        else throw new InvalidKeyException(key);
    }
    /// Get the first value associated with a key, or return a fallback value
    /// when no such key exists.
    T get(T = string)(string key, lazy T fallback){
        if(auto props = this.has(key)) return (*props)[0].value!T;
        else return fallback();
    }
    /// Get the property at an index.
    IniProperty get(size_t index) in{
        assert(this.ordered);
        enforcebounds(index, this);
    } body{
        return this.list[index];
    }
    
    /// Get an array of values associated with a key.
    T[] all(T = string)(string key){
        T[] result;
        if(auto props = this.has(key)){
            result.reserve(props.length);
            foreach(prop; *props){
                result ~= prop.value!T;
            }
        }
        return result;
    }
    
    /// Set a key to a single value.
    void set(T = string)(string key, T value){
        this.set(new IniProperty(key, value.to!string));
    }
    void set()(IniProperty property){
        if(auto props = this.has(property.key)){
            if(this.ordered) (*props).each!(p => this.removefromlist(p));
            *props = [property];
        }else{
            this.map[property.key] = [property];
        }
        if(this.ordered) this.list ~= property;
    }
    
    /// Add a value per some key.
    void add(T = string)(string key, T value){
        this.add(new IniProperty(key, value.to!string));
    }
    void add()(IniProperty property){
        if(auto props = this.has(property.key)){
            *props ~= property;
            if(this.ordered) this.list ~= property;
        }else{
            this.set(property);
        }
    }
    
    void replace(IniProperty original, IniProperty property){
        if(this.ordered) this.list[this.getpropertyindex(original)] = property;
        this.removefrommap(original);
        this.addtomap(property);
    }
    void replace(size_t index, IniProperty property) in{assert(this.ordered);} body{
        IniProperty original = this.list[index];
        this.list[index] = property;
        this.removefrommap(original);
        this.addtomap(property);
    }
    
    void remove(IniProperty property){
        this.removefrommap(property);
        if(this.ordered) this.removefromlist(property);
    }
    void remove(size_t index) in{assert(this.ordered);} body{
        this.removefrommap(this.list[index]);
        this.removefromlist(index);
    }
    
    void addtomap(IniProperty property){
        if(auto props = property.key in this.map) *props ~= property;
        else this.set(property);
    }
    void removefrommap(IniProperty property){
        if(auto props = property.key in this.map){
            *props = (*props).filter!(p => p !is property).asarray;
        }else{
            throw new InvalidPropertyException(property);
        }
    }
    
    auto getpropertyindex(IniProperty property) in{assert(this.ordered);} body{
        auto found = this.list.find!(p => p is property);
        if(!found.exists) throw new InvalidPropertyException(property);
        return found.index;
    }
    void removefromlist(IniProperty[] properties...) in{assert(this.ordered);} body{
        this.removefromlist(
            properties.map!(p => this.getpropertyindex(p)).asarray
        );
    }
    void removefromlist(size_t[] indexes...) in{assert(this.ordered);} body{
        this.list = this.list.skipindexes(indexes).asarray;
    }
    
    bool hasproperty(IniProperty property){
        if(auto props = property.key in this.map){
            return (*props).any!(p => p is property);
        }else{
            return false;
        }
    }
    
    auto asrange(){
        return IniPropertiesRange!()(this);
    }
    auto keys(){
        return this.map.byKey;
    }
    auto values(){
        return this.map.byValue.flatten.pluck!`value`;
    }
    
    IniProperties dup(){
        auto copy = new IniProperties(this.ordered);
        foreach(IniProperty property; this) copy.add(new IniProperty(property));
        return copy;
    }
    
    string opIndex(string key){
        return this.get(key);
    }
    IniProperty opIndex(size_t index) in{assert(this.ordered);} body{
        return this.get(index);
    }
    void opIndexAssign(T)(T value, string key){
        this.set!T(key, value);
    }
    void opIndexAssign(IniProperty property, size_t index) in{assert(this.ordered);} body{
        this.replace(index, property);
    }
    
    void opOpAssign(string op: "~")(IniProperty property){
        this.add(property);
    }
    void opIndexOpAssign(T, string op: "~")(T value, string key){
        this.add!T(key, value);
    }
    
    typeof(this) opSlice(size_t low, size_t high) in{
        assert(this.ordered);
        assert(low >= 0 && high >= low && high < this.length);
    }body{
        return new typeof(this)(this.list[low .. high]);
    }
    
    auto opBinaryRight(string op: "in")(IniProperty property){
        return this.ownsproperty(property);
    }
    
    int opApply(F)(F apply) if(is(F == int delegate(ref string key, ref string value))){
        foreach(prop; this){
            if(auto result = apply(prop.key, prop.value)) return result;
        }
        return 0;
    }
    int opApply(F)(F apply) if(is(F == int delegate(ref IniProperty property))){
        if(this.ordered){
            foreach(prop; this.list){
                if(auto result = apply(prop)) return result;
            }
        }else{
            foreach(props; this.map){
                foreach(prop; props){
                    if(auto result = apply(prop)) return result;
                }
            }
        }
        return 0;
    }
}



struct IniPropertiesRange(Index = size_t){
    import std.typecons : Tuple;
    alias Element = Tuple!(string, `key`, string, `value`);
    
    private static Element aselement(IniProperty property){
        return Element(property.key, property.value);
    }
    private static IniProperty asproperty(Element element){
        return new IniProperty(element.key, element.value);
    }
    
    IniProperties source; /// IniProperties object being enumerated
    Index frontindex;
    Index backindex;
    
    this(IniProperties source) in{
        assert(source.ordered); // TODO: Also support unordered
    }body{
        this(source, 0, source.list.length);
    }
    
    this(IniProperties source, Index frontindex, Index backindex) in{
        assert(source.ordered);
    }body{
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    @property bool empty(){
        return this.frontindex >= backindex;
    }
    @property auto length(){
        return this.source.length;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return this.aselement(this.source.list[this.frontindex]);
    }
    @property void front(Element element) in{assert(!this.empty);} body{
        this.front = this.asproperty(element);
    }
    @property void front(IniProperty property) in{assert(!this.empty);} body{
        this.source.replace(this.frontindex, property);
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
    }
    
    @property auto back() in{assert(!this.empty);} body{
        return this.aselement(this.source.list[this.backindex - 1]);
    }
    @property void back(Element element) in{assert(!this.empty);} body{
        this.back = this.asproperty(element);
    }
    @property void back(IniProperty property) in{assert(!this.empty);} body{
        this.source.replace(this.backindex - 1, property);
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
    }
    
    void insert(Element element){
        this.insert(this.asproperty(element));
    }
    void insert(IniProperty property){
        this.source.add(property);
    }
    void removeFront() in{assert(!this.empty);} body{
        this.source.remove(this.frontindex);
    }
    void removeBack() in{assert(!this.empty);} body{
        this.source.remove(this.backindex - 1);
        this.backindex--;
    }
    
    @property typeof(this) save(){
        return typeof(this)(this.source, this.frontindex, this.backindex);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.pluck;
}
unittest{
    tests("Ini IniProperties", {
        auto props = new IniProperties;
        test(props.ordered);
        props.set("hello", "world");
        testeq(props["hello"], "world");
        testeq(props[0], "world");
        testeq(props[$-1], new IniProperty("hello", "world"));
        
        props.set("a", "apple");
        props.set("a", "apply");
        props.set("b", "bear");
        props.add("b", "bee");
        props.add("c", "cool");
        props.add("c", "clear");
        props.set("c", "cut");
        testeq(props.all("a"), ["apply"]);
        testeq(props.all("b"), ["bear", "bee"]);
        testeq(props.all("c"), ["cut"]);
        // TODO: More thorough tests
    });
}
