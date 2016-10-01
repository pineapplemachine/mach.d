module mach.range.repeat;

private:

import mach.traits : isIterable, isFiniteIterable, isInfiniteIterable;
import mach.traits : isFiniteRange, isRandomAccessRange, isSavingRange;
import mach.traits : hasNumericLength;
import mach.range.asrange : asrange, validAsRange;
import mach.range.asrange : validAsRandomAccessRange, validAsSavingRange;
import mach.range.rangeof : infrangeof, finiterangeof;

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



auto repeat(Iter)(Iter iter) if(isInfiniteIterable!Iter){
    return iter;
}

auto repeat(Iter)(auto ref Iter iter, size_t count) if(
    isInfiniteIterable!Iter
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

auto repeat(Iter)(auto ref Iter iter, size_t count) if(
    canRepeatIterable!Iter
){
    static if(canRepeatRandomAccess!Iter){
        return repeatrandomaccess!(Iter)(iter, count);
    }else{
        return repeatsaving!(Iter)(iter, count);
    }
}

auto repeat(Element)(auto ref Element element) if(!validAsRange!Element){
    return repeatelement!(Element)(element);
}

auto repeat(Element)(auto ref Element element, size_t count) if(!validAsRange!Element){
    return repeatelement!(Element)(element, count);
}



auto repeatrandomaccess(Iter)(Iter iter) if(canRepeatRandomAccess!Iter){
    auto range = iter.asrange;
    return InfiniteRepeatRandomAccessRange!(typeof(range))(range);
}

auto repeatrandomaccess(Iter)(auto ref Iter iter, size_t count) if(
    canRepeatRandomAccess!Iter
){
    auto range = iter.asrange;
    return FiniteRepeatRandomAccessRange!(typeof(range))(range, count);
}

auto repeatsaving(Iter)(Iter iter) if(canRepeatSaving!Iter){
    auto range = iter.asrange;
    return InfiniteRepeatSavingRange!(typeof(range))(range);
}

auto repeatsaving(Iter)(auto ref Iter iter, size_t count) if(
    canRepeatSaving!Iter
){
    auto range = iter.asrange;
    return FiniteRepeatSavingRange!(typeof(range))(range, count);
}

auto repeatelement(Element)(auto ref Element element){
    return infrangeof(element);
}

auto repeatelement(Element)(auto ref Element element, size_t count){
    return finiterangeof(count, element);
}



private template RepeatSavingRangeMixin(Range, string popfrontstr){
    Range* source;
    Range original;
    
    import core.stdc.stdlib : malloc, free;
    import core.stdc.string : memcpy;
    
    @nogc void repeat(in Range from){ // TODO: Is there a better way to do this?
        if(this.source) free(cast(void*) this.source);
        this.source = cast(Range*) malloc(Range.sizeof);
        assert(this.source !is null, "Failed to allocate memory.");
        memcpy(cast(void*) this.source, &from, Range.sizeof);
    }
    
    this(this){
        auto from = *this.source;
        this.source = null;
        this.repeat(from);
    }
    ~this(){
        if(this.source){
            free(this.source);
            this.source = null;
        }
    }
    
    @property auto ref front(){
        return this.source.front;
    }
    void popFront(){
        mixin(popfrontstr);
    }
    
    static if(isRandomAccessRange!Range && hasNumericLength!Range){
        auto opIndex(size_t index){
            return (*this.source)[index % this.source.length];
        }
    }
    
    @property auto ref save(){
        return typeof(this)(this);
    }
}

private template RepeatRandomAccessRangeMixin(Range){
    Range source;
    size_t frontindex;
    size_t backindex;
    
    alias index = frontindex;
    
    @property auto ref front(){
        return this.source[this.frontindex];
    }
    @property auto ref back(){
        return this.source[this.backindex - 1];
    }
    
    auto opIndex(in size_t index) in{
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
struct InfiniteRepeatRandomAccessRange(Range) if(
    canRepeatRandomAccessRange!Range
){
    Range source;
    size_t frontindex;
    size_t backindex;
    
    this(Range source, size_t frontindex = 0){
        this(source, frontindex, source.length);
    }
    this(Range source, size_t frontindex, size_t backindex){
        this.source = source;
        this.frontindex = frontindex;
        this.backindex = backindex;
    }
    
    enum bool empty = false;
    
    @property auto ref front(){
        return this.source[this.frontindex];
    }
    @property auto ref back(){
        return this.source[this.backindex - 1];
    }
    
    void popFront(){
        this.frontindex = (this.frontindex + 1) % cast(size_t) this.source.length;
    }
    void popBack(){
        this.backindex--;
        if(this.backindex == 0) this.backindex = cast(size_t) this.source.length;
    }
    
    auto opIndex(in size_t index) in{assert(index >= 0);} body{
        return this.source[index % cast(size_t) this.source.length];
    }
    auto opSlice(in size_t low, in size_t high) in{
        assert(low >= 0 && high >= low);
    }body{
        return typeof(this)(
            this.source,
            low % cast(size_t) this.source.length,
            high % cast(size_t) this.source.length
        );
    }
    
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save, this.frontindex, this.backindex);
        }
    }
}

/// Repeat a range with random access a given number of times
struct FiniteRepeatRandomAccessRange(Range) if(
    canRepeatRandomAccessRange!Range
){
    mixin RepeatRandomAccessRangeMixin!(Range);
    
    size_t limit; // Number of times the source range is repeated
    size_t count; // Number of times the source range has been fully consumed
    
    this(typeof(this) range){
        this(range.source, range.limit, range.count, range.frontindex, range.backindex);
    }
    this(Range source, size_t limit, size_t frontindex = 0){
        this(source, limit, 0, frontindex, cast(size_t) source.length);
    }
    this(Range source, size_t limit, size_t count, size_t frontindex, size_t backindex){
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
            this.backindex = cast(size_t) this.source.length;
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
struct FiniteRepeatSavingRange(Range) if(
    canRepeatSavingRange!Range
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
    
    size_t count; /// Cycle iteration is currently on
    size_t limit; /// Maximum number of cycles before emptiness
    
    this(typeof(this) range){
        this.count = range.count;
        this.limit = range.limit;
        this.original = range.original;
        this.repeat(*range.source);
    }
    this(Range source, size_t limit){
        this(source, 0, limit);
    }
    this(Range source, size_t count, size_t limit){
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



version(unittest){
    private:
    import mach.test;
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
            testeq(range.length, input.length * 3);
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
            testeq(range.length, input.length * 3);
            test(range.equals(thrice));
            tests("Bidirectionality", {
                auto range = input.repeatrandomaccess(3);
                range.popBack();
                test(range.equals!false(thrice[0 .. $-1]));
            });
        });
    });
    tests("Repeat element", {
        tests("Infinitely", {
            test!equals(6.repeat.head(3), [6, 6, 6]);
        });
        tests("Finitely", {
            test!equals(6.repeat(3), [6, 6, 6]);
        });
    });
}
