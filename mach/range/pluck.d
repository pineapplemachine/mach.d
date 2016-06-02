module mach.range.pluck;

private:

import std.meta : AliasSeq;
import std.traits : ReturnType, isImplicitlyConvertible;
import mach.range.asrange : asrange, validAsRange;
import mach.traits : isRange, isIndexedRange, ElementType, hasProperty;
import mach.traits : IndexParameters;
import mach.range.meta : MetaRangeMixin;

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



auto pluck(Index, Iter)(Iter iter, Index index) if(canPluckIndex!(Iter, Index)){
    auto range = iter.asrange;
    return PluckRange!(typeof(range), Index)(range, index);
}

auto pluck(string property, Iter)(Iter iter) if(canPluckProperty!(Iter, property)){
    auto range = iter.asrange;
    return PropertyPluckRange!(property, typeof(range))(range);
}



struct PluckRange(Range, Index) if(canPluckIndexRange!(Range, Index)){
    mixin MetaRangeMixin!(
        Range, `source`,
        `Empty Length Dollar Save Back`,
        `return this.source.front[this.index];`,
        `this.source.popFront();`
    );
    
    Range source;
    Index index;
    
    this(typeof(this) range){
        this(range.source, range.index);
    }
    this(Range source, Index index){
        this.source = source;
        this.index = index;
    }
    
    static if(isIndexedRange!Range){
        auto opIndex(IndexParameters!Range index){
            return this.source[index][this.index];
        }
    }
    
    // TODO: Slice
}

struct PropertyPluckRange(string property, Range) if(canPluckPropertyRange!(Range, property)){
    mixin MetaRangeMixin!(
        Range, `source`,
        `Empty Length Dollar Save Back`,
        `return this.source.front.` ~ property ~ `;`,
        `this.source.popFront();`
    );
    
    Range source;
    
    this(typeof(this) range){
        this(range.source);
    }
    this(Range source){
        this.source = source;
    }
    
    static if(isIndexedRange!Range){
        auto opIndex(IndexParameters!Range index){
            mixin(`return this.source[index].` ~ property ~ `;`);
        }
    }
    
    // TODO: Slice
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

        tests("Single index", {
            tests("Numeric", {
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
        });
    });
}
