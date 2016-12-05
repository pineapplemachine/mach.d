module mach.text.json.parse;

private:

import mach.text.utf : utf8decode, UTFDecodeException;
import mach.math.floats : fcomposedec;
import mach.text.parse.numeric : WriteFloatSettings;
import mach.text.escape : StringUnescapeException;
import mach.text.json.escape;
import mach.text.json.exceptions;
import mach.text.json.literals;
import mach.text.json.value;

/// Note that this does not include all ASCII whitespace characters,
/// let alone all unicode ones.
/// These are characters which are allowed to be present before and after
/// structual characters, and are ignored.
bool iswhite(in char ch){
    return ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n';
}

/// Note that this differs from the strict unicode definition of what
/// constitutes a control character.
/// These are characters which may not appear in a string literal without
/// being escaped.
bool iscontrol(in dchar ch){
    return ch <= 0x1f;
}

public:



private enum MaxParseDepth = 256; // Try to prevent call stack overflow crashes



/// Parse a json string.
/// Notes:
/// String literals are expected to be UTF-8 encoded. Non-ASCII characters
/// are expected not to appear anywhere outside string literals.
/// By default, the literals "NaN", "Infinite", and "-Infinite" are respected.
/// Otherwise, numeric literals must strictly adhere to how the standard defines
/// them or else they will be rejected.
static auto parsejson(
    WriteFloatSettings floatsettings = JsonValue.EncodeFloatSettingsDefault
)(in string str){
    // Parse the string.
    auto result = parsevalue!floatsettings(str, 0, 1, 0);
    // Consume whitespace at the end of the string.
    auto pos = result.endpos;
    while(pos < str.length && str[pos].iswhite) pos++;
    // If there's any trailing characters other than whitespace, throw an exception.
    if(pos < str.length){
        throw new JsonParseTrailingException(result.endline, result.endpos);
    }
    // All done!
    return result.value;
}



/// Utility used by parser functions to forward position in a string until a
/// non-whitespace character is encountered.
private static void consumews(in string str, ref size_t pos, ref size_t line){
    while(pos < str.length && str[pos].iswhite){
        line += str[pos] == '\n';
        pos++;
    }
}



/// Type returned by `parsevalue` method.
private static struct ParseValueResult{
    JsonValue value;
    size_t endpos;
    size_t endline;
}

/// Parse a json value of indeterminate type.
private static auto parsevalue(
    WriteFloatSettings floatsettings
)(
    in string str,
    in size_t initialpos,
    in size_t initialline,
    in size_t depth
){
    if(depth > MaxParseDepth){
        throw new JsonParseDepthException();
    }
    
    size_t pos = initialpos;
    size_t line = initialline;
    
    consumews(str, pos, line);
    if(pos >= str.length) throw new JsonParseEOFException();
    immutable char initialch = str[pos];
    
    auto begins(in string word){
        return (
            word.length <= (str.length - pos) &&
            str[pos .. pos + word.length] == word
        );
    }
    
    if(begins(NullLiteral)){
        return ParseValueResult(
            JsonValue(null),
            pos + NullLiteral.length, line
        );
    }else if(begins(TrueLiteral)){
        return ParseValueResult(
            JsonValue(true),
            pos + TrueLiteral.length, line
        );
    }else if(begins(FalseLiteral)){
        return ParseValueResult(
            JsonValue(false),
            pos + FalseLiteral.length, line
        );
    }else if(begins(floatsettings.PosNaNLiteral)){
        return ParseValueResult(
            JsonValue(double.nan),
            pos + floatsettings.PosNaNLiteral.length, line
        );
    }else if(begins(floatsettings.NegNaNLiteral)){
        return ParseValueResult(
            JsonValue(-double.nan),
            pos + floatsettings.NegNaNLiteral.length, line
        );
    }else if(begins(floatsettings.PosInfLiteral)){
        return ParseValueResult(
            JsonValue(double.infinity),
            pos + floatsettings.PosInfLiteral.length, line
        );
    }else if(begins(floatsettings.NegInfLiteral)){
        return ParseValueResult(
            JsonValue(-double.infinity),
            pos + floatsettings.NegInfLiteral.length, line
        );
    }else if(initialch == '"'){
        auto result = parsestring(str, pos, line);
        return ParseValueResult(
            JsonValue(result.literal),
            result.endpos, result.endline
        );
    }else if(initialch == '['){
        auto result = parsearray!floatsettings(str, pos, line, depth);
        return ParseValueResult(
            JsonValue(result.array),
            result.endpos, result.endline
        );
    }else if(initialch == '{'){
        auto result = parseobject!floatsettings(str, pos, line, depth);
        return ParseValueResult(
            JsonValue(result.object),
            result.endpos, result.endline
        );
    }else if((initialch >= '0' && initialch <= '9') || initialch == '-'){
        auto result = parsenumber(str, pos, line);
        return ParseValueResult(
            result.integral ? JsonValue(result.integerval) : JsonValue(result.floatval),
            result.endpos, line
        );
    }else{
        throw new JsonParseUnexpectedException(line, pos);
    }
}



/// Type returned by `parsestring` method.
private static struct ParseStringResult{
    string literal;
    size_t endpos;
    size_t endline;
}

/// Parse a json string literal.
private static auto parsestring(
    in string str, 
    in size_t initialpos,
    in size_t initialline
){
    if(str[initialpos] != '"'){
        throw new JsonParseUnexpectedException(
            "string literal", initialline, initialpos
        );
    }
    alias pos = initialpos;
    size_t line = initialline;
    // UTF-8 decoding is needed to ensure parsing doesn't hit
    // false positives for special characters if the byte happens
    // to be within a multi-byte code point.
    try{
        auto utf = str[pos + 1 .. $].utf8decode;
        bool escape = false;
        while(!utf.empty){
            if(escape){
                escape = false;
            }else if(utf.front == '\\'){
                escape = true;
            }else if(utf.front.iscontrol){
                throw new JsonParseControlCharException();
            }else if(utf.front == '"'){
                try{
                    string result = cast(string) jsonunescape(
                        str[pos + 1 .. pos + utf.highindex]
                    );
                    return ParseStringResult(result, pos + utf.highindex + 1, line);
                }catch(StringUnescapeException e){
                    throw new JsonParseEscSeqException(line, pos, e);
                }
            }
            utf.popFront();
        }
    }catch(UTFDecodeException e){
        throw new JsonParseUTFException(line, pos, e);
    }
    throw new JsonParseUnterminatedStrException(initialline, initialpos);
}



/// Type returned by `parsearray` method.
private static struct ParseArrayResult{
    JsonValue[] array;
    size_t endpos;
    size_t endline;
}

/// Parse a json array.
private static auto parsearray(
    WriteFloatSettings floatsettings
)(
    in string str, 
    in size_t initialpos,
    in size_t initialline,
    in size_t depth
){
    if(str[initialpos] != '['){
        throw new JsonParseUnexpectedException(
            "array", initialline, initialpos
        );
    }
    size_t pos = initialpos + 1;
    size_t line = initialline;
    JsonValue[] array;
    while(pos < str.length){
        consumews(str, pos, line);
        if(str[pos] == ']'){
            return ParseArrayResult(array, pos + 1, line);
        }else if(array.length == 0 || (str[pos] == ',' && array.length > 0)){
            auto value = parsevalue!floatsettings(
                str, pos + (array.length > 0), line, depth + 1
            );
            pos = value.endpos;
            line = value.endline;
            array ~= value.value;
        }else{
            throw new JsonParseUnexpectedException(
                "end or continuation of array", line, pos
            );
        }
    }
    throw new JsonParseEOFException();
}



/// Type returned by `parseobject` method.
private static struct ParseObjectResult{
    JsonValue[string] object;
    size_t endpos;
    size_t endline;
}

/// Parse a json object.
private static auto parseobject(
    WriteFloatSettings floatsettings
)(
    in string str,
    in size_t initialpos,
    in size_t initialline,
    in size_t depth
){
    if(str[initialpos] != '{'){
        throw new JsonParseUnexpectedException(
            "object", initialline, initialpos
        );
    }
    size_t pos = initialpos + 1;
    size_t line = initialline;
    JsonValue[string] object;
    
    while(pos < str.length){
        consumews(str, pos, line);
        if(str[pos] == '}'){
            return ParseObjectResult(object, pos + 1, line);
        }else if(object.length == 0 || (str[pos] == ',' && object.length > 0)){
            // Parse key
            pos += (object.length > 0);
            if(pos >= str.length) throw new JsonParseEOFException();
            consumews(str, pos, line);
            auto key = parsestring(str, pos, line);
            if(key.literal in object){
                throw new JsonParseDupKeyException(key.literal, line, pos);
            }
            // Parse value
            pos = key.endpos;
            line = key.endline;
            consumews(str, pos, line);
            if(pos >= str.length){
                throw new JsonParseEOFException();
            }else if(str[pos] != ':'){
                throw new JsonParseUnexpectedException(
                    "key, value delimiter", line, pos
                );
            }
            auto value = parsevalue!floatsettings(str, pos + 1, line, depth + 1);
            pos = value.endpos;
            line = value.endline;
            // Add key, value pair to object
            object[key.literal] = value.value;
        }else{
            throw new JsonParseUnexpectedException(
                "end or continuation of object", line, pos
            );
        }
    }
    throw new JsonParseEOFException();
}



/// Type returned by `parsenumber` method.
private static struct ParseNumberResult{
    /// Whether this is an integral or floating point value
    bool integral;
    /// Whether the number or some component of it was too large and thereby
    /// rendered the resulting value inaccurate.
    bool overflow;
    
    union{
        long integerval;
        double floatval;
    }
    
    size_t endpos;
    
    this(long integerval, bool overflow, size_t endpos){
        this.integral = true;
        this.integerval = integerval;
        this.endpos = endpos;
    }
    this(double floatval, bool overflow, size_t endpos){
        this.integral = false;
        this.floatval = floatval;
        this.endpos = endpos;
    }
}

/// The number parser has many possible states, and here all of them are
/// enumerated.
private static enum ParseNumberState{
    /// Initial parsing state.
    /// Implies: Expecting the sign or first digit of the integral part.
    IntegralInitial,
    /// Set after finding a sign for integral value.
    /// Implies: Expecting the first digit of the integral part.
    IntegralSigned,
    /// Parsing integral digits.
    /// Implies: Consuming digits until a decimal, exponent, or valid end of literal.
    Integral,
    /// Encountered integral with a leading zero.
    /// Implies: Expecting a decimal, exponent, or valid end of literal.
    IntegralZero,
    /// Set after encountering a decimal point.
    /// Implies: Expecting the first digit of the fractional part.
    FractionInitial,
    /// Parsing fractional digits.
    /// Implies: Consuming digits until an exponent or valid end of literal.
    Fraction,
    /// Set after encountering 'e' or 'E'.
    /// Implies: Expecting the sign or first digit of the exponent part.
    ExponentInitial,
    /// Set after finding a sign for exponent value.
    /// Implies: Expecting the first digit of the exponent part.
    ExponentSigned,
    /// Parsing exponent digits.
    /// Implies: Consuming digits until valid end of literal.
    Exponent,
}

/// Parse a json numeric literal. Returns a double.
private static auto parsenumber(
    in string str, 
    in size_t initialpos,
    in size_t initialline
){
    if(!(str[initialpos] == '-' || (str[initialpos] >= '0' && str[initialpos] <= '9'))){
        throw new JsonParseUnexpectedException(
            "numeric literal", initialline, initialpos
        );
    }
    
    // Position in string
    size_t pos = initialpos;
    alias line = initialline;
    
    // Current parsing state
    alias State = ParseNumberState;
    State state = State.IntegralInitial;
    
    ulong mantissa; // Stores the most significant digits of the mantissa.
    uint mantdigits; // Number of digits in the mantissa; can be less than the number in the string.
    uint decimal; // Number of digits preceding the decimal point.
    bool mantnegative; // Whether the mantissa is negative
    bool mantoverflow; // Whether the mantissa overflowed.
    
    uint exponent; // Exponent
    bool expnegative; // Whether the exponent is negative
    bool expoverflow; // Whether the exponent overflowed.
    
    auto addmantdigit(char ch){
        if(!mantoverflow){
            immutable t = (mantissa * 10) + (ch - '0');
            if(t < mantissa){
                mantoverflow = true;
            }else{
                mantissa = t;
                mantdigits++;
            }
        }
    }
    auto addexpdigit(char ch){
        if(!expoverflow){
            immutable t = (exponent * 10) + (ch - '0');
            if(t < exponent){
                expoverflow = true;
            }else{
                exponent = t;
            }
        }
    }
    
    // Main parsing loop
    while(pos < str.length){
        immutable char ch = str[pos];
        if(ch.iswhite || ch == ',' || ch == ']' || ch == '}'){
            break; // Valid terminating characters
        }else if(ch == '0' && (state is State.IntegralInitial || state is State.IntegralSigned)){
            state = State.IntegralZero;
        }else if(ch >= '0' && ch <= '9'){
            final switch(state){
                case State.IntegralInitial:
                    goto case;
                case State.IntegralSigned:
                    state = State.Integral;
                    goto case;
                case State.Integral:
                    addmantdigit(ch);
                    decimal++;
                    break;
                case State.IntegralZero:
                    throw new JsonParseNumberException(line, pos);
                    goto case;
                case State.FractionInitial:
                    state = State.Fraction;
                    goto case;
                case State.Fraction:
                    addmantdigit(ch);
                    break;
                case State.ExponentInitial:
                    goto case;
                case State.ExponentSigned:
                    state = State.Exponent;
                    goto case;
                case State.Exponent:
                    exponent = (exponent * 10) + (ch - '0');
                    break;
            }
        }else if(ch == '.'){
            if(state is State.Integral || state is State.IntegralZero){
                state = State.FractionInitial;
            }else{
                throw new JsonParseNumberException(line, pos);
            }
        }else if(ch == '-'){
            if(state is State.IntegralInitial){
                mantnegative = true;
                state = State.IntegralSigned;
            }else if(state is State.ExponentInitial){
                expnegative = true;
                state = State.ExponentSigned;
            }else{
                throw new JsonParseNumberException(line, pos);
            }
        }else if(ch == '+'){
            if(state is State.ExponentInitial){
                state = State.ExponentSigned;
            }else{
                throw new JsonParseNumberException(line, pos);
            }
        }else if(ch == 'e' || ch == 'E'){
            if(state is State.Fraction || state is State.Integral || state is State.IntegralZero){
                state = State.ExponentInitial;
            }else{
                throw new JsonParseNumberException(line, pos);
            }
        }else{
            throw new JsonParseNumberException(line, pos);
        }
        pos++;
    }
    
    // Calculate and return the parsed value
    final switch(state){
        // Invalid termination for these states
        case State.IntegralInitial:
        case State.IntegralSigned:
        case State.FractionInitial:
        case State.ExponentInitial:
        case State.ExponentSigned:
            if(pos >= str.length){
                throw new JsonParseEOFException();
            }else{
                throw new JsonParseNumberException(line, pos);
            }
        // Ok states for termination
        case State.Integral:
            if(mantoverflow || mantissa > long.max){
                return ParseNumberResult(
                    mantnegative ? long.min : long.max, true, pos
                );
            }else{
                return ParseNumberResult(
                    mantnegative ? -(cast(long) mantissa) : mantissa, false, pos
                );
            }
        case State.IntegralZero:
            return ParseNumberResult(long(0), false, pos);
        case State.Fraction:
        case State.Exponent:
            immutable int sexp = (
                (expnegative ? -(cast(int) exponent) : cast(int) exponent) +
                decimal - mantdigits
            );
            immutable double value = fcomposedec!double(mantnegative, mantissa, sexp);
            return ParseNumberResult(
                value, mantoverflow | expoverflow, pos
            );
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.math.floats : fisnan, fisposinf, fisneginf;
    alias Type = JsonValue.Type;
}
unittest{
    tests("Parse json", {
        tests("Malformed input", {
            testfail({``.parsejson;});
            testfail({`n`.parsejson;});
            testfail({`nul`.parsejson;});
            testfail({`nulll`.parsejson;});
            testfail({`"`.parsejson;});
            testfail({`"""`.parsejson;});
            testfail({`""x`.parsejson;});
            testfail({`[`.parsejson;});
            testfail({`{`.parsejson;});
            testfail({`]`.parsejson;});
            testfail({`}`.parsejson;});
            testfail({`[]]`.parsejson;});
            testfail({`{}}`.parsejson;});
            testfail({`.`.parsejson;});
            testfail({`.0`.parsejson;});
            testfail({`0.`.parsejson;});
            testfail({`{notakey:"hi"}`.parsejson;});
            testfail({`{0:"hi"}`.parsejson;});
            testfail({`{"hi":notaliteral}`.parsejson;});
            testfail({`<.>`.parsejson;});
        });
        tests("Literals", {
            testeq(`null`.parsejson, null);
            testeq(`true`.parsejson, true);
            testeq(`false`.parsejson, false);
            test!fisnan(cast(double) `NaN`.parsejson);
            test!fisposinf(cast(double) `Infinite`.parsejson);
            test!fisneginf(cast(double) `-Infinite`.parsejson);
        });
        tests("Numbers", {
            testeq(`0`.parsejson, 0);
            testeq(`1`.parsejson, 1);
            testeq(`-1`.parsejson, -1);
            testeq(`0.0`.parsejson, 0.0);
            testeq(`0.5`.parsejson, 0.5);
            testeq(`-0.5`.parsejson, -0.5);
            testeq(`0e1`.parsejson, 0e1);
            testeq(`1e2`.parsejson, 1e2);
            testeq(`1e-2`.parsejson, 1e-2);
            testeq(`1.5e2`.parsejson, 1.5e2);
            testeq(`1.5e-2`.parsejson, 1.5e-2);
        });
        tests("Strings", {
            testeq(`""`.parsejson, ``);
            testeq(`" "`.parsejson, ` `);
            testeq(`"x"`.parsejson, `x`);
            testeq(`"hello"`.parsejson, `hello`);
            testeq(`"\\"`.parsejson, "\\");
            testeq(`"\t"`.parsejson, "\t");
            testeq(`"\""`.parsejson, "\"");
        });
        tests("Arrays", {
            tests("Empty", {
                testeq("[]".parsejson, new int[0]);
                testeq("[ ]".parsejson, new int[0]);
            });
            tests("Homogenous", {
                testeq("[true]".parsejson, [true]);
                testeq("[ true]".parsejson, [true]);
                testeq("[true ]".parsejson, [true]);
                testeq("[ true ]".parsejson, [true]);
                testeq("[\ntrue\n]".parsejson, [true]);
                testeq("[false]".parsejson, [false]);
                testeq("[0]".parsejson, [0]);
                testeq("[0,1,2]".parsejson, [0, 1, 2]);
                testeq("[0, 1, 2]".parsejson, [0, 1, 2]);
                testeq("[ 0 , 1 ,2 ]".parsejson, [0, 1, 2]);
                testeq(`["x"]`.parsejson, ["x"]);
                testeq(`["x", "y"]`.parsejson, ["x", "y"]);
                testeq(`["apple", "bear", "cat"]`.parsejson, ["apple", "bear", "cat"]);
            });
            tests("Null", {
                {
                    auto array = "[null]".parsejson;
                    testeq(array.length, 1);
                    testeq(array[0], null);
                }{
                    auto array = "[null, null]".parsejson;
                    testeq(array.length, 2);
                    testeq(array[0], null);
                    testeq(array[1], null);
                }
            });
            tests("Mixed", {
                auto array = `[null, false, 1, 2.0, "3"]`.parsejson;
                testeq(array.length, 5);
                testeq(array[0], null);
                testeq(array[1], false);
                testeq(array[2], 1);
                testeq(array[3], 2.0);
                testeq(array[4], "3");
            });
            tests("Nested", {
                auto array = `[0, [], 1, [0], 2, [[0]]]`.parsejson;
                testeq(array.length, 6);
                testeq(array[0], 0);
                testeq(array[1], new int[0]);
                testeq(array[2], 1);
                testeq(array[3], [0]);
                testeq(array[4], 2);
                testeq(array[5], [[0]]);
            });
        });
        tests("Objects", {
            string[string] emptyaa;
            tests("Empty", {
                testeq("{}".parsejson, emptyaa);
                testeq("{ }".parsejson, emptyaa);
            });
            tests("Single", {
                testeq(`{"true":true}`.parsejson, ["true": true]);
                testeq(`{"a":"apple"}`.parsejson, ["a": "apple"]);
                testeq(`{"a": "apple" }`.parsejson, ["a": "apple"]);
                testeq(`{ "a": "apple"}`.parsejson, ["a": "apple"]);
            });
            tests("Homogenous", {
                testeq(`{"a": "apple", "b": "bear", "c": "car"}`.parsejson,
                    ["a": "apple", "b": "bear", "c": "car"]
                );
                testeq(`{"a": 1, "b": 2, "c": 3, "d": 4}`.parsejson,
                    ["a": 1, "b": 2, "c": 3, "d": 4]
                );
            });
            tests("Mixed", {
                auto obj = `{
                    "null": null,
                    "t": true,
                    "f": false,
                    "bools": [true, false],
                    "int": 1,
                    "float": 2.0,
                    "string": "3",
                    "empty": {},
                    "nested": {"hi": {}}
                }`.parsejson;
                testeq(obj.length, 9);
                testeq(obj["null"], null);
                testeq(obj["t"], true);
                testeq(obj["f"], false);
                testeq(obj["bools"], [true, false]);
                testeq(obj["int"], 1);
                testeq(obj["float"], 2.0);
                testeq(obj["string"], "3");
                testeq(obj["empty"], emptyaa);
                testeq(obj["nested"], JsonValue(["hi": emptyaa]));
            });
        });
    });
}
