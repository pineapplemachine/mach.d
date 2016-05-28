module mach.range.pluck;

private:

import std.meta : AliasSeq;
import std.traits : ReturnType, isImplicitlyConvertible;
import mach.range.asrange : asrange, validAsRange;
import mach.traits : isRange, isRandomAccessRange, ElementType;
import mach.traits : hasSingleIndexParameter, SingleIndexParameter;
import mach.range.metarange : MetaRangeMixin;

public:



enum canPluck(Iter) = validAsRange!Iter && hasSingleIndexParameter!(ElementType!Iter);
enum canPluckRange(Range) = isRange!Range && hasSingleIndexParameter!(ElementType!Range);
template PluckIndexParameter(Iter) if(canPluck!Iter){
    alias PluckIndexParameter = SingleIndexParameter!(ElementType!Iter);
}



auto pluck(Iter, Index)(
    Iter iter, Index index
) if(canPluck!Iter && isImplicitlyConvertible!(Index, PluckIndexParameter!Iter)){
    auto range = iter.asrange;
    return PluckRange!(typeof(range))(range, index);
}

auto pluck(Iter, Index)(
    Iter iter, Index[] indexes
) if(canPluck!Iter && isImplicitlyConvertible!(Index[], PluckIndexParameter!Iter[])){
    auto range = iter.asrange;
    return MultiPluckRange!(typeof(range))(range, indexes);
}



struct PluckRange(Range) if(canPluckRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`,
        `RandomAccess`,
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

struct MultiPluckRange(Range) if(canPluckRange!Range){
    mixin MetaRangeMixin!(
        Range, `source`,
        `RandomAccess`,
        `
            auto front = this.source.front;
            return this.getelement(front);
        `,
        `
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
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Pluck", {
        
        int[][] subject;
        foreach(i; 0 .. 4) subject ~= [0, i, i+i, i*i];

        tests("Single index", {
            tests("Numeric", {
                testeq(subject.pluck(0).length, 4);
                test(subject.pluck(0).equals([0, 0, 0, 0]));
                test(subject.pluck(1).equals([0, 1, 2, 3]));
                test(subject.pluck(2).equals([0, 2, 4, 6]));
                test(subject.pluck(3).equals([0, 1, 4, 9]));
            });
            tests("Associative array strings", {
                string[string][] data = [
                    ["a": "apple", "b": "bear"],
                    ["a": "attack", "b": "bumblebee"],
                    ["a": "airplane", "b": "bin"]
                ];
                test(data.pluck("a").equals(["apple", "attack", "airplane"]));
            });
        });
        tests("Multiple indexes", {
            testeq(subject.pluck([0u, 1u]).length, 4);
            int[][] plucktest = [[0, 0], [1, 1], [2, 4], [3, 9]];
            test(subject.pluck([1u, 3u]).equals(plucktest));
        });
    });
}
