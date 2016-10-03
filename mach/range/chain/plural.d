module mach.range.chain.plural;

private:

import mach.meta : Any, All, varmap, varmapi, varsum;
import mach.traits : hasCommonElementType, CommonElementType;
import mach.traits : isRange, isBidirectionalRange;
import mach.traits : isRandomAccessRange, isSavingRange, isSlicingRange;
import mach.traits : hasNumericLength, hasFalseEmptyEnum, hasTrueEmptyEnum;
import mach.range.asrange : asrange, validAsRange;

public:



/// Can a sequence of aliased iterables be chained?
enum canChainIterables(Iters...) = (
    Iters.length && All!(validAsRange, Iters) && hasCommonElementType!Iters
);

/// Can a sequence of aliased ranges be chained?
enum canChainRanges(Ranges...) = (
    Ranges.length && All!(isRange, Ranges) && hasCommonElementType!Ranges
);



auto chainiters(Iters...)(auto ref Iters iters) if(canChainIterables!Iters){
    auto ranges = varmap!(e => e.asrange)(iters);
    return ChainRange!(typeof(ranges.expand))(ranges.expand);
}



struct ChainRange(Ranges...) if(canChainRanges!Ranges){
    alias Element = CommonElementType!Ranges;
    
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
    
    static if(All!(isBidirectionalRange, Ranges)){
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
    
    static if(Any!(hasFalseEmptyEnum, Ranges)){
        static enum bool empty = false;
    }else static if(All!(hasTrueEmptyEnum, Ranges)){
        static enum bool empty = true;
    }else{
        @property bool empty(){
            foreach(i, _; Ranges){
                if(!this.sources[i].empty) return false;
            }
            return true;
        }
    }
    
    static if(All!(isSavingRange, Ranges)){
        @property typeof(this) save(){
            return typeof(this)(varmap!(e => e.save)(this.sources).expand);
        }
    }
    
    static if(All!(hasNumericLength, Ranges)){
        @property auto length(){
            return varsum(varmap!(e => e.length)(this.sources).expand);
        }
        alias opDollar = length;
        
        static if(All!(isRandomAccessRange, Ranges)){
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
        
        static if(All!(isSlicingRange, Ranges)){
            typeof(this) opSlice(in size_t low, in size_t high) in{
                assert((low >= 0) & (high >= low) & (high <= this.length));
            }body{
                return typeof(this)(
                    this.sources.varmapi!((i, e) => (e[
                        this.getslicelow(i, low) ..
                        this.getslicehigh(i, high)
                    ])).expand
                );
            }
            
            size_t getslicelow(in size_t slice, in size_t low){
                size_t offset = 0;
                foreach(i, _; Ranges){
                    auto len = this.sources[i].length;
                    auto next = offset + len;
                    if(i == slice){
                        if(low <= offset){
                            return 0;
                        }else if(low < next){
                            return low - offset;
                        }else{
                            return len;
                        }
                    } 
                    offset = next;
                }
                assert(false);
            }
            size_t getslicehigh(in size_t slice, in size_t high){
                size_t offset = 0;
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
    import mach.test;
    import mach.range.compare : equals;
}
unittest{
    tests("Chaining", {
        tests("Basic equality", {
            chainiters("yo", "dawg").equals("yodawg");
        });
        tests("Disparate types", {
            chainiters([1, 2], [3.0, 4.0]).equals([1.0, 2.0, 3.0, 4.0]);
            static assert(!is(typeof({
                chainiters([1, 2, 3], 4);
            })));
            static assert(!is(typeof({
                struct X{size_t x;}
                chainiters([1, 2, 3], [X(0), X(1)]);
            })));
        });
        tests("Length", {
            testeq(chainiters("yo", "dawg").length, 6);
            testeq(chainiters("hi").length, 2);
            testeq(chainiters("").length, 0);
            testeq(chainiters("", "", "").length, 0);
        });
        tests("Random access", {
            auto range = chainiters("yo", "dawg");
            testeq(range[0], 'y');
            testeq(range[1], 'o');
            testeq(range[2], 'd');
            testeq(range[3], 'a');
            testeq(range[4], 'w');
            testeq(range[$-1], 'g');
            testfail({range[$];});
        });
        tests("Saving", {
            auto range = chainiters("yo", "dawg");
            auto saved = range.save;
            range.popFront();
            range.popBack();
            test(range.equals!false("odaw"));
            test(saved.equals("yodawg"));
        });
        tests("Slices", {
            auto range = chainiters("xxx", "yyy", "zzz");
            test(range[0 .. 0].equals(""));
            test(range[0 .. 1].equals("x"));
            test(range[0 .. 4].equals("xxxy"));
            test(range[2 .. $].equals("xyyyzzz"));
            test(range[4 .. $].equals("yyzzz"));
            test(range[4 .. 4].equals(""));
            test(range[$ .. $].equals(""));
            testfail({range[0 .. 11];});
            testfail({range[10 .. 11];});
            testfail({range[10 .. 10];});
        });
        tests("Chain of chains", {
            auto range = chainiters(chainiters("abc", "def"), chainiters("ghi", "jkl", "mno"));
            testeq(range[0], 'a');
            testeq(range[3], 'd');
            testeq(range[6], 'g');
            testeq(range[9], 'j');
            testeq(range[12], 'm');
        });
    });
}
