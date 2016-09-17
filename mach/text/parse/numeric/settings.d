module mach.text.parse.numeric.settings;

private:

import mach.range : contains, indexof;

public:



/// Settings struct used to define behavior of parsing functions.
struct NumberParseSettings{
    static enum NumberParseSettings Binary = {
        digits: "01"d,
    };
    static enum NumberParseSettings Octal = {
        digits: "01234567"d,
    };
    static enum NumberParseSettings Decimal = {
        digits: "0123456789"d,
    };
    static enum NumberParseSettings Hex = {
        digits: "0123456789abcdef"d,
    };
    
    alias Default = Decimal;
    
    /// Allowed digits, in ascending order of value.
    dstring digits = "0123456789"d;
    /// Allowed signs.
    dstring signs = "+-"d;
    /// Signs indicating a value is negative.
    dstring negate = "-"d;
    /// Allowed decimal points.
    dstring decimals = "."d;
    /// Allowed exponent signifiers.
    dstring exponents = "eE"d;
    
    /// Get whether some character is a digit.
    bool isdigit(in dchar ch) const @safe{
        return this.digits.contains(ch);
    }
    /// Get the index of a digit, which also represents its value.
    auto getdigit(in dchar ch) const @safe{
        return this.digits.indexof(ch);
    }
    /// Get the number of digits, which also represents the numeric base.
    @property auto base() const @safe{
        return this.digits.length;
    }
    /// Get the digit representing the number 0.
    @property dchar zero() const @safe in{assert(this.digits.length);} body{
        return this.digits[0];
    }
    /// Get whether some character is a sign.
    bool issign(in dchar ch) const @safe{
        return this.signs.contains(ch);
    }
    /// Get whether some character is a negation sign.
    bool isneg(in dchar ch) const @safe{
        return this.negate.contains(ch);
    }
    /// Get a character used to indicate negation.
    dchar neg() const @safe in{assert(this.negate.length);} body{
        return this.negate[0];
    }
    /// Get whether some character is a decimal point.
    bool isdecimal(in dchar ch) const @safe{
        return this.decimals.contains(ch);
    }
    /// Get whether some character is an exponent signifier.
    bool isexp(in dchar ch) const @safe{
        return this.exponents.contains(ch);
    }
}
