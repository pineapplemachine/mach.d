module mach.range.join;

private:

import mach.traits : isRange, isSavingRange, isFiniteRange, isFiniteIterable;
import mach.traits : hasCommonElementType, CommonElementType, ElementType;
import mach.range.asrange : asrange, validAsRange, validAsSavingRange, AsRangeType;
import mach.range.chain : chainiter, canChainIterableOfIterables;

public:



template canJoin(Iter){
    enum bool canJoin = canChainIterableOfIterables!(Iter);
}

template canJoin(Iter, Sep){
    static if(validAsRange!Iter && validAsRange!Sep){
        alias Sub = ElementType!Iter;
        static if(validAsSavingRange!Sub){
            enum bool canJoin = hasCommonElementType!(Sub, Sep);
        }else{
            enum bool canJoin = false;
        }
    }else{
        enum bool canJoin = false;
    }
}

enum canJoinElement(Iter, Sep) = (
    canJoin!(Iter, Sep[])
);

enum canJoinRange(Range, Sep) = (
    isRange!Range && isRange!Sep && canJoin!(Range, Sep)
);



/// Conventional join function, where the first argument is an iterable of
/// iterables and the second, separator argument is an iterable of elements
/// compatible with those of the former iterables.
auto join(bool frontsep = false, bool backsep = false, Iter, Sep)(
    auto ref Iter iter, auto ref Sep sep
)if(canJoin!(Iter, Sep)){
    auto irange = iter.asrange;
    auto srange = sep.asrange;
    return JoinRange!(typeof(irange), typeof(srange), frontsep, backsep)(irange, srange);
}

auto join(bool frontsep = false, bool backsep = false, Iter, Sep)(
    auto ref Iter iter, auto ref Sep sep
)if(canJoinElement!(Iter, Sep) && !canJoin!(Iter, Sep)){
    return join!(frontsep, backsep)(iter, [sep]);
}

/// In the absence of a separator just chain the input iterator. (Because why not?)
auto join(Iter)(auto ref Iter iter) if(canJoin!Iter){
    return chainiter(iter);
}



struct JoinRange(
    Range, Sep, bool frontsep, bool backsep
) if(canJoinRange!(Range, Sep)){
    // TODO: Bidirectionality (will be tricky)
    // TODO: Indexing, slicing (just a lot of tedium probably)
    
    alias Sub = AsRangeType!(ElementType!Range);
    alias Element = CommonElementType!(Sub, Sep);
    
    enum bool isFinite = (
        isFiniteRange!Sep && isFiniteRange!Range && isFiniteIterable!Sub
    );
    
    static if(isFinite && backsep){
        static enum SepState{On, Off, OnLast}
    }else{
        static enum SepState{On, Off}
    }
    static if(frontsep){
        static enum InitialState = SepState.On;
    }else{
        static enum InitialState = SepState.Off;
    }
    
    /// The range to be joined. Commonly a sequence of strings.
    Range source;
    /// The element of the source range currently being enumerated.
    Sub sub = void;
    /// The range to join with, also known as the separator.
    /// It must share an element type with the element type of the source range.
    Sep sep;
    Sep savedsep;
    /// Whether the JoinRange is currently enumerating the source or separator range.
    SepState state = InitialState;
    /// Whether the range is currently empty.
    static if(isFinite) bool isempty = false;
    
    this(Range source, Sep sep){
        this.source = source;
        this.savedsep = sep.save();
        this.sep = this.savedsep.save();
        this.state = InitialState;
        if(!this.source.empty){
            this.sub = this.source.front.asrange;
            this.source.popFront();
        }
        this.advanceFront();
    }
    static if(!isFinite){
        this(Range source, Sub sub, Sep sep, Sep savedsep, SepState state){
            this.source = source;
            this.sub = sub;
            this.sep = sep;
            this.savedsep = savedsep;
            this.state = state;
        }
    }else{
        this(Range source, Sub sub, Sep sep, Sep savedsep, SepState state, bool isempty){
            this.source = source;
            this.sub = sub;
            this.sep = sep;
            this.savedsep = savedsep;
            this.state = state;
            this.isempty = isempty;
        }
    }
    
    @property bool empty(){
        return this.isempty;
    }
    
    @property auto front() in{assert(!this.empty);} body{
        if(this.state !is SepState.Off){
            assert(!this.sep.empty);
            return cast(Element) this.sep.front;
        }else{
            assert(!this.sub.empty);
            return cast(Element) this.sub.front;
        }
    }
    
    void popFront() in{assert(!this.empty);} body{
        if(this.state !is SepState.Off){
            assert(!this.sep.empty);
            this.sep.popFront();
        }else{
            assert(!this.sub.empty);
            this.sub.popFront();
        }
        this.advanceFront();
    }
    
    static if(isSavingRange!Range && isSavingRange!Sub){
        @property auto save(){
            static if(isFinite){
                return typeof(this)(
                    this.source.save, this.sub.save, this.sep.save,
                    this.savedsep, this.state, this.isempty
                );
            }else{
                return typeof(this)(
                    this.source.save, this.sub.save, this.sep.save,
                    this.savedsep, this.state
                );
            }
        }
    }
    
    void advanceFront() in{assert(!this.empty);} body{
        immutable auto initstate = this.state;
        if(this.state !is SepState.Off){
            this.advancesep();
        }else{
            this.advancesub();
        }
        if(initstate != this.state && !this.empty) this.advanceFront();
    }
    void advancesep(){
        if(this.sep.empty){
            this.sep = this.savedsep.save();
            static if(isFinite && backsep){
                this.isempty = this.state is SepState.OnLast;
            }
            this.state = SepState.Off;
        }
    }
    void advancesub(){
        if(this.sub.empty){
            if(!this.source.empty){
                this.sub = this.source.front.asrange;
                this.source.popFront();
                this.state = SepState.On;
            }else{
                static if(backsep) this.state = SepState.OnLast;
                else static if(isFinite) this.isempty = true;
            }
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
    import mach.range.filter: filter;
    import mach.range.split : split;
}
unittest{
    tests("Join", {
        tests("Arrays", {
            test(["abc", "def", "ghi"].join(", ").equals("abc, def, ghi"));
            test(["abc", "def", "ghi"].join("").equals("abcdefghi"));
            test(["abc", "def", "ghi"].join.equals("abcdefghi"));
            test(["abc", "def", "ghi"].join(',').equals("abc,def,ghi"));
            test(["a", "b"].join!(false, true)('.').equals("a.b."));
            test(["a", "b"].join!(true, false)('.').equals(".a.b"));
            test(["a", "b"].join!(true, true)('.').equals(".a.b."));
            test(["abc"].join(", ").equals("abc"));
            test(["abc"].join("").equals("abc"));
            test((new string[0]).join(", ").equals(""));
            test((new string[0]).join("").equals(""));
        });
        tests("Ranges", {
            test(["a", "b"].asrange.join(" ").equals("a b"));
            test(["a", "b"].asrange.join(' ').equals("a b"));
            test("a b c".split(" ").join(" ").equals("a b c"));
            test(["0", "0", "1", "0", "1"].filter!(e => e != "1").join(" ").equals("0 0 0"));
        });
    });
}
