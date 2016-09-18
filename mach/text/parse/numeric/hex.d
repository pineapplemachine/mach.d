module mach.text.parse.numeric.hex;

private:

import std.traits : Unqual, isNumeric, isIntegral, isUnsigned;
import mach.traits : isString;
import mach.range : asrange;
import mach.text.parse.numeric.exceptions;

public:



/// Parse an unsigned hexadecimal integer with the digits '0' - '9' and
/// 'a' - 'f', case-insensitive.
/// Throws an error when an invalid character is encountered, or if no
/// characters are encountered.
auto parsehex(T = long, S)(auto ref S str) if(isString!S && isNumeric!T){
    auto digit(C)(auto ref C ch){
        if(ch >= '0' && ch <= '9') return ch - '0';
        else if(ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
        else if(ch >= 'A' && ch <= 'F') return ch - 'A' + 10;
        else throw new NumberParseException(
            NumberParseException.Reason.InvalidChar
        );
    }
    Unqual!T value = 0;
    size_t chval = void;
    bool anydigits = false;
    foreach(ch; str){
        value <<= 4;
        value |= digit(ch);
        anydigits = true;
    }
    NumberParseException.enforcedigits(anydigits);
    return cast(T) value;
}



/// Get an unsigned integer as a hexadecimal string.
/// The output is left-padded according to the size of the inputted type,
/// e.g. ubyte(0x1).hexstr == "01"
auto hexstr(bool uppercase = true, T)(T n) if(isIntegral!T && isUnsigned!T){
    enum string digits = uppercase ? `0123456789ABCDEF` : `0123456789abcdef`;
    static if(T.sizeof == 1){
        return [
            digits[n >> 4],
            digits[n & 0xf]
        ];
    }else static if(T.sizeof == 2){
        return [
            digits[n >> 12],
            digits[(n >> 8) & 0xf],
            digits[(n >> 4) & 0xf],
            digits[n & 0xf]
        ];
    }else static if(T.sizeof == 4){
        return [
            digits[n >> 28],
            digits[(n >> 24) & 0xf],
            digits[(n >> 20) & 0xf],
            digits[(n >> 16) & 0xf],
            digits[(n >> 12) & 0xf],
            digits[(n >> 8) & 0xf],
            digits[(n >> 4) & 0xf],
            digits[n & 0xf]
        ];
    }else static if(T.sizeof == 8){
        return [
            digits[n >> 60],
            digits[(n >> 56) & 0xf],
            digits[(n >> 52) & 0xf],
            digits[(n >> 48) & 0xf],
            digits[(n >> 44) & 0xf],
            digits[(n >> 40) & 0xf],
            digits[(n >> 36) & 0xf],
            digits[(n >> 32) & 0xf],
            digits[(n >> 28) & 0xf],
            digits[(n >> 24) & 0xf],
            digits[(n >> 20) & 0xf],
            digits[(n >> 16) & 0xf],
            digits[(n >> 12) & 0xf],
            digits[(n >> 8) & 0xf],
            digits[(n >> 4) & 0xf],
            digits[n & 0xf]
        ];
    }else{
        static assert(false, "Unhandled numeric type.");
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Hex", {
        tests("To string", {
            testeq(ubyte(0x00).hexstr, "00");
            testeq(ubyte(0x01).hexstr, "01");
            testeq(ubyte(0xF0).hexstr, "F0");
            testeq(ubyte(0xFF).hexstr, "FF");
            testeq(ushort(0x0).hexstr, "0000");
            testeq(ushort(0xF0).hexstr, "00F0");
            testeq(ushort(0x0123).hexstr, "0123");
            testeq(ushort(0xFFFF).hexstr, "FFFF");
            testeq(uint(0x0).hexstr, "00000000");
            testeq(uint(0x01230123).hexstr, "01230123");
            testeq(uint(0xFFFFFFFF).hexstr, "FFFFFFFF");
            testeq(ulong(0x0).hexstr, "0000000000000000");
            testeq(ulong(0xFFFFFFFF).hexstr, "00000000FFFFFFFF");
            testeq(ulong(0x0123012301230123).hexstr, "0123012301230123");
            // Here be unit test weirdness dragons
            //testeq(ulong(0xFFFFFFFFFFFFFFFF).hexstr, "FFFFFFFFFFFFFFFF");
        });
        tests("Parse", {
            testeq("0".parsehex, 0x0);
            testeq("00".parsehex, 0x00);
            testeq("1".parsehex, 0x1);
            testeq("01".parsehex, 0x01);
            testeq("10".parsehex, 0x10);
            testeq("12340".parsehex, 0x12340);
            testeq("56789".parsehex, 0x56789);
            testeq("abcdef".parsehex, 0xabcdef);
            testeq("ABCDEF".parsehex, 0xabcdef);
            fail({"".parsehex;});
            fail({"hi".parsehex;});
            fail({"0hi".parsehex;});
        });
    });
}
