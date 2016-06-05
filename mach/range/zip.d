module mach.range.zip;

private:

import std.typecons : tuple;
import mach.range.merge : merge, canMerge, canMergeRanges;
import mach.range.meta : MetaMultiRangeWrapperMixin;

public:



enum canZip(Iters...) = canMerge!(tuple, Iters);

enum canZipRanges(Ranges...) = canMergeRanges!(tuple, Ranges);



auto zip(Iters...)(Iters iters) if(canZip!Iters){
    mixin(MetaMultiRangeWrapperMixin!(`zipranges`, Iters));
}

auto zipranges(Ranges...)(Ranges ranges) if(canZipRanges!Ranges){
    return merge!tuple(ranges);
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Zip", {
        auto inputa = ['h', 'a', 'y'];
        auto inputb = ['o', 'r', 'o'];
        auto inputc = ['w', 'e', 'u'];
        auto range = zip(inputa, inputb, inputc);
        testeq(range[0], tuple('h', 'o', 'w'));
        testeq(range[1], tuple('a', 'r', 'e'));
        testeq(range[2], tuple('y', 'o', 'u'));
    });
}
