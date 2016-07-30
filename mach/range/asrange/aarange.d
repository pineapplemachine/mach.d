module mach.range.asrange.aarange;

private:

import std.traits : isAssociativeArray, KeyType, ValueType, isImplicitlyConvertible;
import std.typecons : Tuple;
import mach.traits : canReassign;
import mach.range.asrange.arrayrange : ArrayRange;

public:



alias canMakeAssociativeArrayRange = isAssociativeArray;



/// Range based on an associative array.
struct AssociativeArrayRange(Array) if(canMakeAssociativeArrayRange!Array){
    alias Key = KeyType!Array;
    alias Keys = ArrayRange!(Key[]);
    alias Element = Tuple!(KeyType!Array, "key", ValueType!Array, "value");
    
    Array array;
    Keys keys;
    
    this(typeof(this) range){
        this(range.array, range.keys);
    }
    this(Array array){
        this.array = array;
        this.keys = Keys(array.keys);
    }
    this(Array array, Keys keys){
        this.array = array;
        this.keys = keys;
    }
    
    @property bool empty(){
        return this.keys.empty;
    }
    @property auto length(){
        return this.keys.length;
    }
    @property auto remaining(){
        return this.keys.remaining;
    }
    alias opDollar = length;
    
    @property auto ref front(){
        auto key = keys.front;
        return Element(cast(KeyType!Array) key, cast(ValueType!Array) this.array[key]);
    }
    void popFront(){
        this.keys.popFront();
    }
    @property auto ref back(){
        auto key = keys.back;
        return Element(cast(KeyType!Array) key, cast(ValueType!Array) this.array[key]);
    }
    void popBack(){
        this.keys.popBack();
    }
    
    auto ref opIndex(in size_t index){
        auto key = this.keys[index];
        return Element(cast(KeyType!Array) key, cast(ValueType!Array) this.array[key]);
    }
    static if(!isImplicitlyConvertible!(size_t, Key)){
        auto ref opIndex(in Key key) const{
            return Element(cast(KeyType!Array) key, cast(ValueType!Array) this.array[key]);
        }
    }
    
    typeof(this) opSlice(in size_t low, in size_t high){
        return typeof(this)(this.array, this.keys[low .. high]);
    }
    
    static if(canReassign!Array){
        enum bool mutable = true;
        
        @property void front(Element element){
            this.array.remove(this.keys.front);
            this.keys.front = element.key;
            this.array[element.key] = element.value;
        }
        @property void front(ValueType!Array value){
            this.array[this.keys.front] = value;
        }
        
        @property void back(Element element){
            this.array.remove(this.keys.back);
            this.keys.back = element.key;
            this.array[element.key] = element.value;
        }
        @property void back(ValueType!Array value){
            this.array[this.keys.back] = value;
        }
        
        void opIndexAssign(Element element, in size_t index) in{
            assert(index >= 0 && index < this.keys.length);
        }body{
            this.array.remove(this.keys[index]);
            this.keys[index] = element.key;
            this.array[element.key] = element.value;
        }
        void opIndexAssign(ValueType!Array value, size_t index) in{
            assert(index >= 0 && index < this.keys.length);
        }body{
            this.array[this.keys[index]] = value;
        }
    }else{
        enum bool mutable = false;
    }
    
    @property auto save(){
        return typeof(this)(this.array, this.keys.save);
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Associative array as range", {
        int[string] array = [
            "zero": 0, "one": 1,
            "two": 2, "three": 3,
            "four": 4, "five": 5
        ];
        alias Array = typeof(array);
        testeq("Length",
            AssociativeArrayRange!Array(array).length, array.length
        );
        tests("Iteration", {
            auto range = AssociativeArrayRange!Array(array);
            foreach(element; range){
                testeq(array[element.key], element.value);
            }
            foreach(key, value; range){
                testeq(array[key], value);
            }
        });
        tests("Random access", {
            auto range = AssociativeArrayRange!Array(array);
            foreach(i; 0 .. array.length){
                testeq(range[i].value, array[range[i].key]);
            }
        });
        tests("Index by key", {
            auto range = AssociativeArrayRange!Array(array);
            testeq(range["zero"].value, 0);
            testeq(range["one"].value, 1);
            fail({range["not_a_key"];});
        });
        tests("Mutability", {
            auto arraydup = array.dup;
            auto range = AssociativeArrayRange!Array(arraydup);
            auto insertion = typeof(range).Element("hi", -1);
            range.front = insertion;
            range.back = insertion;
            testeq(range.front, insertion);
            testeq(range.back, insertion);
            range[1] = insertion;
            range.popFront();
            testeq(range.front, insertion);
            testeq(arraydup["hi"], -1);
        });
    });
}
