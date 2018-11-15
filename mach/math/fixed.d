module mach.math.fixed;

private:

import mach.traits.primitives : isNumeric, isFloatingPoint, isIntegral;
import mach.traits.primitives : isSignedIntegral, isUnsignedIntegral;
import mach.math.bits.pow2 : pow2d;

// TODO: More documentation and tests

/++ Docs

This module implements a fixed-point numeric type.

++/

unittest { /// Example
    Fixed!int fixed = 1234.5;
    assert(fixed + 0.5 == 1235);
}

public:



/// Convenient alias for a fixed-point number type with
/// 4 integer bits and 4 fraction bits.
alias Fixed8 = Fixed!byte;

/// Convenient alias for a fixed-point number type with
/// 8 integer bits and 8 fraction bits.
alias Fixed16 = Fixed!short;

/// Convenient alias for a fixed-point number type with
/// 16 integer bits and 16 fraction bits.
alias Fixed32 = Fixed!int;

/// Convenient alias for a fixed-point number type with
/// 32 integer bits and 32 fraction bits.
alias Fixed64 = Fixed!long;

/// Fixed-point number. The scaling factor is (2 ** Radix).
/// The default radix is half the bits of the integer type.
struct Fixed(T, uint radix = (4 * T.sizeof)) if(isSignedIntegral!T) {
    /// The internal integer value type.
    alias Value = T;
    /// The position of the radix; represents the number of bits after
    // the decimal point.
    enum uint Radix = radix;
    
    /// The number of fraction bits. (Bits after the radix)
    static enum T FractionBits = cast(T) Radix;
    /// The number of integer bits. (Bits before the radix)
    static enum T IntegerBits = cast(T)((8 * T.sizeof) - FractionBits);
    /// Divide the internal value by the scaling factor to get an actual value.
    static enum T ScalingFactor = cast(T)(T(1) << Radix);
    /// Bitwise-and with this mask to isolate the integral part.
    static enum T IntegerMask = cast(T)(cast(T)(pow2d!IntegerBits) << FractionBits);
    /// Bitwise-and with this mask to isolate the fractional part.
    static enum T FractionMask = cast(T) pow2d!FractionBits;
    
    /// Internal integer representation of the value of `1`.
    static enum T One = cast(T)(T(1) + FractionMask);
    
    /// Internal integer representation of the fixed-point value.
    T value;
    
    static make(in T value) {
        typeof(this) fixed;
        fixed.value = value;
        return fixed;
    }
    
    /// Initialize from an integer primitive.
    this(N)(in N value) if(isIntegral!N) {
        this = value;
    }
    
    /// Initialize from a floating point value.
    this(N)(in N value) if(isFloatingPoint!N) {
        this = value;
    }
    
    /// Round to the nearest integral value.
    /// Rounds up when the fractional value is 0.5.
    typeof(this) round() {
        enum T Half = ScalingFactor >> 1;
        const T floor = this.value & IntegerMask;
        const T fraction = this.value & FractionMask;
        if(fraction < Half) {
            return typeof(this).make(floor);
        }else{
            return typeof(this).make(cast(T)(One + floor));
        }
    }
    /// Round to the lowest integral value.
    typeof(this) floor() {
        return typeof(this).make(this.value & IntegerMask);
    }
    /// Round to the highest integral value.
    typeof(this) ceil() {
        const T floor = this.value & IntegerMask;
        if(floor == this.value) {
            return typeof(this).make(floor);
        }else{
            return typeof(this).make(cast(T)(One + floor));
        }
    }
    
    N opCast(N)() if(isIntegral!N) {
        return cast(N)(this.value >> FractionBits);
    }
    N opCast(N)() if(isFloatingPoint!N) {
        return cast(N)(this.value) / ScalingFactor;
    }
    
    void opAssign(N)(in N value) if(isIntegral!N) {
        this.value = cast(T)(value) << FractionBits;
    }
    void opAssign(N)(in N value) if(isFloatingPoint!N) {
        this.value = cast(T) (value * ScalingFactor);
    }
    
    bool opEquals(in typeof(this) value) {
        return this.value == value.value;
    }
    bool opEquals(N)(in N value) if(isIntegral!N) {
        static if(N.sizeof > T.sizeof) {
            if(value > T.max || value < T.min){
                return false;
            }
        }
        return ((cast(T) value) << FractionBits) == this.value;
    }
    bool opEquals(N)(in N value) if(isFloatingPoint!N) {
        return value == (cast(N) this);
    }
    
    int opCmp(in typeof(this) value) {
        if(this.value < value.value) {
            return -1;
        }else if(this.value > value.value) {
            return +1;
        }else{
            return 0;
        }
    }
    int opCmp(N)(in N value) if(isIntegral!N) {
        static if(N.sizeof > T.sizeof) {
            const N integral = (cast(N) this.value) << FractionBits;
            if(integral > this.value){
                return -1;
            }else if(integral < this.value){
                return +1;
            }else{
                return 0;
            }
        }else{
            return this.opCmp(typeof(this)(value));
        }
    }
    
    typeof(this) opBinary(string op, N)(in N value) if(isNumeric!N) {
        mixin(`return this ` ~ op ~ ` typeof(this)(value);`);
    }
    typeof(this) opBinaryRight(string op, N)(in N value) if(isNumeric!N) {
        mixin(`return typeof(this)(value) ` ~ op ~ ` this;`);
    }
    
    typeof(this) opBinary(string op: "+", N: typeof(this))(in N value) {
        return typeof(this).make(this.value + value.value);
    }
    typeof(this) opBinary(string op: "-", N: typeof(this))(in N value) {
        return typeof(this).make(this.value - value.value);
    }
    typeof(this) opBinary(string op: "*", N: typeof(this))(in N value) {
        return typeof(this).make(this.value * value.value);
    }
    typeof(this) opBinary(string op: "/", N: typeof(this))(in N value) {
        return typeof(this).make(this.value / value.value);
    }
    typeof(this) opBinary(string op: "%", N: typeof(this))(in N value) {
        return typeof(this).make(this.value % value.value);
    }
}
