module mach.text.escape.escaper;

private:

import mach.types : tuple;
import mach.traits : isCharString, validAsStringRange;
import mach.range : asrange, map, chain, any;
import mach.error : IndexOutOfBoundsError;

import mach.text.utf : utf8encode;
import mach.text.html : NamedChar;
import mach.text.numeric : writehex, writeoct;

import mach.text.escape.unescape : UnescapeRange;
import mach.text.escape.exceptions;

public:



struct Escaper{
    struct Pair{
        dchar original;
        char escaped;
        
        this(char escaped){
            this(escaped, escaped);
        }
        this(dchar original, char escaped){
            this.original = original;
            this.escaped = escaped;
        }
        
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
    
    static bool isprintable(in dchar ch){
        return ch >= MinPrintable && ch <= MaxPrintable;
    }
    
    /// The special escape character. Almost always '\'.
    const char escapechar = '\\';
    
    /// Support for escape sequences like \x00
    bool xesc = false;
    /// Support for escape sequences like \u0000
    bool u16esc = false;
    /// Support for escape sequences like \U00000000
    bool u32esc = false;
    /// Support for escape sequences like \0 \00 \000
    bool octesc = false;
    /// The greatest number of digits allowed in an octal escape sequence.
    size_t octesclength = 0;
    /// Support for escape sequences like \&name;
    bool nameesc = false;
    /// Whether \&name; sequences are supported when the name describes more
    /// than one sequential code point.
    bool nameescmulti = false;
    /// Whether unprintable characters can be outputted as-is,
    /// otherwise an exception is thrown if such a character cannot
    /// be made into an escape sequence.
    bool unprintable = true;
    
    /// An array of character/escape sequence pairs.
    Pairs pairs;
    
    /// Escaper for escaping and unescaping string literals with the same
    /// behavior and functionality as D string literals.
    static immutable Escaper D = {
        xesc: true,
        u16esc: true,
        u32esc: true,
        octesc: true,
        octesclength: 3,
        nameesc: true,
        nameescmulti: false,
        unprintable: true,
        pairs: [
            Pair('\''),
            Pair('"'),
            Pair('?'),
            Pair(dchar(0x00), '0'), // Null
            Pair(dchar(0x08), 'b'), // Backspace
            Pair(dchar(0x0C), 'f'), // Form feed
            Pair(dchar(0x0A), 'n'), // Newline
            Pair(dchar(0x0D), 'r'), // Carriage return
            Pair(dchar(0x09), 't'), // Horizontal tab
            Pair(dchar(0x0B), 'v'), // Vertical tab
            Pair(dchar(0x07), 'a')  // Alarm
        ]
    };
    
    // These constructors disabled because their very presence
    // disables {...} initialization syntax.
    static if(false){
        this(char escapechar){
            this(escapechar, []);
        }
        this(Pairs pairs){
            this('\\', pairs);
        }
        this(char escapechar, Pairs pairs){
            this(escapechar, false, false, false, false, 0, false, false, true, pairs);
        }
        
        this(
            char escapechar, bool xesc, bool u16esc, bool u32esc,
            bool octesc, size_t octesclength, bool nameesc, bool nameescmulti,
            bool unprintable, Pairs pairs
        )in{
            assert(escapechar <= 0x7f,
                "Escape prefix must be valid as a single-byte UTF-8 code point."
            );
            foreach(pair; pairs){
                assert(pair.escaped <= 0x7f,
                    "Escape mapping must be valid as a single-byte UTF-8 code point."
                );
            }
        }body{
            this.escapechar = escapechar;
            this.xesc = xesc;
            this.u16esc = u16esc;
            this.u32esc = u32esc;
            this.octesc = octesc;
            this.octesclength = octesclength;
            this.nameesc = nameesc;
            this.nameescmulti = nameescmulti;
            this.unprintable = unprintable;
            this.pairs = pairs;
        }
    }
    
    /// Intelligently select and return an escape sequence for a given input,
    /// or return the character itself if it can be represented without
    /// requiring an escape sequence.
    /// This method is not intended for UTF-8 encoded strings.
    /// For them, use `utf8escape` instead.
    /// Throws a CharEscapeException upon failure.
    string escape(in dchar ch) const{
        static const error = new CharEscapeException();
        if(ch == this.escapechar){
            return [this.escapechar, this.escapechar];
        }else{
            foreach(pair; this.pairs){
                if(ch == pair.original){
                    return cast(string)[this.escapechar, pair.escaped];
                }
            }
            // Regular, single-byte human-readable code point
            // No need to escape these
            if(this.isprintable(ch)){
                return [cast(char) ch];
            // Single-byte non-human-readable code point
            }else if(ch <= 0x7f){
                if(this.xesc){
                    return xescape(ch, this.escapechar);
                }else if(this.canoctescape(ch)){
                    return octescape(ch, this.escapechar);
                }else if(this.cannameescape(ch)){
                    return nameescape(ch, this.escapechar);
                }else if(this.unprintable){
                    return [cast(char) ch];
                }else{
                    throw error;
                }
            // Multiple-byte code point
            }else{
                if(this.xesc){
                    return ptescape(ch, this.escapechar);
                }else if(this.canu16escape(ch)){
                    return u16escape(ch, this.escapechar);
                }else if(this.u32esc){
                    return u32escape(ch, this.escapechar);
                }else if(this.canoctescape(ch)){
                    return octescape(ch, this.escapechar);
                }else if(this.cannameescape(ch)){
                    return nameescape(ch, this.escapechar);
                }else if(this.unprintable){
                    return cast(string) ch.utf8encode.chars;
                }else{
                    throw error;
                }
            }
        }
    }
    
    /// Intelligently select and return an escape sequence for a given input,
    /// or return the character itself if it can be represented without
    /// requiring an escape sequence.
    /// This method is intended only for UTF-8 encoded strings.
    /// For decoded unicode strings, use `escape` instead.
    /// Throws a CharEscapeException upon failure.
    string utf8escape(in char ch) const{
        if(ch == this.escapechar){
            return [this.escapechar, this.escapechar];
        }else{
            if(ch <= 0x7f){
                foreach(pair; this.pairs){
                    if(ch == pair.original){
                        return cast(string)[this.escapechar, pair.escaped];
                    }
                }
            }
            if(this.isprintable(ch)){
                return [cast(char) ch];
            }else{
                if(this.xesc){
                    return xescape(ch, this.escapechar);
                }else if(this.canoctescape(ch)){
                    return octescape(ch, this.escapechar);
                }else if(ch <= 0x7f && this.cannameescape(ch)){
                    return nameescape(ch, this.escapechar);
                }else if(this.unprintable){
                    return [cast(char) ch];
                }else{
                    static const error = new CharEscapeException();
                    throw error;
                }
            }
        }
    }
    
    /// Determine whether some character can be encoded in the outputted
    /// escaped string.
    /// When this method returns false, calling `escape` with the same
    /// argument will cause an exception to be thrown.
    bool canescape(in dchar ch) const{
        return(
            this.unprintable ||
            this.xesc ||
            this.u32esc ||
            ch == this.escapechar ||
            this.isprintable(ch) ||
            this.canu16escape(ch) ||
            this.canoctescape(ch) ||
            this.cannameescape(ch) ||
            this.pairs.any!(pair => pair.original == ch)
        );
    }
    
    /// Determine whether some character can be encoded in the outputted
    /// escaped string.
    /// When this method returns false, calling `utf8escape` with the same
    /// argument will cause an exception to be thrown.
    bool canutf8escape(in char ch) const{
        return(
            this.unprintable ||
            this.xesc ||
            ch == this.escapechar ||
            this.isprintable(ch) ||
            this.canoctescape(ch) ||
            (ch <= 0x7f && (
                this.cannameescape(ch)) ||
                this.pairs.any!(pair => pair.original == ch)
            )
        );
    }
    
    /// Return a range iterating over the same characters in the input string,
    /// with special characters made into escape sequences.
    /// When omitinvalid is true, characters that cannot be encoded using this
    /// object's escape settings are omitted from the output instead of causing
    /// exceptions.
    /// This method is not intended for UTF-8 encoded strings.
    /// For them, use `utf8escape` instead.
    auto escape(bool omitinvalid = false, S)(auto ref S str) const if(validAsStringRange!S){
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
    
    /// Return a range iterating over the same characters in the input string,
    /// with special characters made into escape sequences.
    /// When omitinvalid is true, characters that cannot be encoded using this
    /// object's escape settings are omitted from the output instead of causing
    /// exceptions.
    /// This method is intended only for UTF-8 encoded strings.
    /// For decoded UTF strings, use `escape` instead.
    auto utf8escape(bool omitinvalid = false, S)(auto ref S str) const if(validAsStringRange!S){
        static assert(isCharString!S, "Operation only valid for UTF-8 encoded strings.");
        return str.map!((ch){
            static if(omitinvalid){
                try{
                    return this.utf8escape(ch);
                }catch(CharEscapeException e){
                    return "";
                }
            }else{
                return this.utf8escape(ch);
            }
        }).chain;
    }
    
    /// Whether this escaper is able to use a \u0000 escape sequence to
    /// describe the given char.
    bool canu16escape(in dchar ch) const{
        return this.u16esc && ch <= 0xffff;
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
    
    auto unescape(S)(auto ref S str) const if(validAsStringRange!S){
        auto range = str.asrange;
        return UnescapeRange!(typeof(range))(range, this);
    }
    
    /// Given a character in the range 0x00 - 0xff,
    /// return an escape sequence like "\x00"
    static string xescape(in dchar ch, in char esc){
        version(assert){
            static const error = new IndexOutOfBoundsError("Character out of bounds.");
            const checked = error.enforcei(cast(uint) ch, 0, 0xff);
        }
        return cast(string)([esc, 'x'] ~ writehex(cast(ubyte) ch));
    }
    /// Given a character in the range 0x0000 - 0xffff,
    /// return an escape sequence like "\u0000"
    static string u16escape(in dchar ch, in char esc){
        version(assert){
            static const error = new IndexOutOfBoundsError("Character out of bounds.");
            const checked = error.enforcei(cast(uint) ch, 0, 0xffff);
        }
        return cast(string)([esc, 'u'] ~ writehex(cast(ushort) ch));
    }
    /// Given a character in the range 0x00000000 - 0xffffffff,
    /// return an escape sequence like "\U00000000"
    static string u32escape(in dchar ch, in char esc){
        version(assert){
            static const error = new IndexOutOfBoundsError("Character out of bounds.");
            const checked = error.enforcei(cast(uint) ch, 0, 0xffffffff);
        }
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
        foreach(ch; pt.utf8encode.chars) chars ~= xescape(ch, esc);
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
