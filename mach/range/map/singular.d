module mach.range.map.singular;

private:

import mach.traits : isRandomAccessRange, isSlicingRange, ElementType;
import mach.range.asrange : asrange;
import mach.range.meta : MetaRangeMixin;
import mach.range.map.templates : canMap, canMapRange;

public:



/// Returns a range whose elements are those of the given iterable transformed
/// by some function.
auto mapsingular(alias transform, Iter)(Iter iter) if(canMap!(transform, Iter)){
    auto range = iter.asrange;
    return MapSingularRange!(transform, typeof(range))(range);
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
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Map", {
        alias square = (n) => (n * n);
        int[] ones = [1, 1, 1, 1];
        int[] empty = new int[0];
        test([1, 2, 3, 4].mapsingular!square.equals([1, 4, 9, 16]));
        test(ones.mapsingular!square.equals(ones));
        test("Empty input", empty.mapsingular!square.equals(empty));
        testeq("Length", [1, 2, 3].mapsingular!square.length, 3);
        testeq("Random access", [2, 3].mapsingular!square[1], 9);
        test("Slicing", [1, 2, 3, 4].mapsingular!square[1 .. $-1].equals([4, 9]));
    });
}
