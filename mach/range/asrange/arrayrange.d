module mach.range.asrange.arrayrange;

private:

import std.traits : isArray, isIntegral, isMutable;
import mach.traits : ArrayElementType;

public:



enum canMakeArrayRange(Array) = isArray!Array;

enum canMakeArrayRange(Array, Index) = (
    canMakeArrayRange!Array && isIntegral!Index
);



/// Range based on an array.
struct ArrayRange(Array, Index = size_t) if(canMakeArrayRange!Array){
    alias Element = ArrayElementType!Array;
    
    Array array;
    Index frontindex;
    Index backindex;
    
    this(typeof(this) range){
        this(range.array, range.frontindex, range.backindex);
    }
    this(Array array, Index frontindex = Index.init){
        this(array, frontindex, array.length);
    }
    this(Array array, Index frontindex, Index backindex){
        this.array = array;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    void popFront(){
        this.frontindex++;
    }
    @property auto ref front() const{
        return this.array[this.frontindex];
    }
    
    void popBack(){
        this.backindex--;
    }
    @property auto ref back() const{
        return this.array[this.backindex - 1];
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    @property auto length() const{
        return this.array.length;
    }
    @property auto remaining() const{
        return this.backindex - this.frontindex;
    }
    alias opDollar = length;
    
    auto ref opIndex(in Index index) const{
        return this.array[index];
    }
    typeof(this) opSlice(in Index low, in Index high){
        return typeof(this)(this.array[low .. high]);
    }
    
    static if(isMutable!Array && isMutable!Element){
        enum bool mutable = true;
        @property void front(Element value){
            this.array[this.frontindex] = value;
        }
        @property void back(Element value){
            this.array[this.backindex - 1] = value;
        }
        void opIndexAssign(Element value, in Index index){
            this.array[index] = value;
        }
    }else{
        enum bool mutable = false;
    }
    
    @property auto save(){
        return typeof(this)(this);
    }
    
    bool opEquals(in Array rhs) const{
        return this.array == rhs;
    }
    bool opEquals(in typeof(this) rhs) const{
        return this.array == rhs.array;
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Array as range", {
        tests("Equality", {
            auto range = ArrayRange!(int[])([1, 2, 3]);
            testeq(range, [1, 2, 3]);
            testeq(range, range);
        });
        tests("Saving", {
            auto range = ArrayRange!(int[])([1, 2, 3]);
            auto saved = range.save;
            while(!range.empty) range.popFront();
            testeq(range.frontindex, 3);
            testeq(saved.frontindex, 0);
        });
        tests("Slicing", {
            auto range = ArrayRange!(int[])([1, 1, 2, 3, 5, 8]);
            auto slice = range[0 .. 3];
            testeq(slice.length, 3);
            test(is(typeof(range) == typeof(slice)));
        });
        tests("Mutability", {
            char[] data = ['h', 'e', 'l', 'l', 'o'];
            auto range = ArrayRange!(char[])(data);
            range[1] = 'a';
            range.popFront();
            testeq(range.front, 'a');
        });
    });
}
