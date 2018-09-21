module mach.error.bounds;

private:

import mach.traits.primitives : isIntegral, isNumeric;
import mach.traits.length : hasNumericLength;

/++ Docs

This module provides the throwable types `IndexOutOfBoundsError` and
`InvalidSliceBoundsError`. These are mainly intended to be used as
static singletons, rather than created and thrown anew.

+/

unittest { /// Example
    import mach.test.assertthrows : assertthrows;
    // Statically allocate an error object
    static const boundserror = new IndexOutOfBoundsError();
    // High-exclusive check: enforce 0 <= 5 < 10.
    boundserror.enforce(5, 0, 10);
    // High-exclusive check: enforce 0 <= 6 <= 10.
    boundserror.enforcei(6, 0, 10);
    // Index out of bounds!
    auto thrownerror = assertthrows({
        boundserror.enforce(100, 0, 10);
    });
    // Enforced error throws itself
    assert(thrownerror is boundserror);
}

unittest { /// Example
    import mach.test.assertthrows : assertthrows;
    // Statically allocate an error object
    static const error = new InvalidSliceBoundsError();
    // Slice 1 .. 2 is contained within 0 .. 10.
    error.enforce(1, 2, 0, 10);
    // Slice 100 .. 200 isn't contained within 0 .. 10.
    assertthrows({
        error.enforce(100, 200, 0, 10);
    });
}

/++ Docs

Optionally, some object with a numeric `length` property may be passed to these
types' `enforce` methods instead of a low and a high bound;
in this case the low bound is considered to be zero and the high bound the
length of the passed object.

+/

unittest{
    static const error = new IndexOutOfBoundsError();
    error.enforce(0, [0, 1, 2]); // Index 0 is within the bounds of this array.
}

unittest{
    static const error = new InvalidSliceBoundsError();
    error.enforce(0, 1, [0, 1, 2]); // Slice 0 .. 1 is valid for this array.
}

public:



/// Error class for failed index bounds checks.
class IndexOutOfBoundsError : Error {
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        this("Index out of bounds.");
    }
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, next);
    }
    
    /// High-exclusive bounds check.
    /// If the condition (low <= value < high) is not satisfied, throw this error.
    /// Returns the value being bounds-checked.
    void enforce(V, L, H)(in V value, in L low, in H high) pure @safe @nogc const if(
        isNumeric!V && isNumeric!L && isNumeric!H
    ){
        if(value < low || value >= high) throw this;
    }
    
    /// High-inclusive bounds check.
    /// If the condition (low <= value <= high) is not satisfied, throw this error.
    /// Returns the value being bounds-checked.
    void enforcei(V, L, H)(in V value, in L low, in H high) pure @safe @nogc const if(
        isNumeric!V && isNumeric!L && isNumeric!H
    ){
        if(value < low || value > high) throw this;
    }
    
    /// High-exclusive bounds check.
    /// Low is 0 and high is the length of the passed object.
    /// Returns the value being bounds-checked.
    void enforce(V, Obj)(in V value, auto ref Obj object) const if(
        isNumeric!V && hasNumericLength!Obj
    ){
        this.enforce(value, 0, object.length);
    }
    
    /// High-inclusive bounds check.
    /// Low is 0 and high is the length of the passed object.
    /// Returns the value being bounds-checked.
    void enforcei(V, Obj)(in V value, auto ref Obj object) const if(
        isNumeric!V && hasNumericLength!Obj
    ){
        this.enforcei(value, 0, object.length);
    }
}



/// Error class for failed slice bounds checks.
class InvalidSliceBoundsError: IndexOutOfBoundsError{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        this("Invalid slice.");
    }
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, next, line, file);
    }
    
    /// Check that the slice represented by `slow .. shigh` is entirely
    /// contained within the slice `ilow .. ihigh` and throw this error if not.
    void enforce(SliceLow, SliceHigh, InLow, InHigh)(
        in SliceLow slow, in SliceHigh shigh, in InLow ilow, in InHigh ihigh
    ) pure @safe @nogc const if(
        isNumeric!SliceLow && isNumeric!SliceHigh &&
        isNumeric!InLow && isNumeric!InHigh
    ){
        if(slow < ilow || shigh < slow || ihigh < shigh) throw this;
    }
    
    /// Check that the slice represented by `slow .. shigh` is entirely
    /// contained within the slice `0 .. obj.length` and throw this error if not.
    void enforce(SliceLow, SliceHigh, InObj)(
        in SliceLow slow, in SliceHigh shigh, auto ref InObj obj
    ) const if(
        isNumeric!SliceLow && isNumeric!SliceHigh && hasNumericLength!InObj
    ){
        return this.enforce(slow, shigh, 0, obj.length);
    }
}



/// TODO: Remove this
deprecated auto enforcebounds(A...)(A args){
    static const error = new IndexOutOfBoundsError();
    error.enforce(args);
}
/// ditto
deprecated auto enforceboundsincl(A...)(A args){
    static const error = new IndexOutOfBoundsError();
    error.enforcei(args);
}



private version(unittest) {
    import mach.test.assertthrows : assertthrows;
}

/// High-exclusive index bounds
unittest {
    static const error = new IndexOutOfBoundsError();
    error.enforce(0, -1, 1);
    error.enforce(1, [0, 1, 2]);
    assert(error is assertthrows({
        error.enforce(1, 0, 1);
    }));
    assert(error is assertthrows({
        error.enforce(10, [0, 1]);
    }));
}

/// High-inclusive index bounds
unittest {
    static const error = new IndexOutOfBoundsError();
    error.enforcei(0, -1, 1);
    error.enforcei(1, 0, 1);
    error.enforcei(1, [0, 1, 2]);
    assert(error is assertthrows({
        error.enforcei(10, 0, 1);
    }));
    assert(error is assertthrows({
        error.enforcei(10, [0, 1]);
    }));
}

/// Slice bounds (numeric inputs)
unittest {
    static const error = new InvalidSliceBoundsError();
    error.enforce(0, 0, 0, 0);
    error.enforce(1, 2, 0, 10);
    assert(error is assertthrows({
        error.enforce(0, 2, 0, 1);
    }));
}

/// Slice bounds (input object with length)
unittest {
    static const error = new InvalidSliceBoundsError();
    const array = [1, 2, 3, 4];
    error.enforce(0, 0, array);
    error.enforce(1, 2, array);
    assert(error is assertthrows({
        error.enforce(0, 5, array);
    }));
}
