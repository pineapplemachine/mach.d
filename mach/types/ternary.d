module mach.types.ternary;

private:

/++ Docs

This module provides an enumeration of
[ternary logic values](https://en.wikipedia.org/wiki/Three-valued_logic)
as well as a wrapper struct type with operator overloads implementing
common ternary logic operations.

The values for this module's ternary logic system are named
"true", "false", and "unknown".
They can be thought of as representing a certainly true state,
a certainly false state, and an uncertain or indeterminate state,
respectively.

+/

unittest { /// Example
    // Using the TernaryValue enum directly
    assert(TernaryValue.True is +1);
    assert(TernaryValue.False is -1);
    assert(TernaryValue.Unknown is 0);
}

unittest { /// Example
    // Using the Ternary type
    assert((Ternary.True & Ternary.True).isTrue);
    assert((Ternary.True & Ternary.False).isFalse);
    assert((Ternary.True & Ternary.Unknown).isUnknown);
}

/++ Docs

Here is a complete list of the operations implemented for the
Ternary struct and their truth tables.

Note that casting a Ternary value to a boolean is the same as
calling its `isTrue` method.

Unary operators `[T, U, F]`:

- Is true **x.isTrue** (returns a bool): `[T, F, F]`
- Is false **x.isFalse** (returns a bool): `[F, F, T]`
- Is unknown **x.isUnknown** (returns a bool): `[F, T, F]`
- Assume true **x.assumeTrue**: `[T, T, F]`
- Assume false **x.assumeFalse**: `[T, F, F]`
- Negation **x.negate**, **-x**: `[F, U, T]`

Binary operators `[T-T, T-U, T-F,  U-T, U-U, U-F,  F-T, F-U, F-F]`:

- Identity **x.identity(y)** `[T, F, F,  F, T, F,  F, F, T]`
- Equality **x.equals(y)**, **x == y** `[T, U, F,  U, U, U,  F, U, T]`
- Implication **x.implies(y)**, **x >> y** `[T, U, F,  T, U, U,  T, T, T]`
- Conjunction **x.and(y)**, **x & y** `[T, U, F,  U, U, F,  F, F, F]`
- Disjunction **x.or(y)**, **x | y** `[T, T, T,  T, U, U,  T, U, F]`
- Exclusive disjunction **x.xor(y)**, **x ^ y** `[F, U, T,  U, U, U,  T, U, F]`

+/

unittest { /// Example
    // Identity (returning a boolean)
    assert(Ternary.True.isTrue is true);
    assert(Ternary.True.isFalse is false);
    assert(Ternary.True.isUnknown is false);
    // Assumption
    assert(Ternary.Unknown.assumeTrue.isTrue);
    assert(Ternary.Unknown.assumeFalse.isFalse);
    // Negation
    assert((-Ternary.False).isTrue);
    assert(Ternary.False.negate.isTrue);
}

unittest { /// Example
    // Identity
    assert(Ternary.True.identity(Ternary.False).isFalse);
    // Equality
    assert(Ternary.True.equals(Ternary.Unknown).isUnknown);
    assert((Ternary.True == Ternary.Unknown).isUnknown);
    // Implication
    assert(Ternary.False.implies(Ternary.Unknown).isTrue);
    assert((Ternary.False >> Ternary.Unknown).isTrue);
    // Conjunction
    assert(Ternary.False.and(Ternary.True).isFalse);
    assert((Ternary.False & Ternary.True).isFalse);
    // Disjunction
    assert(Ternary.False.or(Ternary.True).isTrue);
    assert((Ternary.False | Ternary.True).isTrue);
    // Exclusive disjunction
    assert(Ternary.Unknown.xor(Ternary.True).isUnknown);
    assert((Ternary.Unknown ^ Ternary.True).isUnknown);
}

public:



/// Underlying data type for the TernaryValue enum.
alias TernaryValueType = int;

/// Enumeration of ternary logic values.
enum TernaryValue: TernaryValueType {
    /// Certainly or exclusively true.
    True = 1,
    /// Also called "Maybe", "Null", "Both", "Either".
    Unknown = 0,
    /// Certainly or exclusively false.
    False = -1,
}

/// Wraps a TernaryValue enum value in a struct with various
/// helpful operator overloads.
/// https://en.wikipedia.org/wiki/Three-valued_logic
/// Truth tables for various operations are documented like so:
/// Unary: [T, U, F]
/// Binary: [T-T, T-U, T-F,  U-T, U-U, U-F,  F-T, F-U, F-F]
struct Ternary {
    enum True = Ternary(TernaryValue.True);
    enum Unknown = Ternary(TernaryValue.Unknown);
    enum False = Ternary(TernaryValue.False);
    
    TernaryValue value = TernaryValue.Unknown;
    
    this(T)(in T value) if(
        is(T == Ternary) || is(typeof({auto x = T.init < 0 || T.init > 0;}))
    ) {
        static if(is(T == bool)) {
            this.value = value ? TernaryValue.True : TernaryValue.False;
        }
        else static if(is(T == TernaryValue)) {
            this.value = value;
        }
        else static if(is(T == Ternary)) {
            this.value = value.value;
        }
        else {
            if(value < 0) this.value = TernaryValue.False;
            else if(value > 0) this.value = TernaryValue.True;
            else this.value = TernaryValue.Unknown;
        }
    }
    
    void opAssign(T)(in T numberValue) if(
        is(T == Ternary) || is(typeof({bool x = T.init < 0 || T.init > 0;}))
    ) {
        static if(is(T == bool)) {
            this.value = value ? TernaryValue.True : TernaryValue.False;
        }
        else static if(is(T == TernaryValue)) {
            this.value = value;
        }
        else static if(is(T == Ternary)) {
            this.value = value.value;
        }
        else {
            if(value < 0) this.value = TernaryValue.False;
            else if(value > 0) this.value = TernaryValue.True;
            else this.value = TernaryValue.Unknown;
        }
    }
    
    /// Cast to boolean.
    /// [T, F, F]
    bool opCast(T: bool)() const {
        return this.value is TernaryValue.True;
    }
    
    TernaryValue opCast(T: TernaryValue)() const {
        return this.value;
    }
    
    T opCast(T)() const if(
        is(T == byte) || is(T == short) || is(T == int) || is(T == long)
    ) {
        return cast(T) this.value;
    }
    
    /// [T, F, F]
    bool isTrue() const {
        return this.value > 0;
    }
    /// [F, F, T]
    bool isFalse() const {
        return this.value < 0;
    }
    /// [F, T, F]
    bool isUnknown() const {
        return this.value == 0;
    }
    
    /// Where the value is unknown, assume it represents a true value.
    /// [T, T, F]
    Ternary assumeTrue() const {
        return this.value < 0 ? this : Ternary.True;
    }
    /// Where the value is unknown, assume it represents a false value.
    /// [T, F, F]
    Ternary assumeFalse() const {
        return this.value > 0 ? this : Ternary.False;
    }
    
    /// [F, U, T]
    Ternary negate() const {
        if(this.value > 0) return Ternary.False;
        else if(this.value < 0) return Ternary.True;
        else return Ternary.Unknown;
    }
    
    /// [T, F, F,  F, T, F,  F, F, T]
    Ternary identity(in bool value) {
        if(value) return this.value > 0 ? Ternary.True : Ternary.False;
        else return this.value < 0 ? Ternary.True : Ternary.False;
    }
    Ternary identity(in TernaryValue value) {
        if(value > 0) return this.value > 0 ? Ternary.True : Ternary.False;
        else if(value < 0) return this.value < 0 ? Ternary.True : Ternary.False;
        else return this.value == 0 ? Ternary.True : Ternary.False;
    }
    Ternary identity(in Ternary value) {
        if(value.value > 0) return this.value > 0 ? Ternary.True : Ternary.False;
        else if(value.value < 0) return this.value < 0 ? Ternary.True : Ternary.False;
        else return this.value == 0 ? Ternary.True : Ternary.False;
    }
    
    /// [T, U, F,  T, U, U,  T, T, T]
    Ternary implies(in bool rhsValue) const {
        if(this.value < 0 || rhsValue) return Ternary.True;
        else if(this.value == 0) return Ternary.Unknown;
        else return Ternary.False;
    }
    Ternary implies(in TernaryValue rhsValue) const {
        if(this.value < 0 || rhsValue > 0) return Ternary.True;
        else if(this.value == 0 || rhsValue == 0) return Ternary.Unknown;
        else return Ternary.False;
    }
    Ternary implies(in Ternary rhsValue) const {
        if(this.value < 0 || rhsValue.value > 0) return Ternary.True;
        else if(this.value == 0 || rhsValue.value == 0) return Ternary.Unknown;
        else return Ternary.False;
    }
    
    /// [T, U, F,  U, U, U,  F, U, T]
    Ternary equals(in bool value) const {
        if(this.value > 0) return value ? Ternary.True : Ternary.False;
        if(this.value < 0) return value ? Ternary.False : Ternary.True;
        else return Ternary.Unknown;
    }
    Ternary equals(in TernaryValue value) const {
        if(this.value == 0 || value == 0) return Ternary.Unknown;
        else return (this.value > 0) == (value > 0) ? Ternary.True : Ternary.False;
    }
    Ternary equals(in Ternary value) const {
        if(this.value == 0 || value.value == 0) return Ternary.Unknown;
        else return (this.value > 0) == (value.value > 0) ? Ternary.True : Ternary.False;
    }
    
    /// [T, U, F,  U, U, F,  F, F, F]
    Ternary and(in bool value) const {
        if(value) return this.value <= 0 ? this : Ternary.True;
        else return Ternary.False;
    }
    Ternary and(in TernaryValue value) const {
        return this.value < value ? this : Ternary(value);
    }
    Ternary and(in Ternary value) const {
        return this.value < value.value ? this : value;
    }
    
    /// [T, T, T,  T, U, U,  T, U, F]
    Ternary or(in bool value) const {
        if(!value) return this.value >= 0 ? this : Ternary.False;
        else return Ternary.True;
    }
    Ternary or(in TernaryValue value) const {
        return this.value > value ? this : Ternary(value);
    }
    Ternary or(in Ternary value) const {
        return this.value > value.value ? this : value;
    }
    
    /// [F, U, T,  U, U, U,  T, U, F]
    Ternary xor(in bool value) const {
        if(this.value == 0) return Ternary.Unknown;
        else return (this.value > 0) is value ? Ternary.False : Ternary.True;
    }
    Ternary xor(in TernaryValue value) const {
        if(this.value == 0 || value == 0) return Ternary.Unknown;
        else return this.value == value ? Ternary.False : Ternary.True;
    }
    Ternary xor(in Ternary value) const {
        if(this.value == 0 || value.value == 0) return Ternary.Unknown;
        else return this.value == value.value ? Ternary.False : Ternary.True;
    }
    
    Ternary opEquals(in bool value) {
        return this.equals(value);
    }
    Ternary opEquals(in TernaryValue value) {
        return this.equals(value);
    }
    Ternary opEquals(in Ternary value) {
        return this.equals(value);
    }
    
    /// [F, U, T]
    Ternary opUnary(string op: "-")() const {
        return this.negate();
    }
    
    /// [T, U, F,  T, U, U,  T, T, T]
    Ternary opBinary(string op: ">>", T)(in T value) const if(
        is(T == bool) || is(T == TernaryValue) || is(T == Ternary)
    ) {
        return this.implies(value);
    }
    Ternary opBinaryRight(string op: ">>", T)(in T value) const if(
        is(T == bool) || is(T == TernaryValue)
    ) {
        return Ternary(value).implies(this);
    }
    
    /// [T, U, F,  U, U, F,  F, F, F]
    Ternary opBinary(string op: "&", T)(in T value) const if(
        is(T == bool) || is(T == TernaryValue) || is(T == Ternary)
    ) {
        return this.and(value);
    }
    Ternary opBinaryRight(string op: "&", T)(in T value) const if(
        is(T == bool) || is(T == TernaryValue)
    ) {
        return this.and(value);
    }
    
    /// [T, T, T,  T, U, U,  T, U, F]
    Ternary opBinary(string op: "|", T)(in T value) const if(
        is(T == bool) || is(T == TernaryValue) || is(T == Ternary)
    ) {
        return this.or(value);
    }
    Ternary opBinaryRight(string op: "|", T)(in T value) const if(
        is(T == bool) || is(T == TernaryValue)
    ) {
        return this.or(value);
    }
    
    /// [F, U, T,  U, U, U,  T, U, F]
    Ternary opBinary(string op: "^", T)(in T value) const if(
        is(T == bool) || is(T == TernaryValue) || is(T == Ternary)
    ) {
        return this.xor(value);
    }
    Ternary opBinaryRight(string op: "^", T)(in T value) const if(
        is(T == bool) || is(T == TernaryValue)
    ) {
        return this.xor(value);
    }
    
    /// Get a string representation of this ternary logic value.
    /// ["true", "unknown", "false"]
    string toString() const {
        if(this.value > 0) return "true";
        else if(this.value < 0) return "false";
        else return "unknown";
    }
}



unittest { /// Identity methods: isTrue, isFalse, isUnknown
    assert(Ternary.True.isTrue is true);
    assert(Ternary.True.isFalse is false);
    assert(Ternary.True.isUnknown is false);
    assert(Ternary.False.isFalse is true);
    assert(Ternary.False.isTrue is false);
    assert(Ternary.False.isUnknown is false);
    assert(Ternary.Unknown.isUnknown is true);
    assert(Ternary.Unknown.isTrue is false);
    assert(Ternary.Unknown.isFalse is false);
}

unittest { /// Construct with booleans
    assert(Ternary(true).isTrue);
    assert(Ternary(false).isFalse);
}

unittest { /// Construct with numbers
    assert(Ternary(0).isUnknown);
    assert(Ternary(+1).isTrue);
    assert(Ternary(-1).isFalse);
    assert(Ternary(+128).isTrue);
    assert(Ternary(-128).isFalse);
    assert(Ternary(+1.5).isTrue);
    assert(Ternary(-1.5).isFalse);
    assert(Ternary(float.nan).isUnknown);
    assert(Ternary(+float.infinity).isTrue);
    assert(Ternary(-float.infinity).isFalse);
}

unittest { /// Construct with ternary values
    assert(Ternary(Ternary.Unknown).isUnknown);
    assert(Ternary(Ternary.True).isTrue);
    assert(Ternary(Ternary.False).isFalse);
    assert(Ternary(TernaryValue.Unknown).isUnknown);
    assert(Ternary(TernaryValue.True).isTrue);
    assert(Ternary(TernaryValue.False).isFalse);
}

unittest { /// Cast to boolean
    assert((cast(bool) Ternary.True) is true);
    assert((cast(bool) Ternary.Unknown) is false);
    assert((cast(bool) Ternary.False) is false);
}

unittest { /// Cast to TernaryValue
    assert((cast(TernaryValue) Ternary.True) is TernaryValue.True);
    assert((cast(TernaryValue) Ternary.Unknown) is TernaryValue.Unknown);
    assert((cast(TernaryValue) Ternary.False) is TernaryValue.False);
}

unittest { /// Cast to integer
    assert((cast(int) Ternary.True) is +1);
    assert((cast(int) Ternary.Unknown) is 0);
    assert((cast(int) Ternary.False) is -1);
    assert((cast(byte) Ternary.True) is +1);
    assert((cast(short) Ternary.True) is +1);
    assert((cast(long) Ternary.True) is +1);
}

unittest { /// Negation (-a)
    // Method
    assert(Ternary.True.negate.isFalse);
    assert(Ternary.Unknown.negate.isUnknown);
    assert(Ternary.False.negate.isTrue);
    // Operator overload
    assert((-Ternary.True).isFalse);
    assert((-Ternary.Unknown).isUnknown);
    assert((-Ternary.False).isTrue);
}

unittest { /// Assume true or false
    assert(Ternary.True.assumeTrue.isTrue);
    assert(Ternary.Unknown.assumeTrue.isTrue);
    assert(Ternary.False.assumeTrue.isFalse);
    assert(Ternary.True.assumeFalse.isTrue);
    assert(Ternary.Unknown.assumeFalse.isFalse);
    assert(Ternary.False.assumeFalse.isFalse);
}

unittest { /// Identity (a is b) A.K.A. (a.identity(b))
    // Ternary
    assert((Ternary.True.identity(Ternary.True)).isTrue);
    assert((Ternary.Unknown.identity(Ternary.True)).isFalse);
    assert((Ternary.False.identity(Ternary.True)).isFalse);
    assert((Ternary.True.identity(Ternary.Unknown)).isFalse);
    assert((Ternary.Unknown.identity(Ternary.Unknown)).isTrue);
    assert((Ternary.False.identity(Ternary.Unknown)).isFalse);
    assert((Ternary.True.identity(Ternary.False)).isFalse);
    assert((Ternary.Unknown.identity(Ternary.False)).isFalse);
    assert((Ternary.False.identity(Ternary.False)).isTrue);
    // TernaryValue
    assert((Ternary.True.identity(TernaryValue.True)).isTrue);
    assert((Ternary.Unknown.identity(TernaryValue.True)).isFalse);
    assert((Ternary.False.identity(TernaryValue.True)).isFalse);
    assert((Ternary.True.identity(TernaryValue.Unknown)).isFalse);
    assert((Ternary.Unknown.identity(TernaryValue.Unknown)).isTrue);
    assert((Ternary.False.identity(TernaryValue.Unknown)).isFalse);
    assert((Ternary.True.identity(TernaryValue.False)).isFalse);
    assert((Ternary.Unknown.identity(TernaryValue.False)).isFalse);
    assert((Ternary.False.identity(TernaryValue.False)).isTrue);
    // boolean
    assert((Ternary.True.identity(true)).isTrue);
    assert((Ternary.Unknown.identity(true)).isFalse);
    assert((Ternary.False.identity(true)).isFalse);
    assert((Ternary.True.identity(false)).isFalse);
    assert((Ternary.Unknown.identity(false)).isFalse);
    assert((Ternary.False.identity(false)).isTrue);
}

unittest { /// Equality (a == b)
    // Ternary
    assert((Ternary.True == Ternary.True).isTrue());
    assert((Ternary.Unknown == Ternary.True).isUnknown());
    assert((Ternary.False == Ternary.True).isFalse());
    assert((Ternary.True == Ternary.Unknown).isUnknown());
    assert((Ternary.Unknown == Ternary.Unknown).isUnknown());
    assert((Ternary.False == Ternary.Unknown).isUnknown());
    assert((Ternary.True == Ternary.False).isFalse());
    assert((Ternary.Unknown == Ternary.False).isUnknown());
    assert((Ternary.False == Ternary.False).isTrue());
    // TernaryValue (right)
    assert((Ternary.True == TernaryValue.True).isTrue());
    assert((Ternary.Unknown == TernaryValue.True).isUnknown());
    assert((Ternary.False == TernaryValue.True).isFalse());
    assert((Ternary.True == TernaryValue.Unknown).isUnknown());
    assert((Ternary.Unknown == TernaryValue.Unknown).isUnknown());
    assert((Ternary.False == TernaryValue.Unknown).isUnknown());
    assert((Ternary.True == TernaryValue.False).isFalse());
    assert((Ternary.Unknown == TernaryValue.False).isUnknown());
    assert((Ternary.False == TernaryValue.False).isTrue());
    // TernaryValue (left)
    assert((TernaryValue.True == Ternary.True).isTrue());
    assert((TernaryValue.Unknown == Ternary.True).isUnknown());
    assert((TernaryValue.False == Ternary.True).isFalse());
    assert((TernaryValue.True == Ternary.Unknown).isUnknown());
    assert((TernaryValue.Unknown == Ternary.Unknown).isUnknown());
    assert((TernaryValue.False == Ternary.Unknown).isUnknown());
    assert((TernaryValue.True == Ternary.False).isFalse());
    assert((TernaryValue.Unknown == Ternary.False).isUnknown());
    assert((TernaryValue.False == Ternary.False).isTrue());
    // boolean (right)
    assert((Ternary.True == true).isTrue());
    assert((Ternary.Unknown == true).isUnknown());
    assert((Ternary.False == true).isFalse());
    assert((Ternary.True == false).isFalse());
    assert((Ternary.Unknown == false).isUnknown());
    assert((Ternary.False == false).isTrue());
    // boolean (left)
    assert((true == Ternary.True).isTrue());
    assert((false == Ternary.True).isFalse());
    assert((true == Ternary.Unknown).isUnknown());
    assert((false == Ternary.Unknown).isUnknown());
    assert((true == Ternary.False).isFalse());
    assert((false == Ternary.False).isTrue());
}

unittest { /// Implication (a → b) A.K.A. (a >> b)
    // Ternary
    assert((Ternary.True >> Ternary.True).isTrue());
    assert((Ternary.True >> Ternary.Unknown).isUnknown());
    assert((Ternary.True >> Ternary.False).isFalse());
    assert((Ternary.Unknown >> Ternary.True).isTrue());
    assert((Ternary.Unknown >> Ternary.Unknown).isUnknown());
    assert((Ternary.Unknown >> Ternary.False).isUnknown());
    assert((Ternary.False >> Ternary.True).isTrue());
    assert((Ternary.False >> Ternary.Unknown).isTrue());
    assert((Ternary.False >> Ternary.False).isTrue());
    // TernaryValue (right)
    assert((Ternary.True >> TernaryValue.True).isTrue());
    assert((Ternary.True >> TernaryValue.Unknown).isUnknown());
    assert((Ternary.True >> TernaryValue.False).isFalse());
    assert((Ternary.Unknown >> TernaryValue.True).isTrue());
    assert((Ternary.Unknown >> TernaryValue.Unknown).isUnknown());
    assert((Ternary.Unknown >> TernaryValue.False).isUnknown());
    assert((Ternary.False >> TernaryValue.True).isTrue());
    assert((Ternary.False >> TernaryValue.Unknown).isTrue());
    assert((Ternary.False >> TernaryValue.False).isTrue());
    // TernaryValue (left)
    assert((TernaryValue.True >> Ternary.True).isTrue());
    assert((TernaryValue.True >> Ternary.Unknown).isUnknown());
    assert((TernaryValue.True >> Ternary.False).isFalse());
    assert((TernaryValue.Unknown >> Ternary.True).isTrue());
    assert((TernaryValue.Unknown >> Ternary.Unknown).isUnknown());
    assert((TernaryValue.Unknown >> Ternary.False).isUnknown());
    assert((TernaryValue.False >> Ternary.True).isTrue());
    assert((TernaryValue.False >> Ternary.Unknown).isTrue());
    assert((TernaryValue.False >> Ternary.False).isTrue());
    // boolean (right)
    assert((Ternary.True >> true).isTrue());
    assert((Ternary.True >> false).isFalse());
    assert((Ternary.Unknown >> true).isTrue());
    assert((Ternary.Unknown >> false).isUnknown());
    assert((Ternary.False >> true).isTrue());
    assert((Ternary.False >> false).isTrue());
    // boolean (left)
    assert((true >> Ternary.True).isTrue());
    assert((true >> Ternary.Unknown).isUnknown());
    assert((true >> Ternary.False).isFalse());
    assert((false >> Ternary.True).isTrue());
    assert((false >> Ternary.Unknown).isTrue());
    assert((false >> Ternary.False).isTrue());
}

unittest { /// Conjunction, "and" (a & b)
    // Ternary
    assert((Ternary.True & Ternary.True).isTrue());
    assert((Ternary.True & Ternary.Unknown).isUnknown());
    assert((Ternary.True & Ternary.False).isFalse());
    assert((Ternary.Unknown & Ternary.True).isUnknown());
    assert((Ternary.Unknown & Ternary.Unknown).isUnknown());
    assert((Ternary.Unknown & Ternary.False).isFalse());
    assert((Ternary.False & Ternary.True).isFalse());
    assert((Ternary.False & Ternary.Unknown).isFalse());
    assert((Ternary.False & Ternary.False).isFalse());
    // TernaryValue (right)
    assert((Ternary.True & TernaryValue.True).isTrue());
    assert((Ternary.True & TernaryValue.Unknown).isUnknown());
    assert((Ternary.True & TernaryValue.False).isFalse());
    assert((Ternary.Unknown & TernaryValue.True).isUnknown());
    assert((Ternary.Unknown & TernaryValue.Unknown).isUnknown());
    assert((Ternary.Unknown & TernaryValue.False).isFalse());
    assert((Ternary.False & TernaryValue.True).isFalse());
    assert((Ternary.False & TernaryValue.Unknown).isFalse());
    assert((Ternary.False & TernaryValue.False).isFalse());
    // TernaryValue (left)
    assert((TernaryValue.True & Ternary.True).isTrue());
    assert((TernaryValue.True & Ternary.Unknown).isUnknown());
    assert((TernaryValue.True & Ternary.False).isFalse());
    assert((TernaryValue.Unknown & Ternary.True).isUnknown());
    assert((TernaryValue.Unknown & Ternary.Unknown).isUnknown());
    assert((TernaryValue.Unknown & Ternary.False).isFalse());
    assert((TernaryValue.False & Ternary.True).isFalse());
    assert((TernaryValue.False & Ternary.Unknown).isFalse());
    assert((TernaryValue.False & Ternary.False).isFalse());
    // boolean (right)
    assert((Ternary.True & true).isTrue());
    assert((Ternary.True & false).isFalse());
    assert((Ternary.Unknown & true).isUnknown());
    assert((Ternary.Unknown & false).isFalse());
    assert((Ternary.False & true).isFalse());
    assert((Ternary.False & false).isFalse());
    // boolean (left)
    assert((true & Ternary.True).isTrue());
    assert((true & Ternary.Unknown).isUnknown());
    assert((true & Ternary.False).isFalse());
    assert((false & Ternary.True).isFalse());
    assert((false & Ternary.Unknown).isFalse());
    assert((false & Ternary.False).isFalse());
}

unittest { /// Disjunction, "or" (a | b)
    // Ternary
    assert((Ternary.True | Ternary.True).isTrue());
    assert((Ternary.True | Ternary.Unknown).isTrue());
    assert((Ternary.True | Ternary.False).isTrue());
    assert((Ternary.Unknown | Ternary.True).isTrue());
    assert((Ternary.Unknown | Ternary.Unknown).isUnknown());
    assert((Ternary.Unknown | Ternary.False).isUnknown());
    assert((Ternary.False | Ternary.True).isTrue());
    assert((Ternary.False | Ternary.Unknown).isUnknown());
    assert((Ternary.False | Ternary.False).isFalse());
    // TernaryValue (right)
    assert((Ternary.True | TernaryValue.True).isTrue());
    assert((Ternary.True | TernaryValue.Unknown).isTrue());
    assert((Ternary.True | TernaryValue.False).isTrue());
    assert((Ternary.Unknown | TernaryValue.True).isTrue());
    assert((Ternary.Unknown | TernaryValue.Unknown).isUnknown());
    assert((Ternary.Unknown | TernaryValue.False).isUnknown());
    assert((Ternary.False | TernaryValue.True).isTrue());
    assert((Ternary.False | TernaryValue.Unknown).isUnknown());
    assert((Ternary.False | TernaryValue.False).isFalse());
    // TernaryValue (left)
    assert((TernaryValue.True | Ternary.True).isTrue());
    assert((TernaryValue.True | Ternary.Unknown).isTrue());
    assert((TernaryValue.True | Ternary.False).isTrue());
    assert((TernaryValue.Unknown | Ternary.True).isTrue());
    assert((TernaryValue.Unknown | Ternary.Unknown).isUnknown());
    assert((TernaryValue.Unknown | Ternary.False).isUnknown());
    assert((TernaryValue.False | Ternary.True).isTrue());
    assert((TernaryValue.False | Ternary.Unknown).isUnknown());
    assert((TernaryValue.False | Ternary.False).isFalse());
    // boolean (right)
    assert((Ternary.True | true).isTrue());
    assert((Ternary.True | false).isTrue());
    assert((Ternary.Unknown | true).isTrue());
    assert((Ternary.Unknown | false).isUnknown());
    assert((Ternary.False | true).isTrue());
    assert((Ternary.False | false).isFalse());
    // boolean (left)
    assert((true | Ternary.True).isTrue());
    assert((true | Ternary.Unknown).isTrue());
    assert((true | Ternary.False).isTrue());
    assert((false | Ternary.True).isTrue());
    assert((false | Ternary.Unknown).isUnknown());
    assert((false | Ternary.False).isFalse());
}

unittest { /// Exclusive disjunction, "xor" (a ^ b)
    // Ternary
    assert((Ternary.True ^ Ternary.True).isFalse());
    assert((Ternary.True ^ Ternary.Unknown).isUnknown());
    assert((Ternary.True ^ Ternary.False).isTrue());
    assert((Ternary.Unknown ^ Ternary.True).isUnknown());
    assert((Ternary.Unknown ^ Ternary.Unknown).isUnknown());
    assert((Ternary.Unknown ^ Ternary.False).isUnknown());
    assert((Ternary.False ^ Ternary.True).isTrue());
    assert((Ternary.False ^ Ternary.Unknown).isUnknown());
    assert((Ternary.False ^ Ternary.False).isFalse());
    // TernaryValue (right)
    assert((Ternary.True ^ TernaryValue.True).isFalse());
    assert((Ternary.True ^ TernaryValue.Unknown).isUnknown());
    assert((Ternary.True ^ TernaryValue.False).isTrue());
    assert((Ternary.Unknown ^ TernaryValue.True).isUnknown());
    assert((Ternary.Unknown ^ TernaryValue.Unknown).isUnknown());
    assert((Ternary.Unknown ^ TernaryValue.False).isUnknown());
    assert((Ternary.False ^ TernaryValue.True).isTrue());
    assert((Ternary.False ^ TernaryValue.Unknown).isUnknown());
    assert((Ternary.False ^ TernaryValue.False).isFalse());
    // TernaryValue (left)
    assert((TernaryValue.True ^ Ternary.True).isFalse());
    assert((TernaryValue.True ^ Ternary.Unknown).isUnknown());
    assert((TernaryValue.True ^ Ternary.False).isTrue());
    assert((TernaryValue.Unknown ^ Ternary.True).isUnknown());
    assert((TernaryValue.Unknown ^ Ternary.Unknown).isUnknown());
    assert((TernaryValue.Unknown ^ Ternary.False).isUnknown());
    assert((TernaryValue.False ^ Ternary.True).isTrue());
    assert((TernaryValue.False ^ Ternary.Unknown).isUnknown());
    assert((TernaryValue.False ^ Ternary.False).isFalse());
    // boolean (right)
    assert((Ternary.True ^ true).isFalse());
    assert((Ternary.True ^ false).isTrue());
    assert((Ternary.Unknown ^ true).isUnknown());
    assert((Ternary.Unknown ^ false).isUnknown());
    assert((Ternary.False ^ true).isTrue());
    assert((Ternary.False ^ false).isFalse());
    // boolean (left)
    assert((true ^ Ternary.True).isFalse());
    assert((true ^ Ternary.Unknown).isUnknown());
    assert((true ^ Ternary.False).isTrue());
    assert((false ^ Ternary.True).isTrue());
    assert((false ^ Ternary.Unknown).isUnknown());
    assert((false ^ Ternary.False).isFalse());
}

unittest { /// Ternary toString
    assert(Ternary.True.toString() == "true");
    assert(Ternary.Unknown.toString() == "unknown");
    assert(Ternary.False.toString() == "false");
}
