module mach.range.merge;

private:

import std.meta : allSatisfy, anySatisfy;
import mach.traits : hasFalseEmptyEnum, hasNumericLength, getSmallestLength;
import mach.traits : isBidirectionalRange, isRandomAccessRange, isSlicingRange;
import mach.range.meta : MetaMultiRangeEmptyMixin, MetaMultiRangeSaveMixin;
import mach.range.meta : MetaMultiRangeWrapperMixin;

public:



auto merge(alias func, Iters...)(Iters iters){
    mixin(MetaMultiRangeWrapperMixin!(`MergeRange`, `func`, ``, Iters));
}



private static string MergeAttributeMixin(string callname, string attribute, Ranges...)(){
    import std.conv : to;
    string params = ``;
    for(size_t i = 0; i < Ranges.length; i++){
        if(i > 0) params ~= `, `;
        params ~= `this.sources[` ~ i.to!string ~ `]` ~ attribute;
    }
    return `return ` ~ callname ~ `(` ~ params ~ `);`;
}



struct MergeRange(alias func, Ranges...){
    mixin MetaMultiRangeSaveMixin!(`sources`, Ranges);
    mixin MetaMultiRangeEmptyMixin!(
        `
            foreach(i, _; Ranges){
                if(this.sources[i].empty) return true;
            }
            return false;
        `,
        `sources`, Ranges
    );
    
    Ranges sources;
    
    this(Ranges sources){
        this.sources = sources;
    }
    
    static if(anySatisfy!(hasNumericLength, Ranges)){
        @property auto length(){
            return getSmallestLength(this.sources);
        }
        alias opDollar = length;
    }
    
    @property auto ref front(){
        mixin(MergeAttributeMixin!(`func`, `.front`, Ranges));
    }
    void popFront(){
        foreach(i, _; Ranges) this.sources[i].popFront();
    }
    
    static if(allSatisfy!(isBidirectionalRange, Ranges)){
        @property auto ref back(){
            mixin(MergeAttributeMixin!(`func`, `.back`, Ranges));
        }
        void popBack(){
            foreach(i, _; Ranges) this.sources[i].popBack();
        }
    }
    
    static if(allSatisfy!(isRandomAccessRange, Ranges)){
        auto ref opIndex(size_t index){
            mixin(MergeAttributeMixin!(`func`, `[index]`, Ranges));
        }
    }
    static if(allSatisfy!(isSlicingRange, Ranges)){
        auto ref opSlice(size_t low, size_t high){
            mixin(MergeAttributeMixin!(`typeof(this)`, `[low .. high]`, Ranges));
        }
    }
}

// TODO: MergeFillRange



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.reversed : reversed;
}
unittest{
    tests("Merge", {
        alias sumtwo = (a, b) => (a + b);
        alias sumthree = (a, b, c) => (a + b + c);
        auto inputa = [0, 0, 1, 1];
        auto inputb = [1, 2, 3, 4];
        auto inputc = [1, 2, 2, 3];
        tests("Length", {
            auto inputshort = [1, 2];
            auto inputlong = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
            testeq(merge!sumtwo(inputa, inputshort).length, inputshort.length);
            testeq(merge!sumtwo(inputa, inputlong).length, inputa.length);
        });
        tests("Iteration", {
            test(merge!sumtwo(inputa, inputb).equals([1, 2, 4, 5]));
            test(merge!sumthree(inputa, inputb, inputc).equals([2, 4, 6, 8]));
        });
        tests("Backwards", {
            test(merge!sumtwo(inputa, inputb).reversed.equals([5, 4, 2, 1]));
            test(merge!sumthree(inputa, inputb, inputc).reversed.equals([8, 6, 4, 2]));
        });
        tests("Random access", {
            auto range = merge!sumtwo(inputa, inputb);
            testeq(range[0], 1);
            testeq(range[1], 2);
            testeq(range[2], 4);
            testeq(range[$-1], 5);
        });
        tests("Slicing", {
            auto range = merge!sumtwo(inputa, inputb);
            test(range[0 .. 2].equals([1, 2]));
            test(range[2 .. $].equals([4, 5]));
        });
    });
}
