module mach.text.parse.numeric.octal;

private:

import std.traits : Unqual, isNumeric, isIntegral, isUnsigned;
import mach.traits : isString;
import mach.range : asrange;
import mach.text.parse.numeric.exceptions;

public:



/// Parse an unsigned octal integer with the digits '0' - '7'.
/// Throws an error when an invalid character is encountered, or if no
/// characters are encountered.
auto parseoct(T = long, S)(auto ref S str) if(isString!S && isNumeric!T){
    auto digit(C)(auto ref C ch){
        NumberParseException.enforceinvalid(ch >= '0' && ch <= '7');
        return ch - '0';
    }
    Unqual!T value = 0;
    size_t chval = void;
    bool anydigits = false;
    foreach(ch; str){
        value <<= 3;
        value |= digit(ch);
        anydigits = true;
    }
    NumberParseException.enforcedigits(anydigits);
    return cast(T) value;
}



/// Get an unsigned integer as a octal string.
/// The output is left-padded according to the size of the inputted type,
/// e.g. ubyte(1).octstr == "001"
auto octstr(T)(T n) if(isIntegral!T && isUnsigned!T){
    char digit(T)(T value){
        return cast(char)(value + '0');
    }
    static if(T.sizeof == 1){
        return [
            digit(n >> 6),
            digit((n >> 3) & 7),
            digit(n & 7)
        ];
    }else static if(T.sizeof == 2){
        return [
            digit(n >> 15),
            digit((n >> 12) & 7),
            digit((n >> 9) & 7),
            digit((n >> 6) & 7),
            digit((n >> 3) & 7),
            digit(n & 7)
        ];
    }else static if(T.sizeof == 4){
        return [
            digit(n >> 30),
            digit((n >> 27) & 7),
            digit((n >> 24) & 7),
            digit((n >> 21) & 7),
            digit((n >> 18) & 7),
            digit((n >> 15) & 7),
            digit((n >> 12) & 7),
            digit((n >> 9) & 7),
            digit((n >> 6) & 7),
            digit((n >> 3) & 7),
            digit(n & 7)
        ];
    }else static if(T.sizeof == 8){
        return [
            digit(n >> 63),
            digit((n >> 60) & 7),
            digit((n >> 57) & 7),
            digit((n >> 54) & 7),
            digit((n >> 51) & 7),
            digit((n >> 48) & 7),
            digit((n >> 45) & 7),
            digit((n >> 42) & 7),
            digit((n >> 39) & 7),
            digit((n >> 36) & 7),
            digit((n >> 33) & 7),
            digit((n >> 30) & 7),
            digit((n >> 27) & 7),
            digit((n >> 24) & 7),
            digit((n >> 21) & 7),
            digit((n >> 18) & 7),
            digit((n >> 15) & 7),
            digit((n >> 12) & 7),
            digit((n >> 9) & 7),
            digit((n >> 6) & 7),
            digit((n >> 3) & 7),
            digit(n & 7)
        ];
    }else{
        static assert(false, "Unhandled numeric type.");
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import std.conv : octal;
}
unittest{
    tests("Octal", {
        tests("To string", {
            testeq(ubyte(octal!"0").octstr, "000");
            testeq(ubyte(octal!"1").octstr, "001");
            testeq(ubyte(octal!"70").octstr, "070");
            testeq(ubyte(octal!"377").octstr, "377");
            testeq(ushort(octal!"0").octstr, "000000");
            testeq(ushort(octal!"70").octstr, "000070");
            testeq(ushort(octal!"123123").octstr, "123123");
            testeq(ushort(octal!"177777").octstr, "177777");
            testeq(uint(octal!"0").octstr, "00000000000");
            testeq(uint(octal!"12312312312").octstr, "12312312312");
            testeq(uint(octal!"37777777777").octstr, "37777777777");
            testeq(ulong(octal!"0").octstr, "0000000000000000000000");
            testeq(ulong(octal!"1231231231231231231231").octstr, "1231231231231231231231");
            testeq(ulong(octal!"1777777777777777777777").octstr, "1777777777777777777777");
        });
        tests("Parse", {
            testeq("0".parseoct, octal!"0");
            testeq("00".parseoct, octal!"0");
            testeq("1".parseoct, octal!"1");
            testeq("01".parseoct, octal!"1");
            testeq("10".parseoct, octal!"10");
            testeq("1234".parseoct, octal!"1234");
            testeq("5670".parseoct, octal!"5670");
            fail({"".parseoct;});
            fail({"hi".parseoct;});
            fail({"0hi".parseoct;});
        });
    });
}
