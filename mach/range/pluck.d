module mach.range.pluck;

private:

import std.meta : AliasSeq;
import std.traits : ReturnType, isImplicitlyConvertible;
import mach.range.asrange : asrange, validAsRange;
import mach.traits : isRange, isRandomAccessRange, ElementType, hasField;
import mach.traits : hasSingleIndexParameter, SingleIndexParameter;
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

enum canPluckField(Iter, string field) = (
    validAsRange!Iter && hasField!(ElementType!Iter, field)
);
enum canPluckFieldRange(Range, string field) = (
    isRange!Range && hasField!(ElementType!Range, field)
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

auto pluck(string field, Iter)(
    Iter iter
) if(canPluckField!(Iter, field)){
    auto range = iter.asrange;
    return FieldPluckRange!(field, typeof(range))(range);
}

// TODO: MultiFieldPluckRange



struct PluckRange(Range) if(canPluckRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`,
        `RandomAccess Slice`,
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
    
    static if(isRandomAccessRange!Range){
        auto opIndex(IndexParameters!Range index){
            return this.source.opIndex(index)[this.index];
        }
    }
}

struct FieldPluckRange(string field, Range) if(canPluckFieldRange!(Range, field)){
    mixin MetaRangeMixin!(
        Range, `source`,
        `RandomAccess Slice`,
        `return this.source.front.` ~ field ~ `;`,
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
    
    static if(isRandomAccessRange!Range){
        auto opIndex(IndexParameters!Range index){
            mixin(`return this.source.opIndex(index).` ~ field ~ `;`);
        }
    }
}

struct MultiPluckRange(Range) if(canPluckRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`,
        `RandomAccess Slice`,
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
    
    static if(isRandomAccessRange!Range){
        auto opIndex(IndexParameters!Range index){
            auto value = this.source.opIndex(index);
            return this.getelement(value);
        }
    }
    
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
    struct FieldPluckTest{
        int x, y;
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
            tests("Field name", {
                FieldPluckTest[] data = [
                    FieldPluckTest(0, 2),
                    FieldPluckTest(2, 4),
                    FieldPluckTest(4, 6)
                ];
                test(canPluckField!(typeof(data), `x`));
                test(canPluckField!(typeof(data), `y`));
                testf(canPluckField!(typeof(data), `z`));
                test(data.pluck!`x`.equals([0, 2, 4]));
                test(data.pluck!`y`.equals([2, 4, 6]));
            });
        });
        tests("Multiple indexes", {
            testeq(input.pluck([0u, 1u]).length, 4);
            int[][] plucktest = [[0, 0], [1, 1], [2, 4], [3, 9]];
            test(input.pluck([1u, 3u]).equals(plucktest));
        });
    });
}
