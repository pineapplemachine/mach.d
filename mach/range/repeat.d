module mach.range.repeat;

private:

import mach.types : Rebindable;
import mach.traits : isIterable, isFiniteIterable, isInfiniteIterable;
import mach.traits : isFiniteRange, isRandomAccessRange, isSavingRange;
import mach.traits : isBidirectionalRange, hasNumericLength;
import mach.range.asrange : asrange, validAsRange;
import mach.range.asrange : validAsRandomAccessRange, validAsSavingRange;
import mach.range.rangeof : infrangeof, finiterangeof;
import mach.error : enforcebounds;

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
    Range source;
    size_t limit; // Number of times the source range is repeated
    size_t count; // Number of times the source range has been fully consumed
    size_t frontindex;
    size_t backindex;
    
    // TODO: Slicing
    
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
    
    @property bool empty() const{
        return this.count >= (this.limit - (this.frontindex >= this.backindex));
    }
    @property auto length() const{
        return this.source.length * this.limit;
    }
    
    @property auto ref front() in{assert(!this.empty);} body{
        return this.source[this.frontindex];
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
        if(this.frontindex >= this.source.length){
            this.count++;
            this.frontindex = 0;
        }
    }
    
    @property auto ref back() in{assert(!this.empty);} body{
        return this.source[this.backindex - 1];
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
        if(this.backindex == 0){
            this.count++;
            this.backindex = cast(size_t) this.source.length;
        }
    }
    
    auto opIndex(in size_t index) in{
        static if(hasNumericLength!(typeof(this))) enforcebounds(index, this);
        else assert(index >= 0);
    }body{
        return this.source[cast(size_t)(index % this.source.length)];
    }
    
    @property auto ref save(){
        return typeof(this)(
            this.source, this.limit, this.count,
            this.frontindex, this.backindex
        );
    }
}



/// Repeat a range with saving infinitely
struct InfiniteRepeatSavingRange(Range) if(canRepeatSavingRange!Range){
    static enum bool isBidirectional = isBidirectionalRange!Range;
    
    Range source;
    Rebindable!Range forward = void;
    static if(isBidirectional) Rebindable!Range backward = void;
    
    this(Range source){
        this.source = source;
        this.forward = this.source.save;
        static if(isBidirectional) this.backward = this.source.save;
    }
    static if(!isBidirectional){
        this(Range source, Rebindable!Range forward){
            this.source = source;
            this.forward = forward;
        }
    }else{
        this(Range source, Rebindable!Range forward, Rebindable!Range backward){
            this.source = source;
            this.forward = forward;
            this.backward = backward;
        }
    }
    
    static enum bool empty = false;
    
    @property auto ref front(){
        return this.forward.front;
    }
    void popFront(){
        this.forward.popFront();
        if(this.forward.empty) this.forward = this.source.save;
    }
    
    static if(isBidirectional){
        @property auto ref back(){
            return this.backward.back;
        }
        void popBack(){
            this.backward.popBack();
            if(this.backward.empty) this.backward = this.source.save;
        }
    }
    
    static if(isRandomAccessRange!Range && hasNumericLength!Range){
        auto opIndex(in size_t index){
            return this.source[cast(size_t)(index % this.source.length)];
        }
    }
    
    @property typeof(this) save(){
        static if(!isBidirectional){
            return typeof(this)(this.source, this.forward.save);
        }else{
            return typeof(this)(this.source, this.forward.save, this.backward.save);
        }
    }
}

/// Repeat a range with saving a given number of times
struct FiniteRepeatSavingRange(Range) if(
    canRepeatSavingRange!Range
){
    Range source;
    Rebindable!Range forward = void;
    
    size_t count; /// Cycle iteration is currently on
    size_t limit; /// Maximum number of cycles before emptiness
    
    // TODO: Bidirectionality
    
    this(Range source, size_t limit){
        this(source, 0, limit);
    }
    this(Range source, size_t count, size_t limit){
        this.count = count;
        this.limit = limit;
        this.source = source;
        this.forward = this.source.save;
    }
    
    @property bool empty() const{
        return this.count >= this.limit;
    }
    
    @property auto ref front() in{assert(!this.empty);} body{
        return this.forward.front;
    }
    void popFront() in{assert(!this.empty);} body{
        this.forward.popFront();
        if(this.forward.empty){
            this.forward = this.source.save;
            this.count++;
        }
    }
    
    static if(hasNumericLength!Range){
        @property auto length(){
            return this.source.length * limit;
        }
        alias opDollar = length;
    }
    
    static if(isRandomAccessRange!Range && hasNumericLength!Range){
        auto opIndex(in size_t index) in{
            enforcebounds(index, this);
        }body{
            return this.source[cast(size_t)(index % this.source.length)];
        }
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
