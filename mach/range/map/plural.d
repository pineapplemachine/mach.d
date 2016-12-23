module mach.range.map.plural;

private:

import mach.meta : All, Any, Filter, AdjoinFlat, varmap, varfilter, varany, varmin;
import mach.traits : hasTrueEmptyEnum, hasFalseEmptyEnum, isInfiniteRange;
import mach.traits : hasNumericLength, hasNumericRemaining;
import mach.traits : isRange, isSlicingRange, isSavingRange;
import mach.traits : isBidirectionalRange, isRandomAccessRange;
import mach.range.asrange : asrange, validAsRange;

public:



template canMapPlural(alias transform, T...){
    enum bool canMapPlural = All!(validAsRange, T) && is(typeof({
        auto x = transform(varmap!(e => e.asrange.front)(T.init).expand);
    }));
}

template canMapPluralRange(alias transform, T...){
    enum bool canMapPluralRange = All!(isRange, T) && canMapPlural!(transform, T);
}



/// Construct a map range accepting multiple input iterables and at least one
/// transformation.
template mapplural(transformations...) if(transformations.length){
    alias transform = AdjoinFlat!transformations;
    auto mapplural(Iters...)(Iters iters) if(canMapPlural!(transform, Iters)){
        auto ranges = varmap!(e => e.asrange)(iters);
        return MapPluralRange!(transform, typeof(ranges.expand))(ranges.expand);
    }
}



/// Map range which accepts multiple input ranges and transforms each group of
/// elements into a single element belonging to the output range.
struct MapPluralRange(alias transform, Ranges...) if(canMapPluralRange!(transform, Ranges)){
    Ranges sources;
    
    this(Ranges sources){
        this.sources = sources;
    }
    
    static if(All!(hasFalseEmptyEnum, Ranges)){
        static enum bool empty = false;
    }else static if(Any!(hasTrueEmptyEnum, Ranges)){
        static enum bool empty = true;
    }else{
        @property auto empty(){
            return varany(varmap!(e => e.empty)(this.sources).expand);
        }
    }
    
    private template isInfOrHasLength(T){
        enum bool isInfOrHasLength = hasNumericLength!T || isInfiniteRange!T;
    }
    private template isInfOrHasRemaining(T){
        enum bool isInfOrHasRemaining = hasNumericRemaining!T || isInfiniteRange!T;
    }
    
    static if(All!(isInfOrHasLength, Ranges)){
        @property auto length(){
            auto withlen = varfilter!hasNumericLength(this.sources).expand;
            return withlen.varmap!(e => e.length).expand.varmin;
        }
        alias opDollar = length;
    }
    static if(All!(isInfOrHasRemaining, Ranges)){
        @property auto remaining(){
            auto withlen = varfilter!hasNumericRemaining(this.sources).expand;
            return withlen.varmap!(e => e.remaining).expand.varmin;
        }
    }
    
    @property auto ref front() in{assert(!this.empty);} body{
        return transform(varmap!(e => e.front)(this.sources).expand);
    }
    void popFront() in{assert(!this.empty);} body{
        foreach(i, _; Ranges) this.sources[i].popFront();
    }
    
    // TOOD: Fix for ranges of differing lengths
    //static if(All!(isBidirectionalRange, Ranges)){
    //    @property auto ref back(){
    //        mixin(MergeAttributeMixin!(`transform`, `.back`, Ranges));
    //    }
    //    void popBack(){
    //        foreach(i, _; Ranges) this.sources[i].popBack();
    //    }
    //}
    
    static if(All!(isRandomAccessRange, Ranges)){
        auto ref opIndex(size_t index){
            return transform(varmap!(e => e[index])(this.sources).expand);
        }
    }
    static if(All!(isSlicingRange, Ranges)){
        auto ref opSlice(size_t low, size_t high){
            return typeof(this)(varmap!(e => e[low .. high])(this.sources).expand);
        }
    }
    static if(All!(isSavingRange, Ranges)){
        @property typeof(this) save(){
            return typeof(this)(varmap!(e => e.save)(this.sources).expand);
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.range.rangeof : infrangeof;
    //import mach.range.retro : retro; // TODO
}
unittest{
    tests("Plural Map", {
        alias sumtwo = (a, b) => (a + b);
        alias sumthree = (a, b, c) => (a + b + c);
        alias product = (a, b) => (a * b);
        int[] inputa = [0, 0, 1, 1];
        int[] inputb = [1, 2, 3, 4];
        int[] inputc = [1, 2, 2, 3];
        tests("Length", {
            auto inputshort = [1, 2];
            auto inputlong = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
            testeq(mapplural!sumtwo(inputa, inputshort).length, inputshort.length);
            testeq(mapplural!sumtwo(inputa, inputlong).length, inputa.length);
            testeq(mapplural!sumthree(inputa, inputb, inputc).length, inputa.length);
            testeq(mapplural!sumthree(inputlong, inputb, inputc).length, inputa.length);
        });
        tests("Iteration", {
            test!equals(mapplural!sumtwo(inputa, inputb), [1, 2, 4, 5]);
            test!equals(mapplural!sumthree(inputa, inputb, inputc), [2, 4, 6, 8]);
        });
        //tests("Backwards", { // TODO
        //    test!equals(mapplural!sumtwo(inputa, inputb).retro, [5, 4, 2, 1]);
        //    test!equals(mapplural!sumthree(inputa, inputb, inputc).retro, [8, 6, 4, 2]);
        //});
        tests("Random access", {
            auto range = mapplural!sumtwo(inputa, inputb);
            testeq(range[0], 1);
            testeq(range[1], 2);
            testeq(range[2], 4);
            testeq(range[$-1], 5);
            testfail({range[$];});
        });
        tests("Slicing", {
            auto range = mapplural!sumtwo(inputa, inputb);
            test!equals(range[0 .. 2], [1, 2]);
            test!equals(range[2 .. $], [4, 5]);
            test!equals(range[0 .. 0], new int[0]);
            testfail({range[0 .. 10];});
        });
        tests("Multiple functions", {
            auto range = mapplural!(sumtwo, product)(inputa, inputb);
            foreach(i; 0 .. inputa.length){
                testeq(range[i][0], sumtwo(inputa[i], inputb[i]));
                testeq(range[i][1], product(inputa[i], inputb[i]));
            }
        });
        tests("Finite & Infinite inputs", {
            auto range = mapplural!sumtwo(infrangeof(10), [0, 1, 2, 3]);
            testf(range.empty);
            testeq(range.length, 4);
            test!equals(range, [10, 11, 12, 13]);
            testeq(range[0], 10);
            testeq(range[1], 11);
            testfail({range[$];});
            testeq(range.front, 10);
            //testeq(range.back, 13); // TODO
            range.popFront();
            range.popFront();
            range.popFront();
            range.popFront();
            test(range.empty);
            testfail({range.front;});
            testfail({range.popFront;});
            //testfail({range.back;}); // TODO
            //testfail({range.popBack;}); // TODO
        });
    });
}
