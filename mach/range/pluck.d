module mach.range.pluck;

private:

import mach.traits : isRange, ElementType, hasProperty;
import mach.range.asrange : validAsRange;
import mach.range.map : map;

/++ Docs

This module implements `pluck`, which is a simple abstraction of the `map`
function in `mach.range.map`.
`pluck` can be called with a template argument indicating a property to be
extracted from each element of an input iterable, or with runtime arguments
used to index the elements of the input iterable.

+/

unittest{ /// Example
    import mach.range.compare : equals;
    struct Test{int x; int y; int z;}
    // Equivalent to `input.map!(e => e.x)`.
    auto range = [Test(0, 1, 2), Test(2, 3, 4)].pluck!`x`;
    assert(range.equals(0, 2));
}

unittest{ /// Example
    import mach.range.compare : equals;
    string[] array = ["abc", "xyz", "123"];
    // Equivalent to `input.map!(e => e[0])`.
    assert(array.pluck(0).equals("ax1"));
}

public:



enum canPluckIndex(Iter, Idx) = (
    validAsRange!Iter && validPluckIndex!(Iter, Idx)
);

template validPluckIndex(Iter, Idx...){
    enum bool validPluckIndex = is(typeof((inout int = 0){
        alias Element = ElementType!Iter;
        auto element = Element.init;
        auto result = element[Idx.init];
    }));
}

enum canPluckProperty(Iter, string property) = (
    validAsRange!Iter && hasProperty!(ElementType!Iter, property)
);



/// Return a range enumerating some property of the elements in another range.
/// Really just a simple abstraction of map.
auto pluck(Iter, Idx...)(Iter iter, Idx index) if(
    Idx.length && canPluckIndex!(Iter, Idx)
){
    return map!(element => element[index])(iter);
}

/// ditto
auto pluck(string property, Iter)(auto ref Iter iter) if(
    canPluckProperty!(Iter, property)
){
    return iter.map!((e){
        mixin(`return e.` ~ property ~ `;`);
    });
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    struct PropertyPluckTest{
        int x, y;
        @property int z() const{
            return this.x + this.y;
        }
    }
}
unittest{
    tests("Pluck", {
        tests("Array index", {
            int[][] input;
            foreach(i; 0 .. 4) input ~= [0, i, i+i, i*i];
            testeq(input.pluck(0).length, 4);
            test(input.pluck(0).equals([0, 0, 0, 0]));
            test(input.pluck(1).equals([0, 1, 2, 3]));
            test(input.pluck(2).equals([0, 2, 4, 6]));
            test(input.pluck(3).equals([0, 1, 4, 9]));
        });
        tests("Associative array keys", {
            string[string][] data = [
                ["a": "apple", "b": "bear"],
                ["a": "attack", "b": "bumblebee"],
                ["a": "airplane", "b": "bin"]
            ];
            test(data.pluck("a").equals(["apple", "attack", "airplane"]));
        });
        tests("Property name", {
            PropertyPluckTest[] data = [
                PropertyPluckTest(0, 2),
                PropertyPluckTest(2, 4),
                PropertyPluckTest(4, 6)
            ];
            test(canPluckProperty!(typeof(data), `x`));
            test(canPluckProperty!(typeof(data), `y`));
            test(canPluckProperty!(typeof(data), `z`));
            testf(canPluckProperty!(typeof(data), `w`));
            test(data.pluck!`x`.equals([0, 2, 4]));
            test(data.pluck!`y`.equals([2, 4, 6]));
            test(data.pluck!`z`.equals([2, 6, 10]));
        });
    });
}
