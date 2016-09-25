module mach.range.map.singular;

private:

import mach.traits : isRandomAccessRange, isSlicingRange, ElementType;
import mach.range.asrange : asrange;
import mach.range.meta : MetaRangeMixin;
import mach.range.map.templates : canMap, canMapRange, AdjoinTransformations;

public:



/// Returns a range whose elements are those of the given iterable transformed
/// by some function or functions.
template mapsingular(transformations...) if(transformations.length){
    alias transform = AdjoinTransformations!transformations;
    auto mapsingular(Iter)(Iter iter) if(canMap!(transform, Iter)){
        auto range = iter.asrange;
        return MapSingularRange!(transform, typeof(range))(range);
    }
}



struct MapSingularRange(alias transform, Range) if(canMapRange!(transform, Range)){
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Length Dollar Save Back`,
        `return transform(this.source.front);`,
        `this.source.popFront();`
    );
    
    Range source;
    
    this(typeof(this) range){
        this(range.source);
    }
    this(Range source){
        this.source = source;
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
            int[] ones = [1, 1, 1, 1];
            int[] empty = new int[0];
            test([1, 2, 3, 4].mapsingular!square.equals([1, 4, 9, 16]));
            test(ones.mapsingular!square.equals(ones));
            // Empty input
            test(empty.mapsingular!square.equals(empty));
            // Length
            testeq([1, 2, 3].mapsingular!square.length, 3);
            // Random access
            testeq([2, 3].mapsingular!square[1], 9);
            // Slicing
            test([1, 2, 3, 4].mapsingular!square[1 .. $-1].equals([4, 9]));
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
