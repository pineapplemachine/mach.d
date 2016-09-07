module mach.sdl.flags;

private:

//

public:



/// Used to construct bitmask wrapper types.
/// Flags is the flags type, usually int or uint.
/// Option is an enum in which snazzy representations of those flags
/// are stored.
template BitFlagAggregate(Flags, Option){
    static struct BitFlagAggregate{
        mixin BitFlagAggregateMixin!(Flags, Option);
    }
}

template BitFlagAggregateMixin(Flags, Option){
    import mach.traits : hasEnumType;
    import mach.math.bits : hamming;
     
    static if(hasEnumType!(Option, Option, `All`)){
        static enum All = typeof(this)(Option.All);
    }
    static if(hasEnumType!(Option, Option, `Default`)){
        static enum Default = typeof(this)(Option.Default);
    }
    
    Flags flags;
    
    /// True when no flags are true.
    @property bool empty() const{
        return this.flags == 0;
    }
    /// Get the number of true flags.
    @property auto length() const{
        return this.flags.hamming;
    }
    /// Set a flag to true.
    void add(in const(Option)[] options...){
        foreach(option; options) this.flags |= option;
    }
    /// ditto
    void opOpAssign(string op: "|")(in Option option){
        this.add(option);
    }
    /// Set a flag to false.
    void remove(in const(Option)[] options...){
        foreach(option; options) this.flags &= ~option;
    }
    /// Set a flag.
    void set(in Option option, in bool state){
        if(state) this.add(option);
        else this.remove(option);
    }
    /// ditto
    void opIndexAssign(in bool state, in Option option){
        this.set(option, state);
    }
    /// Get whether a flag is set.
    bool contains(in Option option) const{
        return (this.flags & option) != 0;
    }
    /// ditto
    bool opBinaryRight(string op: "in")(in Option option) const{
        return this.contains(option);
    }
    /// ditto
    bool opIndex(in Option option) const{
        return this.contains(option);
    }
}
