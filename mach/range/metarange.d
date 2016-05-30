module mach.range.metarange;

private:

import std.algorithm : canFind; // TODO: Don't use phobos
import mach.traits : isRange;

public:

enum MetaRangeMixinComponent : string{
    Empty = `Empty`,
    Length = `Length`,
    Dollar = `Dollar`,
    Index = `Index`,
    Slice = `Slice`,
    Save = `Save`,
    Back = `Back`,
}

template MetaRangeMixin(Range, string source, string exclusions) if(isRange!Range){
    import std.algorithm : canFind; // TODO: Don't use phobos
    import mach.range.metarange : MetaRangeMixinComponent;
    import mach.traits : hasEmptyEnum, hasLength, hasDollar;
    import mach.traits : isIndexedRange, IndexParameters;
    import mach.traits : isSavingRange;
    
    static if(!exclusions.canFind(cast(string) MetaRangeMixinComponent.Empty)){
        static if(hasEmptyEnum!Range){
            alias empty = Range.empty;
        }else{
            @property bool empty(){
                mixin(`return this.` ~ source ~ `.empty;`);
            }
        }
    }
    
    static if(!exclusions.canFind(cast(string) MetaRangeMixinComponent.Length)){
        static if(hasLength!Range){
            @property auto length(){
                mixin(`return this.` ~ source ~ `.length;`);
            }
        }
    }
    
    static if(!exclusions.canFind(cast(string) MetaRangeMixinComponent.Dollar)){
        static if(hasDollar!Range){
            @property auto opDollar(){
                mixin(`return this.` ~ source ~ `.opDollar;`);
            }
        }
    }
    
    static if(!exclusions.canFind(cast(string) MetaRangeMixinComponent.Index)){
        static if(isIndexedRange!Range){
            auto ref opIndex(IndexParameters!Range index){
                mixin(`return this.` ~ source ~ `.opIndex(index);`);
            }
        }
    }
    
    static if(exclusions.canFind(cast(string) MetaRangeMixinComponent.Save)){
        static if(isSavingRange!Range){
            @property auto ref save(){
                mixin(`return typeof(this)(this.` ~ source ~ `.save);`);
            }
        }
    }
    
    // TODO: Slice
}

template MetaRangeMixin(Range, string source, string exclusions, string front, string popFront) if(isRange!Range){
    import std.string : replace; // TODO: Don't use phobos
    mixin MetaRangeMixin!(
        Range, source, exclusions, front, popFront,
        front.replace(`front`, `back`).replace(`Front`, `Back`),
        popFront.replace(`front`, `back`).replace(`Front`, `Back`)
    );
}

template MetaRangeMixin(
    Range, string source, string exclusions,
    string frontstr, string popFrontstr,
    string backstr, string popBackstr
) if(isRange!Range){
    import std.algorithm : canFind; // TODO: Don't use phobos
    import mach.range.metarange : MetaRangeMixinComponent;
    import mach.traits : isBidirectionalRange;
    
    mixin MetaRangeMixin!(Range, source, exclusions);
    
    @property auto ref front(){
        mixin(frontstr);
    }
    void popFront(){
        mixin(popFrontstr);
    }
    
    static if(exclusions.canFind(cast(string) MetaRangeMixinComponent.Back)){
        static if(isBidirectionalRange!Range){
            @property auto ref back(){
                mixin(backstr);
            }
            void popBack(){
                mixin(popBackstr);
            }
        }
    }
}
