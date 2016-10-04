module mach.text.escape;

private:

import mach.types : tuple;
import mach.text.utf : utfencode, UTFEncodePoint;
import mach.text.html : NamedChar;
import mach.text.parse.numeric : parsehex, writehex, parseoct, writeoct;
import mach.text.parse.numeric : NumberParseException;

import mach.range.asrange : asrange;
import mach.range : map, chain, next;
import mach.traits : isStringRange;
import mach.error : enforceboundsincl;

public:



/// Base class for exceptions thrown when failing to escape or unescape strings.
class EscapeException: Exception{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super(message, file, line, null);
    }
}

/// Exception thrown when escaping a character fails.
class CharEscapeException: EscapeException{
    dchar ch;
    this(dchar ch, size_t line = __LINE__, string file = __FILE__){
        super(
            "Failed to escape character. Character " ~
            "'" ~ (cast(string) ch.utfencode.chars) ~ "' " ~
            "cannot be encoded using these settings.",
            null, line, file
        );
        this.ch = ch;
    }
}

/// Base exception thrown when unescaping a string fails.
class StringUnescapeException: EscapeException{
    this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to unescape string: " ~ message, next, line, file);
    }
}

/// Thrown when unexpected EOF is encountered while unescaping a string.
class StringUnescapeEOFException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Unexpected end of input.", next, line, file);
    }
    static void enforce(T)(auto ref T cond){
        if(!cond) throw new typeof(this);
    }
}
/// Thrown when an unknown escape sequence is encountered while unescaping
/// a string.
class StringUnescapeUnknownException: StringUnescapeException{
    char initial;
    this(char initial, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Unrecognized escape sequence with initial char '" ~ initial ~ "'.", next, line, file);
        this.initial = initial;
    }
    static void enforce(T)(auto ref T cond, char initial){
        if(!cond) throw new typeof(this)(initial);
    }
}
/// Thrown when invalid hex is encountered while unescaping a string.
class StringUnescapeHexException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to parse hexadecimal escape sequence.", next, line, file);
    }
}
/// Thrown when invalid octal is encountered while unescaping a string.
class StringUnescapeOctException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failed to parse octal escape sequence.", next, line, file);
    }
}
/// Thrown when an invalid HTML5 name is encountered while unescaping a string.
class StringUnescapeInvalidNameException: StringUnescapeException{
    string name;
    this(string name, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Invalid named escape sequence \"\\&" ~ name ~ ";\".", next, line, file);
        this.name = name;
    }
    static void enforce(T)(auto ref T cond, string name){
        if(!cond) throw new typeof(this)(name);
    }
}
/// Thrown when an unterminated HTML5 name is encountered while unescaping a string.
class StringUnescapeUnterminatedNameException: StringUnescapeException{
    this(Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Encountered unterminated named escape sequence.", next, line, file);
    }
    static void enforce(T)(auto ref T cond){
        if(!cond) throw new typeof(this);
    }
}




struct Escaper{
    struct Pair{
        dchar original;
        char escaped;
        @property auto astuple(){
            return tuple(this.original, this.escaped);
        }
        alias astuple this;
    }
    
    alias Pairs = Pair[];
    
    /// The first code point that requires only a single byte to store and that
    /// is a human-readable character. (Inclusive.)
    static enum MinPrintable = 0x20;
    /// The final code point that requires only a single byte to store and that
    /// is a human-readable character. (Inclusive.)
    static enum MaxPrintable = 0x7e;
    
    /// The special escape character. Almost always '\'.
    const char escapechar;
    /// An array of character/escape sequence pairs.
    Pairs pairs;
    
    /// Support for escape sequences like \x00
    bool xesc = true;
    /// Support for escape sequences like \u0000
    bool u16esc = true;
    /// Support for escape sequences like \U00000000
    bool u32esc = true;
    /// Support for escape sequences like \0 \00 \000
    bool octesc = true;
    /// The greatest number of digits allowed in an octal escape sequence.
    size_t octesclength = 3;
    /// Support for escape sequences like \&name;
    bool nameesc = true;
    /// Whether \&name; sequences are supported when the name describes more
    /// than one sequential code point.
    bool nameescmulti = false;
    
    static immutable D = Escaper(
        '\\', true, true, true, true, 3, true, false, [
            Pair('\'', '\''),
            Pair('"', '"'),
            Pair('?', '?'),
            Pair(dchar(0x00), '0'), // Null
            Pair(dchar(0x08), 'b'), // Backspace
            Pair(dchar(0x0C), 'f'), // Form feed
            Pair(dchar(0x0A), 'n'), // Newline
            Pair(dchar(0x0D), 'r'), // Carriage return
            Pair(dchar(0x09), 't'), // Tab
            Pair(dchar(0x0B), 'v'), // Vertical tab
            Pair(dchar(0x07), 'a')  // Alarm
        ]
    );
    
    static immutable Json = Escaper(
    );
    
    this(char escapechar){
        this(escapechar, []);
    }
    this(Pairs pairs){
        this('\\', pairs);
    }
    this(char escapechar, Pairs pairs){
        this.escapechar = escapechar;
        this.pairs = pairs;
    }
    this(
        char escapechar, bool xesc, bool u16esc, bool u32esc, bool octesc,
        size_t octesclength, bool nameesc, bool nameescmulti, Pairs pairs
    ){
        this.escapechar = escapechar;
        this.xesc = xesc;
        this.u16esc = u16esc;
        this.u32esc = u32esc;
        this.octesc = octesc;
        this.octesclength = octesclength;
        this.nameesc = nameesc;
        this.nameescmulti = nameescmulti;
        this.pairs = pairs;
    }
    
    /// Intelligently select and return an escape sequence for a given input,
    /// or return the character itself if it can be represented without
    /// requiring an escape sequence.
    /// Throws a CharEscapeException upon failure.
    string escape(in dchar ch) const{
        if(ch == this.escapechar){
            return [this.escapechar, this.escapechar];
        }else{
            foreach(pair; this.pairs){
                if(ch == pair.original){
                    return cast(string)[this.escapechar, pair.escaped];
                }
            }
            if(ch >= MinPrintable && ch <= MaxPrintable){
                return [cast(char) ch];
            }else if(ch <= 0xff && this.xesc){
                return xescape(ch, this.escapechar);
            }else if(ch <= 0xffff && this.u16esc){
                return u16escape(ch, this.escapechar);
            }else if(this.xesc){
                return ptescape(ch, this.escapechar);
            }else if(this.u32esc){
                return u32escape(ch, this.escapechar);
            }else if(this.canoctescape(ch)){
                return octescape(ch, this.escapechar);
            }else if(this.cannameescape(ch)){
                return nameescape(ch, this.escapechar);
            }else if(ch <= 0xff){
                return [cast(char) ch];
            }else{
                return cast(string) ch.utfencode.chars;
            }
        }
    }
    
    /// Return a range iterating over the same characters in the input string,
    /// with special characters made into escape sequences.
    /// When omitinvalid is true, characters that cannot be encoded using this
    /// object's escape settings are omitted from the output instead of causing
    /// exceptions.
    auto escape(bool omitinvalid = false, S)(auto ref S str) const if(isStringRange!S){
        return str.map!((ch){
            static if(omitinvalid){
                try{
                    return this.escape(ch);
                }catch(CharEscapeException e){
                    return "";
                }
            }else{
                return this.escape(ch);
            }
        }).chain;
    }
    
    /// Whether this escaper is able to use an octal escape sequence to
    /// describe the given char.
    bool canoctescape(in dchar ch) const{
        return this.octesc && (
            this.octesclength >= 11 ||
            ch <= (1 << (this.octesclength * 3)) - 1
        );
    }
    /// Whether this escaper is able to use an HTML5 named escape sequence to
    /// describe the given char.
    bool cannameescape(in dchar ch) const{
        return this.nameesc && NamedChar.isnamed(ch);
    }
    
    auto unescape(S)(auto ref S str) const if(isStringRange!S){
        auto range = str.asrange;
        return UnescapeRange!(typeof(range))(range, this);
    }
    
    /// Given a character in the range 0x00 - 0xff,
    /// return an escape sequence like "\x00"
    static string xescape(in dchar ch, in char esc) in{enforceboundsincl(ch, 0, 0xff);} body{
        return cast(string)([esc, 'x'] ~ writehex(cast(ubyte) ch));
    }
    /// Given a character in the range 0x0000 - 0xffff,
    /// return an escape sequence like "\u0000"
    static string u16escape(in dchar ch, in char esc) in{enforceboundsincl(ch, 0, 0xffff);} body{
        return cast(string)([esc, 'u'] ~ writehex(cast(ushort) ch));
    }
    /// Given a character in the range 0x00000000 - 0xffffffff,
    /// return an escape sequence like "\U00000000"
    static string u32escape(in dchar ch, in char esc) in{enforceboundsincl(ch, 0, 0xffffffff);} body{
        return cast(string)([esc, 'U'] ~ writehex(cast(uint) ch));
    }
    /// Given a character of arbitrary value,
    /// return an escape sequence like "\0"
    static string octescape(in dchar ch, in char esc){
        return cast(string)(esc ~ writeoct(cast(uint) ch));
    }
    /// Given a code point return an escape sequence representing an encoded
    /// unicode character, like "\x00\x00\x00"
    static string ptescape(in dchar pt, in char esc){
        char[] chars;
        foreach(ch; pt.utfencode) chars ~= xescape(ch, esc);
        return cast(string) chars;
    }
    /// Given a code point or sequence of code points valid as an HTML5 named
    /// character, return an escape sequence like "\&amp";
    static string nameescape(T)(in T pts, in char esc) in{
        assert(NamedChar.isnamed(pts));
    }body{
        return cast(string)([esc, '&'] ~ NamedChar.getname(pts) ~ ';');
    }
}










/// Iterates over some basis iterable of characters, presenting a UTF-encoded
/// string of its contents after being unescaped, e.g. `\x23` becomes `#`.
struct UnescapeRange(Range){
    alias CodePoint = UTFEncodePoint!char;
    alias CodePoints = CodePoint[];
    
    Range source;
    const(Escaper) escaper;
    bool isempty = false;
    char frontchar = void;
    CodePoints points;
    bool inpoint = false;
    size_t onpointindex = 0;
    size_t inpointindex = 0;
    
    this(Range source, in Escaper escaper){
        this.source = source;
        this.escaper = escaper;
        this.isempty = source.empty;
        if(!this.isempty) this.popFront();
    }
    this(
        Range source, in Escaper escaper, bool isempty, char frontchar,
        CodePoints points, bool inpoint, size_t onpointindex, size_t inpointindex
    ){
        this.source = source;
        this.escaper = escaper;
        this.isempty = isempty;
        this.frontchar = frontchar;
        this.points = points;
        this.inpoint = inpoint;
        this.onpointindex = onpointindex;
        this.inpointindex = inpointindex;
    }
    
    @property bool empty() const{
        return this.isempty;
    }
    @property auto front() const{
        return this.frontchar;
    }
    
    auto nextne(){
        auto value = this.source.next;
        StringUnescapeEOFException.enforce(!this.source.empty);
        return value;
    }
    void setpoints(in dchar ch){
        this.setpoints([ch]);
    }
    void setpoints(in const(dchar)[] chars){
        this.points.length = 0;
        this.points.reserve(chars.length);
        foreach(ch; chars) this.points ~= ch.utfencode;
        this.onpointindex = 0;
        this.inpointindex = 0;
        this.inpoint = true;
    }
    
    void xunescape(){
        try{
            this.frontchar = cast(char) parsehex([
                this.nextne, this.source.next
            ]);
        }catch(NumberParseException e){
            throw new StringUnescapeHexException(e);
        }
    }
    void u16unescape(){
        try{
            this.setpoints(cast(wchar) parsehex([
                this.nextne, this.nextne, this.nextne, this.source.next
            ]));
        }catch(NumberParseException e){
            throw new StringUnescapeHexException(e);
        }
    }
    void u32unescape(){
        try{
            this.setpoints(cast(dchar) parsehex([
                this.nextne, this.nextne, this.nextne, this.nextne,
                this.nextne, this.nextne, this.nextne, this.source.next
            ]));
        }catch(NumberParseException e){
            throw new StringUnescapeHexException(e);
        }
    }
    void octunescape(char first){
        immutable(char)[] digits;
        digits.reserve(this.escaper.octesclength);
        digits ~= first;
        while(
            digits.length < this.escaper.octesclength &&
            !this.source.empty
        ){
            auto n = this.source.front;
            if(n >= '0' && n <= '7'){
                digits ~= n;
                this.source.popFront();
            }else{
                break;
            }
        }
        this.setpoints(cast(dchar) parseoct(digits));
    }
    void nameunescape(){
        char[NamedChar.LongestName] stname;
        size_t i = 0;
        while(true){
            StringUnescapeEOFException.enforce(!this.source.empty);
            StringUnescapeUnterminatedNameException.enforce(
                i < NamedChar.LongestName
            );
            auto ch = this.source.front;
            this.source.popFront();
            if(ch == ';') break;
            else stname[i++] = ch;
        }
        auto name = cast(string) stname[0 .. i];
        StringUnescapeInvalidNameException.enforce(
            NamedChar.isname(name), name
        );
        auto pointseq = NamedChar.getpoints(name);
        StringUnescapeInvalidNameException.enforce(
            this.escaper.nameescmulti || pointseq.length == 1, name
        );
        this.setpoints(pointseq);
    }
    
    void popFront(){
        if(!this.inpoint){
            if(this.source.empty){
                this.isempty = true;
            }else{
                auto ch0 = this.source.next;
                if(ch0 == this.escaper.escapechar){
                    StringUnescapeEOFException.enforce(!this.source.empty);
                    auto ch1 = this.source.next;
                    foreach(pair; this.escaper.pairs){
                        if(ch1 == pair.escaped){
                            this.setpoints(pair.original);
                            goto found;
                        }
                    }
                    if(ch1 == this.escaper.escapechar){
                        this.frontchar = this.escaper.escapechar;
                    }else if(ch1 == 'x' && this.escaper.xesc){
                        this.xunescape();
                    }else if(ch1 == 'u' && this.escaper.u16esc){
                        this.u16unescape();
                    }else if(ch1 == 'U' && this.escaper.u32esc){
                        this.u32unescape();
                    }else if(ch1 == '&' && this.escaper.nameesc){
                        this.nameunescape();
                    }else if(ch1 >= '0' && ch1 <= '7' && this.escaper.octesc){
                        this.octunescape(ch1);
                    }else{
                        throw new StringUnescapeUnknownException(ch1);
                    }
                }else{
                    this.frontchar = ch0;
                }
            }
        }
        found:
        if(this.inpoint){
            immutable auto point = this.points[this.onpointindex];
            this.frontchar = point[this.inpointindex++];
            if(this.inpointindex >= point.length){
                this.inpointindex = 0;
                this.onpointindex++;
                this.inpoint = (this.onpointindex < this.points.length);
            }
        }
    }
}



version(unittest){
    private:
    import mach.test;
    import mach.range.compare : equals;
    import mach.io.log;
    import mach.range;
    auto descape(S)(auto ref S str){return Escaper.D.escape(str);}
    auto dunescape(S)(auto ref S str){return Escaper.D.unescape(str);}
}
unittest{
    tests("Escaper", {
        tests("D", {
            tests("Escaping", {
                test!equals("".descape, ``);
                test!equals(" ".descape, ` `);
                test!equals("test".descape, `test`);
                test!equals("\\".descape, `\\`);
                test!equals("\\\\".descape, `\\\\`);
                test!equals("\"quotes\"".descape, `\"quotes\"`);
                test!equals("\'\"\?\\\0\a\b\f\n\r\t\v".descape, `\'\"\?\\\0\a\b\f\n\r\t\v`);
                test!equals("\x05\x06".descape, `\x05\x06`);
                test!equals("\u1E02\u1E03"d.descape, `\u1E02\u1E03`);
                test!equals("\u03D5\u03D6"d.descape, `\u03D5\u03D6`);
                test!equals("\xF0\x9F\x98\x83"d.descape, `\xF0\x9F\x98\x83`);
            });
            tests("Unescaping", {
                test!equals(``.dunescape, "");
                test!equals(` `.dunescape, " ");
                test!equals(`test`.dunescape, "test");
                test!equals(`\\`.dunescape, "\\");
                test!equals(`\\\\`.dunescape, "\\\\");
                test!equals(`\"quotes\"`.dunescape, "\"quotes\"");
                test!equals(`\'\"\?\\\0\a\b\f\n\r\t\v`.dunescape, "\'\"\?\\\0\a\b\f\n\r\t\v");
                test!equals(`\x05\x06`.dunescape, "\x05\x06");
                test!equals(`\u1E02\u1E03`.dunescape, "\u1E02\u1E03");
                test!equals(`\u03D5\u03D6`.dunescape, "\u03D5\u03D6");
                test!equals(`\xF0\x9F\x98\x83`.dunescape, "\xF0\x9F\x98\x83");
                test!equals(`\0\1\2\3`.dunescape, "\0\1\2\3");
                test!equals("\0\1\2\3".dunescape, "\0\1\2\3");
                test!equals(`\41\41\41`.dunescape, "!!!");
                test!equals(`\101\102\103`.dunescape, "ABC");
                test!equals(`\&lt;\&amp;\&gt;`.dunescape, "\&lt;\&amp;\&gt;");
            });
        });
        tests("x sequences", {
            auto esc = Escaper(
                '\\', true, false, false, false, 0, false, false, []
            );
            test!equals(esc.escape("\xE3\x83\x84"), `\xE3\x83\x84`);
            test!equals(esc.escape("\x00\x01\x02"), `\x00\x01\x02`);
            
            // TODO
        });
        //this(
        //    char escapechar, bool xesc, bool u16esc, bool u32esc, bool octesc,
        //    size_t octesclength, bool nameesc, bool nameescmulti, Pairs pairs
        //){
    });
    //test!equals("\U0001F603"d.escape, `\U0001F603`);
}
