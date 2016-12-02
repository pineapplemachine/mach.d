module mach.range.meta;

private:

import std.algorithm : canFind; // TODO: Don't use phobos
import mach.traits : isRange;

public:



enum MetaRangeMixinComponent : string {
    Empty = `Empty`,
    Length = `Length`,
    Dollar = `Dollar`,
    Slice = `Slice`,
    Save = `Save`,
    Back = `Back`,
}



/// Used for ranges whose empty property should be
/// the same as the source range if it has one.
template MetaRangeEmptyMixin(Range, string source = `source`) if(isRange!Range){
    import mach.traits : hasEmptyEnum;
    static if(hasEmptyEnum!Range){
        alias empty = Range.empty;
    }else{
        @property bool empty(){
            mixin(`return this.` ~ source ~ `.empty;`);
        }
    }
}

/// Used for ranges whose length, remaining, and opDollar properties should be
/// the same as the source range if it has them.
template MetaRangeLengthMixin(Range, string source = `source`) if(isRange!Range){
    import mach.traits : hasLength, hasRemaining, hasDollar;
    static if(hasLength!Range){
        @property auto length(){
            mixin(`return this.` ~ source ~ `.length;`);
        }
    }
    static if(hasRemaining!Range){
        @property auto remaining(){
            mixin(`return this.` ~ source ~ `.remaining;`);
        }
    }
    static if(hasDollar!Range){
        @property auto opDollar(){
            mixin(`return this.` ~ source ~ `.opDollar;`);
        }
    }
}

/// Deprecated, TODO: Sever all ties
template MetaRangeDollarMixin(Range, string source = `source`) if(isRange!Range){
    //import mach.traits : hasDollar;
    //static if(hasDollar!Range){
    //    @property auto opDollar(){
    //        mixin(`return this.` ~ source ~ `.opDollar;`);
    //    }
    //}
}

/// Deprecated, TODO: Sever all ties
template MetaRangeSaveMixin(Range, string source = `source`) if(isRange!Range){
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
                if(param == source) args ~= `.save`;
            }
            return `return typeof(this)(` ~ args ~ `);`;
        }
        
        @property typeof(this) save(){
            mixin(SaveMixin());
        }
    }
}



/// Deprecated, TODO: Sever all ties
template MetaRangeMixin(Range, string source, string inclusions) if(isRange!Range){
    //import mach.range.contains : contains;
    import std.algorithm : canFind;
    import mach.range.meta : MetaRangeMixinComponent;
    
    static if(inclusions.canFind(cast(string) MetaRangeMixinComponent.Empty)){
        import mach.range.meta : MetaRangeEmptyMixin;
        mixin MetaRangeEmptyMixin!(Range, source);
    }
    
    static if(inclusions.canFind(cast(string) MetaRangeMixinComponent.Length)){
        import mach.range.meta : MetaRangeLengthMixin;
        mixin MetaRangeLengthMixin!(Range, source);
    }
    
    static if(inclusions.canFind(cast(string) MetaRangeMixinComponent.Dollar)){
        import mach.range.meta : MetaRangeDollarMixin;
        mixin MetaRangeDollarMixin!(Range, source);
    }
    
    static if(inclusions.canFind(cast(string) MetaRangeMixinComponent.Save)){
        import mach.range.meta : MetaRangeSaveMixin;
        mixin MetaRangeSaveMixin!(Range, source);
    }
    
    // TODO: Slice
}

/// Deprecated, TODO: Sever all ties
template MetaRangeMixin(Range, string source, string inclusions, string front, string popFront) if(isRange!Range){
    import std.string : replace; // TODO: Don't use phobos
    mixin MetaRangeMixin!(
        Range, source, inclusions, front, popFront,
        front.replace(`front`, `back`).replace(`Front`, `Back`),
        popFront.replace(`front`, `back`).replace(`Front`, `Back`)
    );
}

/// Deprecated, TODO: Sever all ties
template MetaRangeMixin(
    Range, string source, string inclusions,
    string frontstr, string popFrontstr,
    string backstr, string popBackstr
) if(isRange!Range){
    //import mach.range.contains : contains;
    import std.algorithm : canFind;
    import mach.range.meta : MetaRangeMixinComponent;
    
    mixin MetaRangeMixin!(Range, source, inclusions);
    
    @property auto ref front(){
        mixin(frontstr);
    }
    void popFront(){
        mixin(popFrontstr);
    }
    
    static if(inclusions.canFind(cast(string) MetaRangeMixinComponent.Back)){
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



template MetaMultiRangeEmptyMixin(string emptybody, string sources, Range...){
    import std.meta : anySatisfy;
    import mach.traits : hasFalseEmptyEnum;
    static if(anySatisfy!(hasFalseEmptyEnum, Ranges)){
        enum bool empty = false;
    }else{
        @property bool empty(){
            mixin(emptybody);
        }
    }
}
