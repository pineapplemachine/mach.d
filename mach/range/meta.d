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
                if(param == source) args ~= `.save`;
            }
            return `return typeof(this)(` ~ args ~ `);`;
        }
        
        @property typeof(this) save(){
            mixin(SaveMixin());
        }
    }
}



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



static string MetaMultiRangeWrapperMixin(string rangetype, Iters...)(){
    return MetaMultiRangeWrapperMixin!(rangetype, ``, ``, Iters);
}

static string MetaMultiRangeWrapperMixin(
    string rangetype, string ctortemplateparams, string ctorparams, Iters...
)(){
    import std.conv : to;
    string templates = ``;
    string params = ``;
    for(size_t i = 0; i < Iters.length; i++){
        if(i > 0) params ~= `, `;
        if(i > 0) templates ~= `, `;
        string ter = `ters[` ~ i.to!string ~ `]`;
        params ~= `i` ~ ter ~ `.asrange`;
        templates ~= `AsRangeType!(I` ~ ter ~ `)`;
    }
    static if(ctortemplateparams.length){
        if(templates.length) templates = ctortemplateparams ~ `, ` ~ templates;
        else templates = ctortemplateparams;
    }
    static if(ctorparams.length){
        if(params.length) params = ctorparams ~ `, ` ~ params;
        else params = ctorparams;
    }
    return `
        import mach.range.asrange : asrange, AsRangeType;
        return ` ~ rangetype ~ `!(` ~ templates ~ `)(` ~ params ~ `);
    `;
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

template MetaMultiRangeSaveMixin(string sources, Ranges...){
    import std.meta : allSatisfy;
    import mach.traits : isSavingRange;
    // Build a return statement, this works even when the source range elements
    // contain immutable members.
    private static string SaveCtorMixin(Ranges...)(){
        import std.conv : to;
        string params = ``;
        for(size_t i = 0; i < Ranges.length; i++){
            if(i > 0) params ~= `, `;
            params ~= `this.sources[` ~ i.to!string ~ `].save`;
        }
        return `return typeof(this)(` ~ params ~ `);`;
    }
    // And here's the actual save method
    static if(allSatisfy!(isSavingRange, Ranges)){
        @property typeof(this) save(){
            mixin(SaveCtorMixin!Ranges);
        }
    }
}
