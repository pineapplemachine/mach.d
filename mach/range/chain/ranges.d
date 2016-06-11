module mach.range.chain.ranges;

private:

import std.meta : staticMap, allSatisfy, anySatisfy;
import mach.traits : hasCommonElementType, CommonElementType;
import mach.traits : isRange, isBidirectionalRange;
import mach.traits : isRandomAccessRange, isSavingRange, isSlicingRange;
import mach.traits : hasNumericLength, hasFalseEmptyEnum, getSummedLength;
import mach.range.asrange : asrange, validAsRange, AsRangeType;
import mach.range.meta : MetaMultiRangeEmptyMixin, MetaMultiRangeSaveMixin;
import mach.range.meta : MetaMultiRangeWrapperMixin;

public:



/// Can a sequence of aliased iterables be chained?
enum canChainIterables(Iters...) = (
    Iters.length && allSatisfy!(validAsRange, Iters) && hasCommonElementType!Iters
);

/// Can a sequence of aliased ranges be chained?
enum canChainRanges(Ranges...) = (
    Ranges.length && allSatisfy!(isRange, Ranges) && hasCommonElementType!Ranges
);



auto chainranges(Iters...)(Iters iters) if(canChainIterables!Iters){
    mixin(MetaMultiRangeWrapperMixin!(`ChainRange`, Iters));
}



private static string ChainSliceMixin(Ranges...)(){
    import std.conv : to;
    string params = ``;
    for(size_t i = 0; i < Ranges.length; i++){
        if(i > 0) params ~= `, `;
        auto istr = i.to!string;
        params ~= `this.sources[` ~ istr ~ `][
            this.getslicelow(` ~ istr ~ `, low) ..
            this.getslicehigh(` ~ istr ~ `, high)
        ]`;
    }
    return `return typeof(this)(` ~ params ~ `);`;
}



struct ChainRange(Ranges...) if(canChainRanges!Ranges){
    alias Element = CommonElementType!Ranges;
    
    mixin MetaMultiRangeSaveMixin!(`sources`, Ranges);
    mixin MetaMultiRangeEmptyMixin!(
        `
            foreach(i, _; Ranges){
                if(!this.sources[i].empty) return false;
            }
            return true;
        `,
        `sources`, Ranges
    );
    
    Ranges sources;
    
    this(typeof(this) range){
        this.sources = range.sources;
    }
    this(Ranges sources){
        this.sources = sources;
    }
    
    @property auto ref front(){
        foreach(i, _; Ranges){
            if(!this.sources[i].empty) return this.sources[i].front;
        }
        assert(false);
    }
    void popFront(){
        foreach(i, _; Ranges){
            if(!this.sources[i].empty) return this.sources[i].popFront();
        }
        assert(false);
    }
    
    static if(allSatisfy!(isBidirectionalRange, Ranges)){
        @property auto ref back(){
            foreach_reverse(i, _; Ranges){
                if(!this.sources[i].empty) return this.sources[i].back;
            }
            assert(false);
        }
        void popBack(){
            foreach_reverse(i, _; Ranges){
                if(!this.sources[i].empty) return this.sources[i].popBack();
            }
            assert(false);
        }
    }
    
    static if(allSatisfy!(hasNumericLength, Ranges)){
        @property auto length(){
            return getSummedLength(this.sources);
        }
        alias opDollar = length;
        static if(allSatisfy!(isRandomAccessRange, Ranges)){
            auto opIndex(in size_t index) in{
                assert(index >= 0 && index < this.length);
            }body{
                size_t offset = size_t.init;
                foreach(i, _; Ranges){
                    auto next = offset + this.sources[i].length;
                    if(next > index) return this.sources[i][index - offset];
                    offset = next;
                }
                assert(false);
            }
        }
        static if(allSatisfy!(isSlicingRange, Ranges)){
            typeof(this) opSlice(in size_t low, in size_t high) in{
                assert((low >= 0) & (high >= low) & (high <= this.length));
            }body{
                mixin(ChainSliceMixin!Ranges);
            }
            
            private size_t getslicelow(in size_t slice, in size_t low){
                size_t offset = size_t.init;
                foreach(i, _; Ranges){
                    auto next = offset + this.sources[i].length;
                    if(i == slice){
                        if(low > offset && low <= next){
                            return low - offset;
                        }else{
                            return 0;
                        }
                    } 
                    offset = next;
                }
                assert(false);
            }
            private size_t getslicehigh(in size_t slice, in size_t high){
                size_t offset = size_t.init;
                foreach(i, _; Ranges){
                    auto next = offset + this.sources[i].length;
                    if(i == slice){
                        if(high <= offset){
                            return 0;
                        }else if(high >= next){
                            return this.sources[i].length;
                        }else{
                            return high - offset;
                        }
                    } 
                    offset = next;
                }
                assert(false);
            }
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Chaining", {
        test("Basic equality",
            chainranges("yo", "dawg").equals("yodawg")
        );
        test("Disparate types",
            chainranges([1, 2], [3.0, 4.0]).equals([1.0, 2.0, 3.0, 4.0])
        );
        testeq("Length",
            chainranges("yo", "dawg").length, 6
        );
        tests("Random access", {
            auto range = chainranges("yo", "dawg");
            testeq(range[0], 'y');
            testeq(range[1], 'o');
            testeq(range[2], 'd');
            testeq(range[3], 'a');
            testeq(range[4], 'w');
            testeq(range[$-1], 'g');
        });
        tests("Saving", {
            auto range = chainranges("yo", "dawg");
            auto saved = range.save;
            range.popFront();
            range.popBack();
            test(range.equals("odaw"));
            test(saved.equals("yodawg"));
        });
        tests("Slices", {
            auto range = chainranges("xxx", "yyy", "zzz");
            test(range[0 .. 4].equals("xxxy"));
            test(range[2 .. $].equals("xyyyzzz"));
        });
        tests("Chain of chains", {
            auto range = chainranges(chainranges("abc", "def"), chainranges("ghi", "jkl", "mno"));
            testeq(range[0], 'a');
            testeq(range[3], 'd');
            testeq(range[6], 'g');
            testeq(range[9], 'j');
            testeq(range[12], 'm');
        });
    });
}
