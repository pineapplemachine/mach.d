module mach.range.chain.iterable;

private:

import mach.traits : ElementType, hasNumericLength, isRandomAccessIterable;
import mach.traits : isRange, isFiniteRange, isSavingRange, isRandomAccessRange;
import mach.traits : isArray, isIterable, isIterableOf, isFiniteIterable;
import mach.range.asrange : asrange, validAsRange, AsRangeType;
import mach.range.reduce : reduce;

public:



/// Can an iterable of iterables be chained?
enum canChainIterableOfIterables(Iter) = (
    canChainRandomAccessIterable!Iter ||
    canChainForwardIterable!Iter
);

template canChainRandomAccessIterable(Iter){
    static if(isRandomAccessIterable!Iter){
        enum bool canChainRandomAccessIterable = (
            hasNumericLength!Iter &&
            hasNumericLength!(ElementType!Iter) &&
            isIterableOf!(Iter, isFiniteIterable) &&
            isIterableOf!(Iter, isRandomAccessIterable)
        );
    }else{
        enum bool canChainRandomAccessIterable = false;
    }
}

enum canChainForwardIterable(Iter) = (
    validAsRange!Iter && isIterableOf!(Iter, isIterable)
);

enum canChainForwardIterableRange(Range) = (
    isRange!Iter && isIterableOf!(Range, isIterable)
);



auto ref chainiter(Iter)(auto ref Iter iter) if(canChainIterableOfIterables!Iter){
    static if(canChainRandomAccessIterable!Iter){
        return chainiterrandomaccess(iter);
    }else{
        return chainiterforward(iter);
    }
}

auto ref chainiterrandomaccess(Iter)(auto ref Iter iter) if(canChainRandomAccessIterable!Iter){
    return ChainRandomAccessIterablesRange!(typeof(iter))(iter);
}

auto ref chainiterforward(Iter)(auto ref Iter iter) if(canChainForwardIterable!Iter){
    auto range = iter.asrange;
    return ChainForwardIterablesRange!(typeof(range))(range);
}



/// Chain the iterables contained within some iterable, where both the
/// containing and contained iterables provide random access. Supports more
/// operations than its counterpart that operates on iterables without requiring
/// random access.
struct ChainRandomAccessIterablesRange(Iter) if(canChainRandomAccessIterable!Iter){
    Iter source;
    size_t frontiter; /// Index of source for front
    size_t frontindex; /// Index of current iterable for front
    size_t backiter; /// Index of source for back
    size_t backindex; /// Index of current iterable for back
    
    this(typeof(this) range){
        this(
            range.source, range.frontiter, range.frontindex,
            range.backiter, range.backindex
        );
    }
    this(Iter source){
        this(
            source, 0, 0, source.length,
            source.length > 0 ? source[source.length - 1].length : 0
        );
        this.searchFront();
        this.searchBack();
    }
    this(
        Iter source, size_t frontiter, size_t frontindex,
        size_t backiter, size_t backindex
    ){
        this.source = source;
        this.frontiter = frontiter;
        this.frontindex = frontindex;
        this.backiter = backiter;
        this.backindex = backindex;
    }
    
    @property bool empty(){
        return(
            this.frontiter >= this.backiter || (
                this.frontindex >= this.backindex &&
                this.frontiter >= (this.backiter - 1)
            )
        );
    }
    @property auto length(){
        alias lengthsum = (size_t len, r) => (len + r.length);
        return this.source.reduce!lengthsum(cast(size_t) 0);
    }
    alias opDollar = length;

    @property auto ref front() in{assert(!this.empty);} body{
        return this.source[this.frontiter][this.frontindex];
    }
    void popFront() in{assert(!this.empty);} body{
        this.frontindex++;
        this.searchFront();
    }
    void searchFront(){
        while(
            this.frontiter < this.backiter &&
            this.frontindex >= this.source[this.frontiter].length
        ){
            this.frontiter++;
            this.frontindex = 0;
        }
    }
    
    @property auto ref back() in{assert(!this.empty);} body{
        return this.source[this.backiter - 1][this.backindex - 1];
    }
    void popBack() in{assert(!this.empty);} body{
        this.backindex--;
        this.searchBack();
    }
    void searchBack(){
        while(
            this.backindex <= 0 &&
            this.backiter > this.frontiter
        ){
            this.backiter--;
            if(this.backiter > this.frontiter){
                this.backindex = this.source[this.backiter - 1].length;
            }
        }
    }
    
    auto ref opIndex(in size_t index) in{
        assert(index >= 0 && index < this.length);
    }body{
        size_t offset = 0;
        for(size_t i = 0; i < this.source.length; i++){
            auto iter = this.source[i];
            auto j = index - offset;
            if(j < iter.length) return iter[j];
            offset += iter.length;
        }
        assert(false);
    }
    
    // TODO: Slice, Mutability
    
    static if(isSavingRange!Iter){
        @property typeof(this) save(){
            return typeof(this)(
                this.source.save, this.frontiter, this.frontindex,
                this.backiter, this.backindex
            );
        }
    }else static if(isArray!Iter){
        @property typeof(this) save(){
            return typeof(this)(
                this.source, this.frontiter, this.frontindex,
                this.backiter, this.backindex
            );
        }
    }
}



/// Chain the iterables contained within some iterable that is valid as a range.
struct ChainForwardIterablesRange(Range) if(canChainForwardIterable!Range){
    alias SubRange = AsRangeType!(ElementType!Range);
    
    Range source;
    SubRange current;
    size_t tracklength;
    
    this(typeof(this) range){
        this(range.source, range.current);
    }
    this(Range source){
        this.source = source;
        while(this.current.empty && !this.source.empty){
            this.current = this.source.front.asrange;
            this.tracklength += this.current.length;
            this.source.popFront();
        }
    }
    this(Range source, SubRange current){
        this.source = source;
        this.current = current;
    }
    
    static if(isFiniteRange!Range && isFiniteRange!SubRange){
        @property bool empty(){
            return this.current.empty;
        }
        static if(hasNumericLength!SubRange){
            @property auto length(){
                alias lengthsum = (size_t len, r) => (len + r.length);
                return this.source.reduce!lengthsum(cast(size_t) 0) + this.tracklength;
            }
            alias opDollar = length;
        }
    }else{
        enum bool empty = false;
    }
    
    @property auto ref front() in{assert(!this.empty);} body{
        return this.current.front;
    }
    void popFront() in{assert(!this.empty);} body{
        this.current.popFront();
        while(this.current.empty && !this.source.empty){
            this.current = this.source.front.asrange;
            this.tracklength += this.current.length;
            this.source.popFront();
        }
    }
    
    static if(
        isRandomAccessRange!Range &&
        isRandomAccessIterable!(ElementType!Range) &&
        hasNumericLength!(ElementType!Range)
    ){
        auto ref opIndex(in size_t index) in{
            assert(index >= 0 && index < this.length);
        }body{
            size_t offset = 0;
            for(size_t i = 0; i < this.source.length; i++){
                auto iter = this.source[i];
                auto j = index - offset;
                if(j < iter.length) return iter[j];
                offset += iter.length;
            }
            assert(false);
        }
    }
    
    // TODO: Slice, Mutability
    
    static if(isSavingRange!Range && isSavingRange!SubRange){
        @property typeof(this) save(){
            return typeof(this)(this.source.save, this.current.save);
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.retro : retro;
    template ChainTestCommon(alias chainfunc){
        void ChainTestCommon(){
            int[][] input = [[1, 2], [3, 4], [5]];
            test("Iteration",
                chainfunc(input).equals([1, 2, 3, 4, 5])
            );
            tests("Length", {
                auto range = chainfunc(input);
                while(!range.empty){
                    testeq(range.length, 5);
                    range.popFront();
                }
            });
            tests("Empty iterables", {
                int[][] inputa = [[], [1], [], []];
                int[][] inputb = [[], [], []];
                string[] inputc = [""];
                string[] inputd = [];
                testeq(chainfunc(inputa).length, 1);
                test(chainfunc(inputa).equals([1]));
                test(chainfunc(inputb).empty);
                foreach(b; inputb){}
                test(chainfunc(inputc).empty);
                foreach(c; inputc){}
                test(chainfunc(inputd).empty);
                foreach(d; inputd){}
            });
            tests("Random access", {
                auto range = chainfunc(input);
                testeq(range[0], 1);
                testeq(range[1], 2);
                testeq(range[2], 3);
                testeq(range[3], 4);
                testeq(range[$-1], 5);
            });
        }
    }
}
unittest{
    tests("Chain", {
        tests("Forward", {
            ChainTestCommon!chainiterforward();
        });
        tests("Random Access", {
            ChainTestCommon!chainiterrandomaccess();
            int[][] input = [[1, 2], [3, 4], [5]];
            tests("Backwards", {
                input.chainiterrandomaccess.retro.equals([5, 4, 3, 2, 1]);
            });
            tests("Bidirectionality", {
                auto range = input.chainiterrandomaccess;
                testeq(range.front, 1);
                testeq(range.back, 5);
                range.popFront(); range.popBack();
                testeq(range.front, 2);
                testeq(range.back, 4);
                range.popFront();
                testeq(range.front, 3);
                range.popBack();
                testeq(range.back, 3);
                range.popFront();
                test(range.empty);
            });
        });
    });
}
