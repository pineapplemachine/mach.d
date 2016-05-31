module mach.range.pluck;

private:

import std.meta : AliasSeq;
import std.traits : ReturnType, isImplicitlyConvertible;
import mach.range.asrange : asrange, validAsRange;
import mach.traits : isRange, isIndexedRange, ElementType, hasProperty;
import mach.traits : hasSingleIndexParameter, SingleIndexParameter;
import mach.traits : IndexParameters;
import mach.range.metarange : MetaRangeMixin;

public:



enum canPluck(Iter) = (
    validAsRange!Iter && hasSingleIndexParameter!(ElementType!Iter)
);
enum canPluckRange(Range) = (
    isRange!Range && hasSingleIndexParameter!(ElementType!Range)
);

template PluckIndexParameter(Iter) if(canPluck!Iter){
    alias PluckIndexParameter = SingleIndexParameter!(ElementType!Iter);
}

enum canPluckProperty(Iter, string property) = (
    validAsRange!Iter && hasProperty!(ElementType!Iter, property)
);
enum canPluckPropertyRange(Range, string property) = (
    isRange!Range && hasProperty!(ElementType!Range, property)
);



auto pluck(Index, Iter)(
    Iter iter, Index index
) if(canPluck!Iter && isImplicitlyConvertible!(Index, PluckIndexParameter!Iter)){
    auto range = iter.asrange;
    return PluckRange!(typeof(range))(range, index);
}

auto pluck(Index, Iter)(
    Iter iter, Index[] indexes
) if(canPluck!Iter && isImplicitlyConvertible!(Index[], PluckIndexParameter!Iter[])){
    auto range = iter.asrange;
    return MultiPluckRange!(typeof(range))(range, indexes);
}

auto pluck(string property, Iter)(
    Iter iter
) if(canPluckProperty!(Iter, property)){
    auto range = iter.asrange;
    return PropertyPluckRange!(property, typeof(range))(range);
}

// TODO: MultiPropertyPluckRange



struct PluckRange(Range) if(canPluckRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`,
        `Empty Length Dollar Save Back`,
        `return this.source.front[this.index];`,
        `this.source.popFront();`
    );
    
    alias Index = PluckIndexParameter!Range;
    alias Element = ReturnType!(typeof(this).front);
    
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
            return this.source.opIndex(index)[this.index];
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
    
    alias Element = ReturnType!(typeof(this).front);
    
    Range source;
    
    this(typeof(this) range){
        this(range.source);
    }
    this(Range source){
        this.source = source;
    }
    
    static if(isIndexedRange!Range){
        auto opIndex(IndexParameters!Range index){
            mixin(`return this.source.opIndex(index).` ~ property ~ `;`);
        }
    }
    
    // TODO: Slice
}

struct MultiPluckRange(Range) if(canPluckRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`,
        `Empty Length Dollar Save Back`,
        `
            auto front = this.source.front;
            return this.getelement(front);
        `, `
            this.source.popFront();
        `
    );
    
    alias Index = PluckIndexParameter!Range;
    alias Element = ReturnType!(typeof(this).front);
    
    Range source;
    Index[] indexes;
    
    this(PluckRange!Range range){
        this(range.source, [range.index]);
    }
    this(typeof(this) range){
        this(range.source, range.indexes);
    }
    this(Range source, Index[] indexes){
        this.source = source;
        this.indexes = indexes;
    }
    
    static if(isIndexedRange!Range){
        auto opIndex(IndexParameters!Range index){
            auto value = this.source.opIndex(index);
            return this.getelement(value);
        }
    }
    
    // TODO: Slice
    
    private auto getelement(T)(T value){
        import std.traits : Unqual;
        
        auto result = new Unqual!(ElementType!T)[this.indexes.length];
        for(size_t i = 0; i < this.indexes.length; i++){
            result[i] = value[this.indexes[i]];
        }
        return cast(ElementType!T[]) result;
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
        tests("Multiple indexes", {
            testeq(input.pluck([0u, 1u]).length, 4);
            int[][] plucktest = [[0, 0], [1, 1], [2, 4], [3, 9]];
            test(input.pluck([1u, 3u]).equals(plucktest));
        });
    });
}
