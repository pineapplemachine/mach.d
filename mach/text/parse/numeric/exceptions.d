module mach.text.parse.numeric.exceptions;

private:

//

public:



/// Exception raised when a number fails to parse.
class NumberParseException: Exception{
    static enum Reason{
        EmptyString,
        NoDigits,
        InvalidChar,
        MultDecimals,
        MalformedExp,
        MisplacedPadding,
    }
    
    Reason reason;
    
    this(Reason reason, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to parse string as number: " ~ reasonname(reason), file, line, next);
        this.reason = reason;
    }
    
    static string reasonname(in Reason reason){
        final switch(reason){
            case Reason.EmptyString: return "Empty string.";
            case Reason.NoDigits: return "No digits in string.";
            case Reason.InvalidChar: return "Encountered invalid character.";
            case Reason.MultDecimals: return "Multiple decimal points.";
            case Reason.MalformedExp: return "Malformed exponent.";
            case Reason.MisplacedPadding: return "Misplaced padding character.";
        }
    }
    
    static void enforce(T)(auto ref T cond, Reason reason){
        if(!cond) throw new typeof(this)(reason);
    }
    static void enforceempty(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.EmptyString);
    }
    static void enforcedigits(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.NoDigits);
    }
    static void enforceinvalid(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.InvalidChar);
    }
    static void enforcedecimals(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.MultDecimals);
    }
    static void enforcepadding(T)(auto ref T cond){
        typeof(this).enforce(cond, Reason.MisplacedPadding);
    }
}
