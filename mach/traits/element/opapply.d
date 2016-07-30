module mach.traits.element.opapply;

private:

import std.traits : Parameters; // TODO: Replace (see below)
import mach.traits.call : isDelegate;
import mach.traits.op : hasOpApply, hasOpApplyReverse;

public:



/// Base template for getting the element type of some type implementing opApply
/// or opApplyReverse.
private template OpApplyGenericElementType(alias op){
    alias ApplyParams = Parameters!op;
    static assert(
        ApplyParams.length == 1 && isDelegate!(ApplyParams[0]),
        "Invalid arguments for opApply."
    );
    alias Delegate = ApplyParams[0];
    // TODO: What if there's more than one opApply overload?
    // Probably going to need a more robust Parameters template for that.
    alias DelegateParams = Parameters!Delegate;
    static if(DelegateParams.length == 1){
        alias OpApplyGenericElementType = DelegateParams[0];
    }else{
        alias OpApplyGenericElementType = DelegateParams;
    }
}



/// Get the element type of a type implementing opApply.
template OpApplyElementType(Tx...) if(Tx.length == 1 && hasOpApply!(Tx[0])){
    alias OpApplyElementType = OpApplyGenericElementType!(Tx[0].opApply);
}

/// Get the element type of a type implementing opApplyReverse.
template OpApplyReverseElementType(Tx...) if(Tx.length == 1 && hasOpApplyReverse!(Tx[0])){
    alias OpApplyReverseElementType = OpApplyGenericElementType!(Tx[0].opApplyReverse);
}



version(unittest){
    private:
    import mach.meta : Aliases;
}
unittest{
    struct ApplyInt{int opApply(int delegate(ref int)){return 0;}}
    struct ApplyString{int opApply(int delegate(ref string)){return 0;}}
    struct ApplyTuple{int opApply(int delegate(ref int, ref int)){return 0;}}
    struct ApplyReverseInt{int opApplyReverse(int delegate(ref int)){return 0;}}
    struct ApplyReverseString{int opApplyReverse(int delegate(ref string)){return 0;}}
    struct ApplyReverseTuple{int opApplyReverse(int delegate(ref int, ref int)){return 0;}}
    struct ApplyBidirectional{
        int opApply(int delegate(ref int)){return 0;}
        int opApplyReverse(int delegate(ref int)){return 0;}
    }
    ApplyInt apply;
    ApplyReverseInt applyrev;
    static assert(is(OpApplyElementType!apply == int));
    static assert(is(OpApplyElementType!ApplyInt == int));
    static assert(is(OpApplyElementType!ApplyString == string));
    static assert(is(OpApplyElementType!ApplyTuple == Aliases!(int, int)));
    static assert(is(OpApplyElementType!ApplyBidirectional == int));
    static assert(is(OpApplyReverseElementType!applyrev == int));
    static assert(is(OpApplyReverseElementType!ApplyReverseInt == int));
    static assert(is(OpApplyReverseElementType!ApplyReverseString == string));
    static assert(is(OpApplyReverseElementType!ApplyReverseTuple == Aliases!(int, int)));
    static assert(is(OpApplyReverseElementType!ApplyBidirectional == int));
}
