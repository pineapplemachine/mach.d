module mach.range.repeat;

private:

import std.conv : to;
import std.traits : isIntegral;
import mach.traits : isIterable, isFiniteIterable, isInfiniteIterable;
import mach.traits : isFiniteRange, isRandomAccessRange, isSavingRange;
import mach.traits : canIncrement, canCompare, hasNumericLength;
import mach.traits : hasSingleIndexParameter, SingleIndexParameter;
import mach.traits : hasNumericLength;
import mach.range.asrange : asrange, validAsRange;
import mach.range.asrange : validAsRandomAccessRange, validAsSavingRange;

public:



enum canRepeatIterable(Iter) = (
    canRepeatRandomAccess!Iter || canRepeatSaving!Iter
);

enum canRepeatRange(Range) = (
    canRepeatRandomAccessRange!Range || canRepeatSavingRange!Range
);

enum canRepeatRandomAccess(Iter) = (
    isFiniteIterable!Iter && validAsRandomAccessRange!Iter
);
enum canRepeatSaving(Iter) = (
    isFiniteIterable!Iter && validAsSavingRange!Iter
);

enum canRepeatRandomAccessRange(Range) = (
    isFiniteRange!Range && isRandomAccessRange!Range && hasNumericLength!Range
);
enum canRepeatSavingRange(Range) = (
    isFiniteRange!Range && isSavingRange!Range
);

enum canRepeatElement(Element) = !validAsRange!Element;

alias DefaultRepeatCount = size_t;

alias validRepeatCount = isIntegral;



auto repeat(Iter)(Iter iter) if(isInfiniteIterable!Iter){
    return iter;
}

auto repeat(Iter, Count = DefaultRepeatCount)(Iter iter, Count count) if(
    isInfiniteIterable!Iter && validRepeatCount!Count
){
    return iter;
}

auto repeat(Iter)(Iter iter) if(canRepeatIterable!Iter){
    static if(canRepeatRandomAccess!Iter){
        return repeatrandomaccess!(Iter)(iter);
    }else{
        return repeatsaving!(Iter)(iter);
    }
}

auto repeat(Iter, Count = DefaultRepeatCount)(Iter iter, Count count) if(
    canRepeatIterable!Iter && validRepeatCount!Count
){
    static if(canRepeatRandomAccess!Iter){
        return repeatrandomaccess!(Iter, Count)(iter, count);
    }else{
        return repeatsaving!(Iter, Count)(iter, count);
    }
}

auto repeat(Element)(Element element) if(!validAsRange!Element){
    return repeatelement!(Element)(element);
}

auto repeat(Element, Count = DefaultRepeatCount)(Element element, Count count) if(
    !validAsRange!Element && validRepeatCount!Count
){
    return repeatelement!(Element, Count)(element, count);
}



auto repeatrandomaccess(Iter)(Iter iter) if(canRepeatRandomAccess!Iter){
    auto range = iter.asrange;
    return InfiniteRepeatRandomAccessRange!(typeof(range))(range);
}

auto repeatrandomaccess(Iter, Count = DefaultRepeatCount)(Iter iter, Count count) if(
    canRepeatRandomAccess!Iter && validRepeatCount!Count
){
    auto range = iter.asrange;
    return FiniteRepeatRandomAccessRange!(typeof(range), Count)(range, count);
}

auto repeatsaving(Iter)(Iter iter) if(canRepeatSaving!Iter){
    auto range = iter.asrange;
    return InfiniteRepeatSavingRange!(typeof(range))(range);
}

auto repeatsaving(Iter, Count = DefaultRepeatCount)(Iter iter, Count count) if(
    canRepeatSaving!Iter && validRepeatCount!Count
){
    auto range = iter.asrange;
    return FiniteRepeatSavingRange!(typeof(range), Count)(range, count);
}

auto repeatelement(Element)(Element element){
    return InfiniteRepeatElementRange!(Element)(element);
}

auto repeatelement(Element, Count = DefaultRepeatCount)(Element element, Count count) if(
    validRepeatCount!Count
){
    return FiniteRepeatElementRange!(Element, Count)(element, count);
}



private template RepeatSavingRangeMixin(Range, string popfrontstr){
    Range* source;
    Range original;
    
    import core.stdc.stdlib : malloc, free;
    
    @nogc void repeat(Range from){ // TODO: this really should not be necessary
        if(this.source) free(this.source);
        ubyte* newptr = cast(ubyte*) malloc(Range.sizeof);
        assert(newptr !is null, "Failed to allocate memory.");
        
        ubyte* fromptr = cast(ubyte*) &from;
        for(size_t i; i < Range.sizeof; i++) newptr[i] = fromptr[i];
        this.source = cast(Range*) newptr;
    }
    
    this(this){
        auto from = *this.source;
        this.source = null;
        this.repeat(from);
    }
    ~this(){
        if(this.source) free(this.source);
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        mixin(popfrontstr);
    }
    
    static if(isRandomAccessRange!Range && hasNumericLength!Range){
        auto opIndex(SingleIndexParameter!Range index){
            return (*this.source)[index % this.source.length];
        }
    }
    
    @property auto ref save(){
        return typeof(this)(this);
    }
}

private template RepeatRandomAccessRangeMixin(Range, Count){
    Range source;
    Count frontindex;
    Count backindex;
    
    alias index = frontindex;
    
    @property auto ref front(){
        return this.source[this.frontindex];
    }
    @property auto ref back(){
        return this.source[this.backindex - 1];
    }
    
    auto opIndex(in Count index) in{
        assert(index >= 0);
        static if(hasNumericLength!(typeof(this))){
            assert(index < this.length);
        }
    }body{
        return this.source[index % this.source.length];
    }
    
    // TODO: Slice
    
    @property auto ref save(){
        return typeof(this)(this);
    }
}

private template RepeatElementRangeMixin(Element){
    Element element;
    
    @property auto ref front() const{
        return this.element;
    }
    @property auto ref back() const{
        return this.element;
    }
    
    auto opIndex(in size_t index) in{
        assert(index >= 0);
        static if(hasNumericLength!(typeof(this))){
            assert(index < this.length);
        }
    }body{
        return this.element;
    }
    
    auto opSlice(in size_t low, in size_t high) in{
        assert((low >= 0) & (high >= low));
        static if(hasNumericLength!(typeof(this))){
            assert(high < this.length);
        }
    }body{
        return FiniteRepeatElementRange!(Element)(this.element, high - low);
    }
    
    @property auto ref save(){
        return typeof(this)(this);
    }
}



/// Repeat a range with random access infinitely
struct InfiniteRepeatRandomAccessRange(Range, Count = DefaultRepeatCount) if(
    canRepeatRandomAccessRange!Range && validRepeatCount!Count
){
    mixin RepeatRandomAccessRangeMixin!(Range, Count);
    
    this(typeof(this) range){
        this(range.source, range.frontindex, range.backindex);
    }
    this(Range source, Count frontindex = Count.init){
        this(source, frontindex, source.length);
    }
    this(Range source, Count frontindex, Count backindex){
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    enum bool empty = false;
    
    void popFront(){
        this.frontindex = (this.frontindex + 1) % this.source.length;
    }
    void popBack(){
        this.backindex--;
        if(this.backindex == 0) this.backindex = this.source.length;
    }
}

/// Repeat a range with random access a given number of times
struct FiniteRepeatRandomAccessRange(Range, Count = DefaultRepeatCount) if(
    canRepeatRandomAccessRange!Range && validRepeatCount!Count
){
    mixin RepeatRandomAccessRangeMixin!(Range, Count);
    
    Count limit; // Number of times the source range is repeated
    Count count; // Number of times the source range has been fully consumed
    
    this(typeof(this) range){
        this(range.source, range.limit, range.count, range.frontindex, range.backindex);
    }
    this(Range source, Count limit, Count frontindex = Count.init){
        this(source, limit, Count.init, frontindex, to!Count(source.length));
    }
    this(Range source, Count limit, Count count, Count frontindex, Count backindex){
        this.source = source;
        this.limit = limit;
        this.count = count;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    @property bool empty(){
        return this.count >= (this.limit - (this.frontindex >= this.backindex));
    }
    
    @property auto length(){
        return this.source.length * this.limit;
    }
    
    void popFront(){
        this.frontindex++;
        if(this.frontindex >= this.source.length){
            this.count++;
            this.frontindex = 0;
        }
    }
    void popBack(){
        this.backindex--;
        if(this.backindex == 0){
            this.count++;
            this.backindex = to!Count(this.source.length);
        }
    }
}



/// Repeat a range with saving infinitely
struct InfiniteRepeatSavingRange(Range) if(canRepeatSavingRange!Range){
    mixin RepeatSavingRangeMixin!(
        Range, `
            this.source.popFront();
            if(this.source.empty) this.repeat(this.original.save);
        `
    );
    
    this(typeof(this) range){
        this.original = range.original;
        this.repeat(*range.source);
    }
    this(Range source){
        this.original = source;
        this.repeat(source.save);
    }
    
    enum bool empty = false;
}

/// Repeat a range with saving a given number of times
struct FiniteRepeatSavingRange(Range, Count = DefaultRepeatCount) if(
    canRepeatSavingRange!Range && validRepeatCount!Count
){
    mixin RepeatSavingRangeMixin!(
        Range, `
            this.source.popFront();
            if(this.source.empty){
                this.repeat(this.original.save);
                this.count++;
            }
        `
    );
    
    Count count; /// Cycle iteration is currently on
    Count limit; /// Maximum number of cycles before emptiness
    
    this(typeof(this) range){
        this.count = range.count;
        this.limit = range.limit;
        this.original = range.original;
        this.repeat(*range.source);
    }
    this(Range source, Count limit){
        this(source, Count.init, limit);
    }
    this(Range source, Count count, Count limit){
        this.count = count;
        this.limit = limit;
        this.original = source;
        this.repeat(source.save);
    }
    
    @property bool empty(){
        return this.count >= this.limit;
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            return this.source.length * limit;
        }
        alias opDollar = length;
    }
}



/// Create a range repeating a single element infinitely
struct InfiniteRepeatElementRange(Element){
    mixin RepeatElementRangeMixin!Element;
    
    this(typeof(this) range){
        this(range.element);
    }
    this(Element element){
        this.element = element;
    }
    
    enum bool empty = false;
    
    void popFront() const{
        // Do nothing
    }
    void popBack() const{
        // Do nothing
    }
}

/// Create a range repeating a single element for a given number of times
struct FiniteRepeatElementRange(Element, Count = DefaultRepeatCount) if(
    validRepeatCount!Count
){
    mixin RepeatElementRangeMixin!Element;
    
    Count count;
    Count limit;
    
    this(typeof(this) range){
        this(range.element, range.count, range.limit);
    }
    this(Element element, Count limit, Count count = Count.init){
        this.element = element;
        this.limit = limit;
        this.count = count;
    }
    
    @property bool empty() const{
        return this.count >= this.limit;
    }
    
    void popFront(){
        this.count++;
    }
    void popBack(){
        this.count++;
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.ends : head;
}
unittest{
    tests("Repeat saving range", {
        auto input = [1, 2, 3];
        auto thrice = [1, 2, 3, 1, 2, 3, 1, 2, 3];
        tests("Infinitely", {
            auto range = input.repeatsaving;
            tests("Random access", {
                testeq(range[0], 1);
                testeq(range[1], 2);
                testeq(range[2], 3);
                testeq(range[3], 1);
            });
            test(range.head(thrice.length).equals(thrice));
            tests("Saving", {
                auto a = [1, 2, 3].repeatsaving;
                auto b = a.save;
                a.popFront();
                testeq(a.front, 2);
                testeq(b.front, 1);
            });
        });
        tests("Finitely", {
            auto range = input.repeatsaving(3);
            tests("Random access", {
                testeq(range[0], 1);
                testeq(range[1], 2);
                testeq(range[2], 3);
                testeq(range[3], 1);
            });
            testeq("Length", range.length, input.length * 3);
            test(range.equals(thrice));
        });
    });
    tests("Repeat random access range", {
        auto input = [1, 2, 3];
        auto thrice = [1, 2, 3, 1, 2, 3, 1, 2, 3];
        tests("Infinitely", {
            auto range = input.repeatrandomaccess;
            tests("Random access", {
                testeq(range[0], 1);
                testeq(range[1], 2);
                testeq(range[2], 3);
                testeq(range[3], 1);
            });
            test(range.head(thrice.length).equals(thrice));
            tests("Saving", {
                auto a = [1, 2, 3].repeatrandomaccess;
                auto b = a.save;
                a.popFront();
                testeq(a.front, 2);
                testeq(b.front, 1);
            });
        });
        tests("Finitely", {
            auto range = input.repeatrandomaccess(3);
            tests("Random access", {
                testeq(range[0], 1);
                testeq(range[1], 2);
                testeq(range[2], 3);
                testeq(range[3], 1);
            });
            testeq("Length", range.length, input.length * 3);
            test(range.equals(thrice));
            tests("Bidirectionality", {
                auto range = input.repeatrandomaccess(3);
                range.popBack();
                test(range.equals(thrice[0 .. $-1]));
            });
        });
    });
    tests("Repeat element", {
        tests("Infinitely", {
            test(6.repeat.head(3).equals([6, 6, 6]));
        });
        tests("Finitely", {
            test(6.repeat(3).equals([6, 6, 6]));
        });
    });
}
