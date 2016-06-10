module mach.range.map.plural;

private:

import std.meta : allSatisfy, anySatisfy;
import mach.traits : hasFalseEmptyEnum, hasNumericLength, getSmallestLength;
import mach.traits : isBidirectionalRange, isRandomAccessRange, isSlicingRange;
import mach.range.meta : MetaMultiRangeEmptyMixin, MetaMultiRangeSaveMixin;
import mach.range.meta : MetaMultiRangeWrapperMixin;
import mach.range.map.templates : canMap, canMapRanges, AdjoinTransformations;

public:



template mapplural(transformations...) if(transformations.length){
    alias transform = AdjoinTransformations!transformations;
    auto mapplural(Iters...)(Iters iters) if(canMap!(transform, Iters)){
        mixin(MetaMultiRangeWrapperMixin!(`MapPluralRange`, `transform`, ``, Iters));
    }
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



struct MapPluralRange(alias transform, Ranges...) if(canMapRanges!(transform, Ranges)){
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
        mixin(MergeAttributeMixin!(`transform`, `.front`, Ranges));
    }
    void popFront(){
        foreach(i, _; Ranges) this.sources[i].popFront();
    }
    
    static if(allSatisfy!(isBidirectionalRange, Ranges)){
        @property auto ref back(){
            mixin(MergeAttributeMixin!(`transform`, `.back`, Ranges));
        }
        void popBack(){
            foreach(i, _; Ranges) this.sources[i].popBack();
        }
    }
    
    static if(allSatisfy!(isRandomAccessRange, Ranges)){
        auto ref opIndex(size_t index){
            mixin(MergeAttributeMixin!(`transform`, `[index]`, Ranges));
        }
    }
    static if(allSatisfy!(isSlicingRange, Ranges)){
        auto ref opSlice(size_t low, size_t high){
            mixin(MergeAttributeMixin!(`typeof(this)`, `[low .. high]`, Ranges));
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.retro : retro;
}
unittest{
    tests("Merge", {
        alias sumtwo = (a, b) => (a + b);
        alias sumthree = (a, b, c) => (a + b + c);
        alias product = (a, b) => (a * b);
        auto inputa = [0, 0, 1, 1];
        auto inputb = [1, 2, 3, 4];
        auto inputc = [1, 2, 2, 3];
        tests("Length", {
            auto inputshort = [1, 2];
            auto inputlong = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
            testeq(mapplural!sumtwo(inputa, inputshort).length, inputshort.length);
            testeq(mapplural!sumtwo(inputa, inputlong).length, inputa.length);
        });
        tests("Iteration", {
            test(mapplural!sumtwo(inputa, inputb).equals([1, 2, 4, 5]));
            test(mapplural!sumthree(inputa, inputb, inputc).equals([2, 4, 6, 8]));
        });
        tests("Backwards", {
            test(mapplural!sumtwo(inputa, inputb).retro.equals([5, 4, 2, 1]));
            test(mapplural!sumthree(inputa, inputb, inputc).retro.equals([8, 6, 4, 2]));
        });
        tests("Random access", {
            auto range = mapplural!sumtwo(inputa, inputb);
            testeq(range[0], 1);
            testeq(range[1], 2);
            testeq(range[2], 4);
            testeq(range[$-1], 5);
        });
        tests("Slicing", {
            auto range = mapplural!sumtwo(inputa, inputb);
            test(range[0 .. 2].equals([1, 2]));
            test(range[2 .. $].equals([4, 5]));
        });
        tests("Multiple functions", {
            auto range = mapplural!(sumtwo, product)(inputa, inputb);
            foreach(i; 0 .. inputa.length){
                testeq(range[i][0], sumtwo(inputa[i], inputb[i]));
                testeq(range[i][1], product(inputa[i], inputb[i]));
            }
        });
    });
}
