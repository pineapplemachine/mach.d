module mach.range.metarange;

private:

import std.algorithm : canFind; // TODO: Don't use phobos
import mach.traits : isRange;

public:



enum MetaRangeMixinComponent : string {
    Empty = `Empty`,
    Length = `Length`,
    Dollar = `Dollar`,
    Index = `Index`,
    Slice = `Slice`,
    Save = `Save`,
    Back = `Back`,
}



template MetaRangeEmptyMixin(Range, string source) if(isRange!Range){
    import mach.traits : hasEmptyEnum;
    static if(hasEmptyEnum!Range){
        alias empty = Range.empty;
    }else{
        @property bool empty(){
            mixin(`return this.` ~ source ~ `.empty;`);
        }
    }
}

template MetaRangeLengthMixin(Range, string source) if(isRange!Range){
    import mach.traits : hasLength;
    static if(hasLength!Range){
        @property auto length(){
            mixin(`return this.` ~ source ~ `.length;`);
        }
    }
}

template MetaRangeDollarMixin(Range, string source) if(isRange!Range){
    import mach.traits : hasDollar;
    static if(hasDollar!Range){
        @property auto opDollar(){
            mixin(`return this.` ~ source ~ `.opDollar;`);
        }
    }
}

template MetaRangeIndexMixin(Range, string source) if(isRange!Range){
    import mach.traits : isIndexedRange;
    static if(isIndexedRange!Range){
        import mach.traits : IndexParameters;
        auto ref opIndex(IndexParameters!Range index){
            mixin(`return this.` ~ source ~ `.opIndex(index);`);
        }
    }
}

template MetaRangeSaveMixin(Range, string source) if(isRange!Range){
    import mach.traits : isSavingRange, hasConstructor;
    static if(isSavingRange!Range && hasConstructor!(typeof(this))){
        import std.traits : ParameterIdentifierTuple;
        import mach.traits : getFunctionWithMostParameters;
        
        private static string SaveMixin(){
            alias Ctor = getFunctionWithMostParameters!(typeof(this), `__ctor`);
            alias Params = ParameterIdentifierTuple!Ctor;
            string args = ``;
            foreach(param; Params){
                if(args.length) args ~= `, `;
                args ~= `this.` ~ param;
                if(param == `source`) args ~= `.save`;
            }
            return `return typeof(this)(` ~ args ~ `);`;
        }
        
        @property typeof(this) save(){
            mixin(SaveMixin());
        }
    }
}



template MetaRangeMixin(Range, string source, string inclusions) if(isRange!Range){
    import mach.range.contains : contains;
    import mach.range.metarange : MetaRangeMixinComponent;
    
    
    static if(inclusions.contains(cast(string) MetaRangeMixinComponent.Empty)){
        import mach.range.metarange : MetaRangeEmptyMixin;
        mixin MetaRangeEmptyMixin!(Range, source);
    }
    
    static if(inclusions.contains(cast(string) MetaRangeMixinComponent.Length)){
        import mach.range.metarange : MetaRangeLengthMixin;
        mixin MetaRangeLengthMixin!(Range, source);
    }
    
    static if(inclusions.contains(cast(string) MetaRangeMixinComponent.Dollar)){
        import mach.range.metarange : MetaRangeDollarMixin;
        mixin MetaRangeDollarMixin!(Range, source);
    }
    
    static if(inclusions.contains(cast(string) MetaRangeMixinComponent.Index)){
        import mach.range.metarange : MetaRangeIndexMixin;
        mixin MetaRangeIndexMixin!(Range, source);
    }
    
    static if(inclusions.contains(cast(string) MetaRangeMixinComponent.Save)){
        import mach.range.metarange : MetaRangeSaveMixin;
        mixin MetaRangeSaveMixin!(Range, source);
    }
    
    // TODO: Slice
}

template MetaRangeMixin(Range, string source, string inclusions, string front, string popFront) if(isRange!Range){
    import std.string : replace; // TODO: Don't use phobos
    mixin MetaRangeMixin!(
        Range, source, inclusions, front, popFront,
        front.replace(`front`, `back`).replace(`Front`, `Back`),
        popFront.replace(`front`, `back`).replace(`Front`, `Back`)
    );
}

template MetaRangeMixin(
    Range, string source, string inclusions,
    string frontstr, string popFrontstr,
    string backstr, string popBackstr
) if(isRange!Range){
    import mach.range.contains : contains;
    import mach.range.metarange : MetaRangeMixinComponent;
    
    mixin MetaRangeMixin!(Range, source, inclusions);
    
    @property auto ref front(){
        mixin(frontstr);
    }
    void popFront(){
        mixin(popFrontstr);
    }
    
    static if(inclusions.contains(cast(string) MetaRangeMixinComponent.Back)){
        import mach.traits : isBidirectionalRange;
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
