module mach.range.map.templates;

private:

import std.meta : allSatisfy;
import mach.traits : isIterable, isRange, isElementTransformation;
import mach.range.asrange : validAsRange;

public:



/// Whether a sequence of iterables can be mapped with a given transformation.
template canMap(alias transform, Iters...){
    static if(allSatisfy!(validAsRange, Iters)){
        enum bool canMap = isElementTransformation!(transform, Iters);
    }else{
        enum bool canMap = false;
    }
}

/// Whether a sequence of ranges can be mapped with a given transformation.
template canMapRanges(alias transform, Ranges...){
    static if(allSatisfy!(isRange, Ranges)){
        enum bool canMapRanges = isElementTransformation!(transform, Ranges);
    }else{
        enum bool canMapRanges = false;
    }
}

/// Whether a given range can be mapped with a given transformation.
enum canMapRange(alias transform, Range) = (
    canMapRanges!(transform, Range)
);

/// Take a sequence of transformation functions and, when there is a single
/// transformation, return it; when there are multiple transformations, adjoin
/// them into a single transformation function which returns a tuple wherein
/// each element is the result of its corresponding transformation.
template AdjoinTransformations(transformations...){
    static if(transformations.length == 0){
        alias AdjoinTransformations = (e) => (e);
    }else static if(transformations.length == 1){
        alias AdjoinTransformations = transformations[0];
    }else{
        import std.functional : adjoin;
        alias AdjoinTransformations = adjoin!transformations;
    }
}



unittest{
    alias twice = (n) => (n + n);
    alias sum = (a, b) => (a + b);
    static assert(canMap!(twice, int[]));
    static assert(canMap!(sum, int[], int[]));
    static assert(canMap!(sum, int[], real[]));
    static assert(!canMap!(twice, int));
}
