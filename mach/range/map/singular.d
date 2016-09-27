module mach.range.map.singular;

private:

import mach.meta : AdjoinFlat;
import mach.traits : isRange, isBidirectionalRange, isSavingRange;
import mach.traits : isRandomAccessRange, isSlicingRange, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeEmptyMixin, MetaRangeLengthMixin;

public:



template canMapSingular(alias transform, T){
    enum bool canMapSingular = validAsRange!T && is(typeof({
        auto x = transform(T.init.asrange.front);
    }));
}

template canMapSingularRange(alias transform, T){
    enum bool canMapSingularRange = isRange!T && canMapSingular!(transform, T);
}



/// Returns a range whose elements are those of the given iterable transformed
/// by some function or functions.
template mapsingular(transformations...) if(transformations.length){
    alias transform = AdjoinFlat!transformations;
    auto mapsingular(Iter)(Iter iter) if(canMapSingular!(transform, Iter)){
        auto range = iter.asrange;
        return MapSingularRange!(transform, typeof(range))(range);
    }
}



struct MapSingularRange(alias transform, Range) if(canMapSingularRange!(transform, Range)){
    mixin MetaRangeEmptyMixin!Range;
    mixin MetaRangeLengthMixin!Range;
    
    Range source;
    
    this(Range source){
        this.source = source;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        return transform(this.source.front);
    }
    void popFront() in{assert(!this.empty);} body{
        this.source.popFront();
    }
    static if(isBidirectionalRange!Range){
        @property auto back() in{assert(!this.empty);} body{
            return transform(this.source.back);
        }
        void popBack() in{assert(!this.empty);} body{
            this.source.popBack();
        }
    }
    static if(isRandomAccessRange!Range){
        auto ref opIndex(size_t index){
            return transform(this.source[index]);
        }
    }
    static if(isSlicingRange!Range){
        typeof(this) opSlice(size_t low, size_t high){
            return typeof(this)(this.source[low .. high]);
        }
    }
    static if(isSavingRange!Range){
        @property typeof(this) save(){
            return typeof(this)(this.source.save);
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Map", {
        alias square = (n) => (n * n);
        alias cube = (n) => (n * n * n);
        tests("Single function", {
            test!equals([1, 2, 3, 4].mapsingular!square, [1, 4, 9, 16]);
            test!equals([1, 1, 1, 1].mapsingular!square, [1, 1, 1, 1]);
            tests("Not empty", {
                auto range = [1, 2, 3].mapsingular!square;
                testeq(range.length, 3);
                testf(range.empty);
                tests("Random access", {
                    testeq(range[0], 1);
                    testeq(range[1], 4);
                    testeq(range[2], 9);
                    testfail({range[3];});
                });
                tests("Slicing", {
                    test!equals(range[0 .. 0], new int[0]);
                    test!equals(range[0 .. 1], [1]);
                    test!equals(range[0 .. 2], [1, 4]);
                    test!equals(range[0 .. $], [1, 4, 9]);
                });
                tests("Bidirectionality & Saving", {
                    testeq(range.remaining, 3);
                    testeq(range.front, 1);
                    testeq(range.back, 9);
                    range.popFront();
                    testeq(range.remaining, 2);
                    testeq(range.front, 4);
                    range.popBack();
                    testeq(range.front, 4);
                    testeq(range.back, 4);
                    auto saved = range.save();
                    range.popFront();
                    test(range.empty);
                    testeq(range.remaining, 0);
                    testfail({range.front;});
                    testfail({range.popFront;});
                    testfail({range.back;});
                    testfail({range.popBack;});
                    testf(saved.empty);
                });
            });
            tests("Empty input", {
                auto empty = new int[0];
                auto range = empty.mapsingular!square;
                test(range.empty);
                testeq(range.length, 0);
                test!equals(range, empty);
                test!equals(range[0 .. 0], empty);
                testfail({range[0];});
                testfail({range.front;});
                testfail({range.popFront;});
                testfail({range.back;});
                testfail({range.popBack;});
            });
        });
        tests("Multiple functions", {
            auto input = [1, 2, 3];
            auto range = input.mapsingular!(square, cube);
            testeq(range[0][0], 1);
            testeq(range[0][1], 1);
            testeq(range[1][0], 4);
            testeq(range[1][1], 8);
            testeq(range[2][0], 9);
            testeq(range[2][1], 27);
        });
        tests("Static array", {
            int[3] input = [1, 2, 3];
            auto range = input.mapsingular!(square);
            test(range.equals([1, 4, 9]));
            test(range[0 .. 2].equals([1, 4]));
        });
    });
}
