module mach.range.rotate;

private:

import std.meta : allSatisfy, staticMap;
import mach.traits : isFiniteIterable, isFiniteRange;
import mach.traits : canCast, isMutableFrontRange, ElementType;
import mach.range.asrange : asrange, validAsMutableFrontRange;
import mach.range.meta : MetaMultiRangeWrapperMixin;

public:



enum canRotate(Iters...) = (
    allSatisfy!(validAsMutableFrontRange, Iters) &&
    allSatisfy!(isFiniteIterable, Iters)
);

enum canRotateRanges(Ranges...) = (
    allSatisfy!(isMutableFrontRange, Ranges) &&
    allSatisfy!(isFiniteRange, Ranges)
);



/// Eagerly rotates the contents of some iterables in-place, up to the length of
/// the shortest iterable.
void rotate(Iters...)(Iters iters) if(canRotate!Iters){
    mixin(MetaMultiRangeWrapperMixin!(`rotateranges`, Iters));
}

void rotateranges(Ranges...)(Ranges ranges) if(canRotateRanges!Ranges){
    static if(Ranges.length > 1){
        alias Elements = staticMap!(ElementType, Ranges);
        while(true){
            foreach(i, _; Ranges){
                if(ranges[i].empty) goto endrotate;
            }
            auto tail = ranges[$-1].front;
            foreach_reverse(i, _; Ranges){
                static if(i == 0){
                    ranges[i].front = tail;
                }else{
                    ranges[i].front = ranges[i - 1].front;
                }
                ranges[i].popFront();
            }
        }
        endrotate:
        return;
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Rotate", {
        tests("No inputs", {
            rotate();
        });
        tests("One input", {
            int[] input = [1, 2, 3];
            rotate(input);
            testeq(input, [1, 2, 3]);
        });
        tests("Two inputs", {
            int[] inputa = [1, 2, 3];
            int[] inputb = [3, 2, 1, 0];
            rotate(inputa, inputb);
            testeq(inputa, [3, 2, 1]);
            testeq(inputb, [1, 2, 3, 0]);
        });
        tests("Three inputs", {
            int[] inputa = [1, 2, 3];
            int[] inputb = [3, 2, 1, 0];
            int[] inputc = [4, 5, 6];
            rotate(inputa, inputb, inputc);
            testeq(inputa, [4, 5, 6]);
            testeq(inputb, [1, 2, 3, 0]);
            testeq(inputc, [3, 2, 1]);
        });
    });
}
