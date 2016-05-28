module mach.algo.asrange;

private:

import std.traits : Parameters, ReturnType, TemplateOf, TemplateArgsOf, Unqual;
import std.traits : isArray;
import std.range.primitives : ElementType, isBidirectionalRange;
import mach.algo.traits : isRange, canIncrement, canDecrement;

public:



/// Determine whether a range can be created from a type using makerange.
enum canMakeRange(Base) = (
    canMakeArrayRange!Base ||
    canMakeIndexRange!Base ||
    canMakeFiniteIndexRange!Base ||
    canMakeBidirectionalIndexRange!Base
);

/// Determine if a range can be created from a type, or if it already is a range.
enum validAsRange(T) = isRange!T || canMakeRange!T;

enum validAsBidirectionalRange(T) = (
    isBidirectionalRange!T ||
    canMakeArrayRange!T ||
    canMakeBidirectionalIndexRange!T
);



/// Get a range for iterating over some object.
auto asrange(Base)(in Base basis) if(!isRange!Base && canMakeRange!Base){
    return makerange(basis);
}
/// ditto
auto asrange(Range)(in Range range) if(isRange!Range){
    return range;
}

/// Create a range for iterating over some object.
auto makerange(Base)(in Base basis) if(canMakeRange!Base){
    static if(canMakeArrayRange!Base){
        return ArrayRange!Base(basis);
    }else static if(canMakeBidirectionalIndexRange!Base){
        return BidirectionalIndexRange!Base(basis);
    }else static if(canMakeFiniteIndexRange!Base){
        return FiniteIndexRange!Base(basis);
    }else static if(canMakeIndexRange!Base){
        return IndexRange!Base(basis);
    }else{
        static assert(false); // This shouldn't happen
    }
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
        alias Index = IndexRangeIndex!Base; //Unqual!(Parameters!(Base.opIndex)[0]);
        
        Base range = Base.init;
        Index index = Index.init;
        assert(index <= range.length); // Initial index is <= length
    }));
}

template canMakeBidirectionalIndexRange(Base){
    enum bool canMakeBidirectionalIndexRange = is(typeof((inout int = 0){
        static assert(canMakeFiniteIndexRange!Base);
        Base range = Base.init;
        auto index = cast(IndexRangeIndex!Base) range.length; // Compatible index and length types
        static assert(canDecrement!(typeof(index)));
    }));
}

enum canMakeArrayRange(Base) = isArray!Base;



template IndexRangeIndex(Base) if(canMakeIndexRange!Base && !isIndexRange!Base){
    alias IndexRangeIndex = Unqual!(Parameters!(Base.opIndex)[0]);
}
template IndexRangeElement(Base) if(canMakeIndexRange!Base && !isIndexRange!Base){
    alias IndexRangeElement = ReturnType!(Base.opIndex);
}

template IndexRangeBase(Range) if(isIndexRange!Range){
    alias IndexRangeBase = TemplateArgsOf!Range[0];
}
template IndexRangeIndex(Range) if(isIndexRange!Range){
    alias IndexRangeIndex = IndexRangeIndex!(IndexRangeBase!Range);
}
template IndexRangeElement(Range) if(isIndexRange!Range){
    alias IndexRangeElement = IndexRangeElement!(IndexRangeBase!Range);
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
    Elem opIndex(Index index){
        return this.basis[index];
    }
    
    @property auto save(){
        return typeof(this)(this);
    }
    
    static if(is(typeof(this.basis[Index.init .. Index.init]) == Base)){
        auto opSlice(Index low, Index high){
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
    alias Index = IndexRangeIndex!Base;
    alias Elem = IndexRangeElement!Base;
    
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
    
    void popFront(){
        this.index++;
    }
    @property Elem front(){
        return this.basis[this.index];
    }
    
    enum bool empty = false;
}

/// Make a range from some object implementing opIndex(Index) and length by
/// starting at Index.init and incrementing until index >= length.
struct FiniteIndexRange(Base) if(canMakeFiniteIndexRange!Base){
    alias Index = IndexRangeIndex!Base;
    alias Elem = IndexRangeElement!Base;
    
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
    
    void popFront(){
        this.index++;
    }
    @property Elem front() in{assert(!this.empty);}body{
        return this.basis[this.index];
    }
    
    @property bool empty(){
        return this.index >= this.basis.length;
    }
    @property auto remaining(){
        return this.length - this.index;
    }
    
}

/// Make a range from some object implementing opIndex(Index) and length where
/// length is also of type Index and can be decremented. Start the front index
/// at Index.init and back index at length-1 and keep popping until the front
/// index exceeds the back index.
struct BidirectionalIndexRange(Base) if(canMakeBidirectionalIndexRange!Base){
    alias Index = IndexRangeIndex!Base;
    alias Elem = IndexRangeElement!Base;
    
    Base basis;
    Index frontindex;
    Index backindex;
    
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
    
    void popFront(){
        this.frontindex++;
    }
    @property Elem front() in{assert(!this.empty);}body{
        return this.basis[this.frontindex];
    }
    
    void popBack(){
        this.backindex--;
    }
    @property Elem back() in{assert(!this.empty);}body{
        auto index = this.backindex;
        index--;
        return this.basis[index];
    }
    
    @property bool empty(){
        return this.frontindex > this.backindex;
    }
    @property auto remaining(){
        auto value = this.backindex - this.frontindex;
        value++;
        return value;
    }
}

/// Range based on an array.
struct ArrayRange(Base) if(canMakeArrayRange!Base){
    alias Index = size_t;
    alias Elem = Unqual!(ElementType!Base);
    
    const Base basis;
    Index frontindex;
    Index backindex;
    
    this(typeof(this) range){
        this(range.basis, range.frontindex, range.backindex);
    }
    this(in Base basis, Index frontindex = 0){
        this(basis, frontindex, basis.length);
    }
    this(in Base basis, Index frontindex, Index backindex){
        this.basis = basis;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    void popFront(){
        this.frontindex++;
    }
    @property Elem front() const in{assert(!this.empty);}body{
        return this.basis[this.frontindex];
    }
    
    void popBack(){
        this.backindex--;
    }
    @property Elem back() const in{assert(!this.empty);}body{
        return this.basis[this.backindex - 1];
    }
    
    @property bool empty() const{
        return this.frontindex >= this.backindex;
    }
    @property auto length() const{
        return this.basis.length;
    }
    @property auto remaining() const{
        return this.backindex - this.frontindex;
    }
    alias opDollar = length;
    
    Elem opIndex(in Index index) const{
        return this.basis[index];
    }
    typeof(this) opSlice(in Index low, in Index high) const{
        return typeof(this)(this.basis[low .. high]);
    }
    
    @property auto save(){
        return typeof(this)(this);
    }
}



version(unittest){
    import mach.error.unit;
    
    // Test IndexRange creation
    struct Indexed{
        int value;
        int opIndex(in int index) const{
            return this.value + index;
        }
    }
    
    // Test BidirectionalIndexRange creation
    struct BiIndexed0{
        int value, length;
        int opIndex(in int index) const{
            return this.value + index;
        }
    }
    struct BiIndexed1{
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
    int[] array = [1, 1, 2, 3, 5, 8];
    auto range = array.asrange;
    testis(range, range.asrange);
}
unittest{
    auto indexed = Indexed(0);
    auto range = indexed.asrange;
    testtype!(IndexRange!Indexed)(range);
}
unittest{
    auto bi0 = BiIndexed0(0, 10);
    auto range0 = bi0.asrange;
    testtype!(BidirectionalIndexRange!BiIndexed0)(range0);
    auto bi1 = BiIndexed1(0, 10);
    auto range1 = bi1.asrange;
    testtype!(BidirectionalIndexRange!BiIndexed1)(range1);
}
