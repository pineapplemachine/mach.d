module mach.range.rotate;

private:

import mach.meta : Any, All, Map, varmap;
import mach.traits : isFiniteIterable, isFiniteRange;
import mach.traits : isMutableFrontRange, ElementType;
import mach.range.asrange : asrange, validAsMutableFrontRange;

/++ Docs

The `rotate` function accepts any number of input iterables, where all of
the iterables are valid as ranges which allow modification of their front
element.
Up to the length of its shortest input, `rotate` will eagerly rotate the
positions of elements in the iterables such that —
in the case of three inputs, for example —
the elements of the first input are placed into the second,
the elements of the second input are placed into the third,
and the elements of the third input are placed into the first.

+/

unittest{ /// Example
    int[] a = [0, 1, 2];
    int[] b = [3, 4, 5];
    int[] c = [6, 7, 8];
    rotate(a, b, c);
    assert(a == [6, 7, 8]); // Previously the elements of c.
    assert(b == [0, 1, 2]); // Previously the elements of a.
    assert(c == [3, 4, 5]); // Previously the elements of b.
}

unittest{ /// Example
    // Rotation is performed only up to the length of the shortest input.
    int[] a = [0, 1, 2, 3];
    int[] b = [10, 11];
    rotate(a, b);
    assert(a == [10, 11, 2, 3]);
    assert(b == [0, 1]);
}

/++ Docs

In the case of `rotate` receiving one or fewer inputs, no operation is actually
performed.

+/

unittest{ /// Example
    int[] a = [0, 1, 2, 3];
    rotate(a); // Does nothing.
}

unittest{ /// Example
    rotate(); // Valid, but also does nothing.
}

public:



/// Determine whether rotation is a meaningful operation for some inputs.
template canRotate(T...){
    static if(T.length == 0){
        enum bool canRotate = true;
    }else{
        enum bool canRotate = (
            All!(validAsMutableFrontRange, T) &&
            Any!(isFiniteIterable, T)
        );
    }
}



/// Eagerly rotates the contents of some iterables in-place, up to the length of
/// the shortest iterable.
void rotate(Iters...)(auto ref Iters iters) if(canRotate!Iters){
    static if(Iters.length > 1){
        auto ranges = iters.varmap!(e => e.asrange);
        alias Ranges = typeof(ranges.expand);
        alias Elements = Map!(ElementType, Ranges);
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
    import mach.test;
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
