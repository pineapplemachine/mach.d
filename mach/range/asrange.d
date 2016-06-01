module mach.range.asrange;

private:

import std.traits : Parameters, ReturnType, TemplateOf, TemplateArgsOf, Unqual;
import std.traits : isArray, isCallable, isImplicitlyConvertible;
import std.traits : isAssociativeArray, KeyType, ValueType;
import mach.traits : isRange, isSavingRange, isRandomAccessRange;
import mach.traits : isBidirectionalRange, isSlicingRange;
import mach.traits : ArrayElementType, canIncrement, canDecrement, canCast;

public:



/// Determine whether a range can be created from a type using makerange.
enum canMakeRange(Base) = (
    canMakeArrayRange!Base ||
    canMakeAssociativeArrayRange!Base ||
    canMakeIndexRange!Base ||
    canMakeFiniteIndexRange!Base ||
    canMakeBidirectionalIndexRange!Base
);

/// Determine if a range can be created from a type, or if it already is a range.
enum validAsRange(T) = isRange!T || canMakeRange!T;
template validAsRange(T, alias isType){
    static if(isRange!T){
        enum bool validAsRange = isType!T;
    }else static if(validAsRange!T){
        enum bool validAsRange = isType!(AsRangeType!T);
    }else{
        enum bool validAsRange = false;
    }
}

enum validAsBidirectionalRange(T) = validAsRange!(T, isBidirectionalRange);
enum validAsRandomAccessRange(T) = validAsRange!(T, isRandomAccessRange);
enum validAsSlicingRange(T) = validAsRange!(T, isSlicingRange);
enum validAsSavingRange(T) = validAsRange!(T, isSavingRange);

template MakeRangeType(Base) if(canMakeRange!Base){
    static if(canMakeArrayRange!Base){
        alias MakeRangeType = ArrayRange!Base;
    }else static if(canMakeAssociativeArrayRange!Base){
        alias MakeRangeType = AssociativeArrayRange!Base;
    }else static if(canMakeBidirectionalIndexRange!Base){
        alias MakeRangeType = BidirectionalIndexRange!Base;
    }else static if(canMakeFiniteIndexRange!Base){
        alias MakeRangeType = FiniteIndexRange!Base;
    }else static if(canMakeIndexRange!Base){
        alias MakeRangeType = IndexRange!Base;
    }else{
        static assert(false); // This shouldn't happen
    }
}

template AsRangeType(T) if(validAsRange!T){
    static if(isRange!T){
        alias AsRangeType = T;
    }else{
        alias AsRangeType = MakeRangeType!T;
    }
}



/// Get a range for iterating over some object.
auto asrange(Base)(Base basis) if(!isRange!Base && canMakeRange!Base){
    return makerange(basis);
}
/// ditto
auto asrange(Range)(Range range) if(isRange!Range){
    return range;
}

/// Create a range for iterating over some object.
auto makerange(Base)(Base basis) if(canMakeRange!Base){
    return MakeRangeType!Base(basis);
}



template canMakeIndexRange(Base){
    enum bool canMakeIndexRange = is(typeof((inout int = 0){
        alias Params = Parameters!(Base.opIndex);
        static assert(Params.length == 1); // Has exactly one argument
        
        Base range = Base.init;
        auto index = Unqual!(Params[0]).init;
        auto elem = range[index]; // Can get index from Param.init
        static assert(canIncrement!(typeof(index)));
    }));
}
        
template canMakeFiniteIndexRange(Base){
    enum bool canMakeFiniteIndexRange = is(typeof((inout int = 0){
        static assert(canMakeIndexRange!Base);
        alias Index = IndexRangeIndexType!Base; //Unqual!(Parameters!(Base.opIndex)[0]);
        
        Base range = Base.init;
        Index index = Index.init;
        assert(index <= range.length); // Initial index is <= length
    }));
}

template canMakeBidirectionalIndexRange(Base){
    enum bool canMakeBidirectionalIndexRange = is(typeof((inout int = 0){
        static assert(canMakeFiniteIndexRange!Base);
        Base range = Base.init;
        auto index = cast(IndexRangeIndexType!Base) range.length; // Compatible index and length types
        static assert(canDecrement!(typeof(index)));
    }));
}

alias canMakeArrayRange = isArray;

alias canMakeAssociativeArrayRange = isAssociativeArray;



template IndexRangeIndexType(Base) if(canMakeIndexRange!Base && !isIndexRange!Base){
    alias IndexRangeIndexType = Unqual!(Parameters!(Base.opIndex)[0]);
}
template IndexRangeElementType(Base) if(canMakeIndexRange!Base && !isIndexRange!Base){
    alias IndexRangeElementType = ReturnType!(Base.opIndex);
}

template IndexRangeBase(Range) if(isIndexRange!Range){
    alias IndexRangeBase = TemplateArgsOf!Range[0];
}
template IndexRangeIndexType(Range) if(isIndexRange!Range){
    alias IndexRangeIndexType = IndexRangeIndexType!(IndexRangeBase!Range);
}
template IndexRangeElementType(Range) if(isIndexRange!Range){
    alias IndexRangeElementType = IndexRangeElementType!(IndexRangeBase!Range);
}

template isIndexRange(Range){
    enum bool isIndexRange = is(typeof((inout int = 0){
        static assert(
            __traits(isSame, TemplateOf!Range, IndexRange) ||
            __traits(isSame, TemplateOf!Range, FiniteIndexRange) ||
            __traits(isSame, TemplateOf!Range, BidirectionalIndexRange)
        );
    }));
}



static immutable string IndexRangeCommonMixin = `
    auto ref opIndex(Index index){
        return this.basis[index];
    }
    
    @property auto ref save(){
        return typeof(this)(this);
    }
    
    static if(is(typeof(this.basis[Index.init .. Index.init]) == Base)){
        typeof(this) opSlice(Index low, Index high){
            return typeof(this)(this.basis[low .. high]);
        }
    }
`;

static immutable string FiniteIndexRangeCommonMixin = `
    @property auto length(){
        return this.basis.length;
    }
    alias opDollar = length;
`;




/// Make a range from some object implementing opIndex(Index) by starting at
/// Index.init and infinitely incrementing.
struct IndexRange(Base) if(canMakeIndexRange!Base){
    alias Index = IndexRangeIndexType!Base;
    alias Element = IndexRangeElementType!Base;
    
    Base basis;
    Index index;
    
    this(typeof(this) range){
        this(range.basis, range.index);
    }
    this(Base basis, Index index = Index.init){
        this.basis = basis;
        this.index = index;
    }
    
    mixin(IndexRangeCommonMixin);
    
    enum bool empty = false;
    
    void popFront(){
        this.index++;
    }
    @property auto ref front(){
        return this.basis[this.index];
    }
}



/// Make a range from some object implementing opIndex(Index) and length by
/// starting at Index.init and incrementing until index >= length.
struct FiniteIndexRange(Base) if(canMakeFiniteIndexRange!Base){
    alias Index = IndexRangeIndexType!Base;
    
    Base basis;
    Index index;
    
    this(typeof(this) range){
        this(range.basis, range.index);
    }
    this(Base basis, Index index = Index.init){
        this.basis = basis;
        this.index = index;
    }
    
    mixin(IndexRangeCommonMixin);
    mixin(FiniteIndexRangeCommonMixin);
    
    @property bool empty(){
        return this.index >= this.basis.length;
    }
    @property auto remaining(){
        return this.length - this.index;
    }
    
    void popFront(){
        this.index++;
    }
    @property auto ref front() in{assert(!this.empty);}body{
        return this.basis[this.index];
    }
}



/// Make a range from some object implementing opIndex(Index) and length where
/// length is also of type Index and can be decremented. Start the front index
/// at Index.init and back index at length-1 and keep popping until the front
/// index exceeds the back index.
struct BidirectionalIndexRange(Base) if(canMakeBidirectionalIndexRange!Base){
    alias Index = IndexRangeIndexType!Base;
    
    Base basis;
    Index frontindex;
    Index backindex;
    
    alias index = frontindex;
    
    this(typeof(this) range){
        this(range.basis, range.frontindex, range.backindex);
    }
    this(Base basis, Index frontindex = Index.init){
        this(basis, frontindex, cast(Index) basis.length);
    }
    this(Base basis, Index frontindex, Index backindex){
        this.basis = basis;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    mixin(IndexRangeCommonMixin);
    mixin(FiniteIndexRangeCommonMixin);
    
    @property bool empty(){
        return this.frontindex >= this.backindex;
    }
    @property auto remaining(){
        return this.backindex - this.frontindex;
    }
    
    void popFront(){
        this.frontindex++;
    }
    @property auto ref front() in{assert(!this.empty);}body{
        return this.basis[this.frontindex];
    }
    
    void popBack(){
        this.backindex--;
    }
    @property auto ref back() in{assert(!this.empty);}body{
        auto index = this.backindex;
        index--;
        return this.basis[index];
    }
}



/// Range based on an array.
struct ArrayRange(Array) if(canMakeArrayRange!Array){
    alias Index = size_t;
    
    const Array array;
    Index frontindex;
    Index backindex;
    
    alias index = frontindex;
    
    this(typeof(this) range){
        this(range.array, range.frontindex, range.backindex);
    }
    this(in Array array, Index frontindex = 0){
        this(array, frontindex, array.length);
    }
    this(in Array array, Index frontindex, Index backindex){
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
    typeof(this) opSlice(in Index low, in Index high) const{
        return typeof(this)(this.array[low .. high]);
    }
    
    @property auto save(){
        return typeof(this)(this);
    }
}



struct AssociativeArrayRangeElement(Array){
    KeyType!Array key;
    ValueType!Array value;
    alias k = key;
    alias val = value; alias v = value;
}

/// Range based on an associative array.
struct AssociativeArrayRange(Array) if(canMakeAssociativeArrayRange!Array){
    alias Key = KeyType!Array;
    alias Keys = ArrayRange!(Key[]);
    alias Element = AssociativeArrayRangeElement!Array;
    
    const Array array;
    Keys keys;
    
    this(in typeof(this) range){
        this(range.array, range.keys);
    }
    this(in Array array){
        this.array = array;
        this.keys = Keys(array.keys);
    }
    this(in Array array, in Keys keys){
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
    
    @property auto ref front() const{
        auto key = keys.front;
        return Element(key, this.array[key]);
    }
    void popFront(){
        this.keys.popFront();
    }
    @property auto ref back() const{
        auto key = keys.back;
        return Element(key, this.array[key]);
    }
    void popBack(){
        this.keys.popBack();
    }
    
    auto ref opIndex(in size_t index) const{
        auto key = keys[index];
        return Element(key, this.array[key]);
    }
    static if(!isImplicitlyConvertible!(size_t, Key)){
        auto ref opIndex(in Key key) const{
            return Element(key, this.array[key]);
        }
    }
    
    typeof(this) opSlice(in size_t low, in size_t high) const{
        return typeof(this)(this.array, this.keys[low .. high]);
    }
    
    @property auto save(){
        return typeof(this)(this.array, this.keys.save);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    
    // Test IndexRange creation
    private struct Indexed{
        int value;
        int opIndex(in int index) const{
            return this.value + index;
        }
    }
    
    // Test BidirectionalIndexRange creation
    private struct BiIndexed0{
        int value, length;
        int opIndex(in int index) const{
            return this.value + index;
        }
    }
    private struct BiIndexed1{
        int value, len;
        int opIndex(in int index) const{
            return this.value + index;
        }
        @property int length() const{
            return this.len;
        }
    }
}
unittest{
    tests("Range from some type implementing opIndex", {
        auto indexed = Indexed(0);
        auto range = indexed.asrange;
        testtype!(IndexRange!Indexed)(range);
    });
}
unittest{
    tests("Range from some type implementing length and opIndex", {
        auto bi0 = BiIndexed0(0, 10);
        auto range0 = bi0.asrange;
        testtype!(BidirectionalIndexRange!BiIndexed0)(range0);
        auto bi1 = BiIndexed1(0, 10);
        auto range1 = bi1.asrange;
        testtype!(BidirectionalIndexRange!BiIndexed1)(range1);
    });
}
unittest{
    tests("Array as range", {
        tests("Saving", {
            auto range = [1, 2, 3].asrange;
            testis(range, range.asrange);
            auto saved = range.save;
            while(!range.empty) range.popFront();
            testeq(range.index, 3);
            testeq(saved.index, 0);
        });
        tests("Slicing", {
            int[] array = [1, 1, 2, 3, 5, 8];
            auto range = array.asrange;
            auto slice = range[0 .. 3];
            testeq(slice.length, 3);
            test(is(typeof(range) == typeof(slice)));
        });
    });
}
unittest{
    tests("Associative array as range", {
        int[string] array = [
            "zero": 0, "one": 1,
            "two": 2, "three": 3,
            "four": 4, "five": 5
        ];
        testeq("Length",
            array.asrange.length, array.length
        );
        tests("Iteration", {
            auto range = array.asrange;
            foreach(element; range){
                testeq(array[element.key], element.value);
            }
        });
        tests("Random access", {
            auto range = array.asrange;
            foreach(i; 0 .. array.length){
                testeq(range[i].value, array[range[i].key]);
            }
        });
        tests("Index by key", {
            auto range = array.asrange;
            testeq(range["zero"].value, 0);
            testeq(range["one"].value, 1);
            fail({range["not_a_key"];});
        });
    });
}
