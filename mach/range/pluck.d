module mach.range.pluck;

private:

import mach.range.asrange : validAsRange;
import mach.traits : isRange, ElementType, hasProperty;
import mach.range.map : map;

public:



enum canPluckIndex(Iter, Index) = (
    validAsRange!Iter && validPluckIndex!(Iter, Index)
);
enum canPluckIndexRange(Range, Index) = (
    isRange!Range && validPluckIndex!(Range, Index)
);

template validPluckIndex(Iter, Index){
    enum bool validPluckIndex = is(typeof((inout int = 0){
        alias Element = ElementType!Iter;
        auto element = Element.init;
        auto result = element[Index.init];
    }));
}

enum canPluckProperty(Iter, string property) = (
    validAsRange!Iter && hasProperty!(ElementType!Iter, property)
);
enum canPluckPropertyRange(Range, string property) = (
    isRange!Range && hasProperty!(ElementType!Range, property)
);



/// Return a range enumerating some property of the elements in another range.
/// Really just a simple abstraction of map.
auto pluck(Index, Iter)(Iter iter, Index index) if(canPluckIndex!(Iter, Index)){
    return map!(element => element[index])(iter);
}

private template MakePluckTransformation(alias property){
    alias MakePluckTransformation = property;
}
private template MakePluckTransformation(string property){
    mixin(`alias MakePluckTransformation = element => element.` ~ property ~ `;`);
}
/// ditto
template pluck(properties...) if(properties.length){
    import std.meta : staticMap;
    auto pluck(Iter)(Iter iter){
        return map!(staticMap!(MakePluckTransformation, properties))(iter);
    }
}



version(unittest){
    private:
    import mach.error.unit;
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
        
        int[][] input;
        foreach(i; 0 .. 4) input ~= [0, i, i+i, i*i];
        tests("Numeric index", {
            testeq(input.pluck(0).length, 4);
            test(input.pluck(0).equals([0, 0, 0, 0]));
            test(input.pluck(1).equals([0, 1, 2, 3]));
            test(input.pluck(2).equals([0, 2, 4, 6]));
            test(input.pluck(3).equals([0, 1, 4, 9]));
        });
        tests("Associative array strings", {
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
        tests("Transformation", {
            // Note: This is a pointless use case. Please use map instead.
            auto input = [0, 1, 2];
            test(input.pluck!(e => e+1).equals([1, 2, 3]));
        });
        tests("Multiple properties", {
            auto input = [[0, 1], [1, 2], [2, 3]];
            auto range = input.pluck!(`length`, `sizeof`, (e) => (e[0] + e[1]));
            testeq(range.front[0], input[0].length);
            testeq(range.front[1], input[0].sizeof);
            testeq(range.front[2], 1);
        });
    });
}
