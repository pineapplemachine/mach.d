module mach.range.mutate;

private:

import mach.traits : isMutableFrontRange, isMutableBackRange, ElementType;
import mach.range.asrange : asrange, validAsRange;
import mach.range.meta : MetaRangeMixin;

public:



enum canMutate(Iter, alias transform) = (
    validAsRange!(isMutableFrontRange, Iter) &&
    validMutateTransformation!(Iter, transform)
);
enum canMutateRange(Range, alias transform) = (
    isMutableFrontRange!Range &&
    validMutateTransformation!(Range, transform)
);

template validMutateTransformation(Iter, alias transform){
    enum bool validMutateTransformation = is(typeof((inout int = 0){
        alias Element = ElementType!Iter;
        Element result = transform(Element.init);
    }));
}



/// Maps values from the input range to values in an output range using a
/// transformation function, and differs from the map function in that the
/// input range is also modified to contain the new values.
auto mutate(alias transform, Iter)(Iter iter) if(canMutate!(Iter, transform)){
    auto range = iter.asrange;
    return MutateRange!(transform, typeof(range))(range);
}



struct MutateRange(alias transform, Range) if(canMutateRange!(Range, transform)){
    enum bool isBidirectional = isMutableBackRange!Range;
    
    mixin MetaRangeMixin!(
        Range, `source`, `Empty Length Dollar`
    );
    
    Range source;
    bool mutfront;
    static if(isBidirectional) bool mutback;
    
    static if(isBidirectional){
        this(typeof(this) range){
            this(range.source, range.mutfront, range.mutback);
        }
        this(Range source, bool mutfront = false, bool mutback = false){
            this.source = source;
            this.mutfront = mutfront;
            this.mutback = mutback;
        }
    }else{
        this(typeof(this) range){
            this(range.source, range.mutfront);
        }
        this(Range source, bool mutfront = false){
            this.source = source;
            this.mutfront = mutfront;
        }
    }
    
    @property auto ref front(){
        if(!this.mutfront) this.mutateFront();
        return this.source.front;
    }
    void popFront(){
        if(!this.mutfront) this.mutateFront();
        this.source.popFront();
        this.mutfront = false;
    }
    void mutateFront(){
        this.source.front = transform(this.source.front);
        this.mutfront = true;
    }
    static if(isMutableBackRange!Range){
        @property auto ref back(){
            if(!this.mutback) this.mutateBack();
            return this.source.back;
        }
        void popBack(){
            if(!this.mutback) this.mutateBack();
            this.source.popBack();
            this.mutback = false;
        }
        void mutateBack(){
            this.source.back = transform(this.source.back);
            this.mutback = true;
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.consume : consume, consumereverse;
}
unittest{
    tests("Mutate", {
        int[] array = [0, 1, 2, 3, 4];
        array.mutate!((n) => (n+1)).consume;
        testeq(array, [1, 2, 3, 4, 5]);
        array.mutate!((n) => (n+1)).consumereverse;
        testeq(array, [2, 3, 4, 5, 6]);
    });
}
