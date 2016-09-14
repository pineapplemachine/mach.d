module mach.traits.range;

private:

import mach.traits.call : ReturnType;

public:



/// Determine whether some type is a range.
/// Defined separately from std.range.primitives.isInputRange to avoid arrays-
/// masquarading-as-ranges tomfoolery.
enum isRange(alias T) = isRange!(typeof(T));
/// ditto
template isRange(T){
    enum bool isRange = is(typeof((inout int = 0){
        T range = T.init;
        if(range.empty){}
        auto element = range.front;
        range.popFront();
    }));
}



/// Determine whether a range can be iterated over both forwards and back.
/// Unlike the similar phobos template, this doesn't require the range to also
/// be a ForwardRange.
enum isBidirectionalRange(alias T) = isBidirectionalRange!(typeof(T));
/// ditto
template isBidirectionalRange(T){
    enum bool isBidirectionalRange = isRange!T && is(typeof((inout int = 0){
        T range = T.init;
        auto front = range.front;
        auto back = range.back;
        static assert(is(typeof(front) == typeof(back)));
        range.popBack();
    }));
}



/// Determine whether a range implements a save method. Essentially the same as
/// phobos' isForwardRange but not so oddly named.
enum isSavingRange(alias T) = isSavingRange!(typeof(T));
/// ditto
template isSavingRange(T){
    enum bool isSavingRange = isRange!T && is(typeof((inout int = 0){
        T range = T.init;
        auto saved = range.save;
        static assert(is(typeof(saved) == T));
    }));
}



/// Determine whether a range supports random access. For this to be true, a
/// range must have an opIndex method allowing a single integral argument and
/// returning a value of the same type as its front property.
enum isRandomAccessRange(alias T) = isRandomAccessRange!(typeof(T));
/// ditto
template isRandomAccessRange(T){
    enum bool isRandomAccessRange = isRange!T && is(typeof((inout int = 0){
        size_t index = 0;
        T range = T.init;
        auto front = range.front;
        auto element = range[index];
        static assert(is(typeof(front) == typeof(element)));
    }));
}



/// Determine whether a range supports a slice operation with integral arguments
/// for both low and high indexes. The returned slice must be of the same type
/// as the range itself for it to be considered slicing by this template.
enum isSlicingRange(alias T) = isSlicingRange!(typeof(T));
/// ditto
template isSlicingRange(T){
    enum bool isSlicingRange = isRange!T && is(typeof((inout int = 0){
        auto slice = T.init[0 .. 0];
        static assert(is(typeof(slice) == T));
    }));
}



/// Determine whether a range supports any mutate operations. Ranges must
/// explicitly declare mutability using a "mutable" enum.
enum isMutableRange(alias T) = isMutableRange!(typeof(T));
/// ditto
template isMutableRange(T){
    static if(__traits(compiles, {enum mutable = T.mutable;})){
        enum bool isMutableRange = T.mutable;
    }else{
        enum bool isMutableRange = false;
    }
}



/// Determine whether the front element of a range can be reassigned.
/// The reassignment should persist in whatever collection backs the range, if any.
enum isMutableFrontRange(alias T) = isMutableFrontRange!(typeof(T));
/// ditto
template isMutableFrontRange(T){
    enum bool isMutableFrontRange = isMutableRange!T && is(typeof((inout int = 0){
        T range = T.init;
        auto front = range.front;
        range.front = front;
    }));
}



/// Determine whether the back element of a range can be reassigned.
/// The reassignment should persist in whatever collection backs the range, if any.
enum isMutableBackRange(alias T) = isMutableBackRange!(typeof(T));
/// ditto
template isMutableBackRange(T){
    enum bool isMutableBackRange = isMutableRange!T && is(typeof((inout int = 0){
        T range = T.init;
        auto back = range.back;
        range.back = back;
    }));
}



/// Determine if a randomly-accessed element of a range be reassigned.
/// The reassignment should persist in whatever collection backs the range, if any.
enum isMutableRandomRange(alias T) = isMutableRandomRange!(typeof(T));
/// ditto
template isMutableRandomRange(T){
    enum bool isMutableRandomRange = isMutableRange!T && is(typeof((inout int = 0){
        T range = T.init;
        auto front = range.front;
        range[0] = front;
    }));
}



/// Determine if a range can have an element safely added during consumption.
/// The added element should not be included in the range's iteration.
/// The addition should persist in whatever collection backs the range, if any.
enum isMutableInsertRange(alias T) = isMutableInsertRange!(typeof(T));
/// ditto
template isMutableInsertRange(T){
    enum bool isMutableInsertRange = isMutableRange!T && is(typeof((inout int = 0){
        T range = T.init;
        auto front = range.front;
        range.insert(front);
    }));
}



/// Determine if a range can have the current front element safely removed.
/// Calling removeFront should also implicitly popFront.
/// The removal should persist in whatever collection backs the range, if any.
enum isMutableRemoveFrontRange(alias T) = isMutableRemoveFrontRange!(typeof(T));
/// ditto
template isMutableRemoveFrontRange(T){
    enum bool isMutableRemoveFrontRange = isMutableRange!T && is(typeof((inout int = 0){
        T range = T.init;
        range.removeFront();
    }));
}



/// Determine if a range can have the current back element safely removed.
/// Calling removeBack should also implicitly popBack.
/// The removal should persist in whatever collection backs the range, if any.
enum isMutableRemoveBackRange(alias T) = isMutableRemoveBackRange!(typeof(T));
/// ditto
template isMutableRemoveBackRange(T){
    enum bool isMutableRemoveBackRange = (
        isMutableRange!T && isBidirectionalRange!T
    ) && is(typeof((inout int = 0){
        T range = T.init;
        range.removeBack();
    }));
}



// TODO: Put this stuff somewhere else
template hasEmptyEnum(T){
    import mach.traits.property : hasEnumType;
    enum bool hasEmptyEnum = hasEnumType!(T, bool, `empty`);
}

template hasEmptyEnum(T, bool value){
    static if(hasEmptyEnum!T){
        enum bool hasEmptyEnum = T.empty is value;
    }else{
        enum bool hasEmptyEnum = false;
    }
}

enum hasTrueEmptyEnum(T) = hasEmptyEnum!(T, true);
enum hasFalseEmptyEnum(T) = hasEmptyEnum!(T, false);

enum isFiniteRange(T) = isRange!T && !hasFalseEmptyEnum!T;
enum isInfiniteRange(T) = isRange!T && hasFalseEmptyEnum!T;

unittest{
    struct TrueEnum{enum empty = true;}
    struct FalseEnum{enum empty = false;}
    struct NoEnum{enum x = false;}
    static assert(hasEmptyEnum!TrueEnum);
    static assert(hasEmptyEnum!FalseEnum);
    static assert(!hasEmptyEnum!NoEnum);
    static assert(!hasEmptyEnum!int);
    static assert(hasTrueEmptyEnum!TrueEnum);
    static assert(!hasTrueEmptyEnum!FalseEnum);
    static assert(!hasTrueEmptyEnum!NoEnum);
    static assert(!hasTrueEmptyEnum!int);
    static assert(!hasFalseEmptyEnum!TrueEnum);
    static assert(hasFalseEmptyEnum!FalseEnum);
    static assert(!hasFalseEmptyEnum!NoEnum);
    static assert(!hasFalseEmptyEnum!int);
}



version(unittest){
    private:
    
    template FwdMixin(bool emptyenum = false){
        enum bool empty = emptyenum;
        @property int front(){return 0;}
        void popFront();
    }
    template BiMixin(){
        @property int back(){return 0;}
        void popBack();
    }
    template SaveMixin(){
        @property typeof(this) save(){return this;}
    }
    template RandomMixin(){
        int opIndex(size_t){return 0;}
    }
    template SliceMixin(){
        typeof(this) opSlice(size_t, size_t){return this;}
    }
    template MutFrontMixin(){
        @property void front(int){}
    }
    template MutBackMixin(){
        @property void back(int){}
    }
    template MutRandomMixin(){
        @property void opIndex(int, size_t){}
    }
    template MutInsertMixin(){
        @property void insert(int){}
    }
    template MutRemFrontMixin(){
        @property void removeFront(){}
    }
    template MutRemBackMixin(){
        @property void removeBack(){}
    }
    
    struct NotARange{}
    struct FwdRange{
        mixin FwdMixin;
    }
    struct BiRange{
        mixin FwdMixin;
        mixin BiMixin;
    }
    struct SaveRange{
        mixin FwdMixin;
        mixin SaveMixin;
    }
    struct RandomRange{
        mixin FwdMixin;
        mixin RandomMixin;
    }
    struct EmptyRange{
        mixin FwdMixin!true;
    }
    struct FiniteRange{
        @property bool empty(){return true;}
        @property int front(){return 0;}
        void popFront();
    }
}
unittest{
    FwdRange fwd;
    static assert(isRange!fwd);
    static assert(isRange!FwdRange);
    static assert(isRange!BiRange);
    static assert(isRange!SaveRange);
    static assert(isRange!RandomRange);
    static assert(isRange!EmptyRange);
    static assert(isRange!FiniteRange);
    static assert(!isRange!int);
    static assert(!isRange!NotARange);
    static assert(isBidirectionalRange!BiRange);
    static assert(!isBidirectionalRange!FwdRange);
    static assert(!isBidirectionalRange!int);
    static assert(isSavingRange!SaveRange);
    static assert(!isSavingRange!FwdRange);
    static assert(!isSavingRange!int);
    static assert(isRandomAccessRange!RandomRange);
    static assert(!isRandomAccessRange!FwdRange);
    static assert(!isRandomAccessRange!int);
    static assert(isInfiniteRange!FwdRange);
    static assert(!isInfiniteRange!EmptyRange);
    static assert(!isInfiniteRange!FiniteRange);
    static assert(!isInfiniteRange!int);
    static assert(isFiniteRange!EmptyRange);
    static assert(isFiniteRange!FiniteRange);
    static assert(!isFiniteRange!FwdRange);
    static assert(!isFiniteRange!int);
    // TODO: More tests
}
