module mach.text.escape.unescape;

private:

import mach.text.utf : utf8encode, unicodevalid;
import mach.text.utf : UTF8EncodePoint, UTFDecodeException, UTFEncodeException;
import mach.text.utf.utf16 : getutf16surrogate;
import mach.text.html : NamedChar;
import mach.text.numeric : parsehex, parseoct;
import mach.text.numeric : NumberParseException;
import mach.traits : isStringRange;
import mach.range : next;

import mach.text.escape.escaper : Escaper;
import mach.text.escape.exceptions;

public:



/// Iterates over some basis iterable of characters, presenting a UTF8-encoded
/// string of its contents after being unescaped, e.g. `\x23` becomes `#`.
struct UnescapeRange(Range) if(isStringRange!Range){
    alias CodePoint = UTF8EncodePoint;
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
        static const error = new StringUnescapeEOFException();
        if(this.source.empty) throw error;
        return this.source.next;
    }
    void setpoints(in dchar ch){
        this.setpoints([ch]);
    }
    void setpoints(in const(dchar)[] chars){
        static const utferror = new StringUnescapeUTFException();
        this.points.length = 0;
        this.points.reserve(chars.length);
        foreach(const ch; chars){
            try{
                this.points ~= ch.utf8encode;
            }catch(UTFEncodeException){
                throw utferror;
            }
        }
        this.onpointindex = 0;
        this.inpointindex = 0;
        this.inpoint = true;
    }
    
    void xunescape(){
        static const hexerror = new StringUnescapeHexException();
        try{
            immutable a = this.nextne;
            immutable b = this.nextne;
            this.frontchar = cast(char) parsehex([a, b]);
        }catch(NumberParseException){
            throw hexerror;
        }
    }
    void u16unescape(){
        static const hexerror = new StringUnescapeHexException();
        try{
            immutable a = this.nextne;
            immutable b = this.nextne;
            immutable c = this.nextne;
            immutable d = this.nextne;
            immutable first = cast(wchar) parsehex([a, b, c, d]);
            if(first < 0xd800 || first > 0xdfff){
                this.setpoints(first);
            }else{ // Surrogate pair
                if(this.nextne != this.escaper.escapechar) throw hexerror;
                if(this.nextne != 'u') throw hexerror;
                immutable e = this.nextne;
                immutable f = this.nextne;
                immutable g = this.nextne;
                immutable h = this.nextne;
                immutable second = cast(wchar) parsehex([e, f, g, h]);
                try{
                    this.setpoints(getutf16surrogate(first, second));
                }catch(UTFDecodeException){
                    static const utferror = new StringUnescapeUTFException();
                    throw utferror;
                }
            }
        }catch(NumberParseException){
            throw hexerror;
        }
    }
    void u32unescape(){
        static const hexerror = new StringUnescapeHexException();
        static const utferror = new StringUnescapeUTFException();
        try{
            immutable a = this.nextne;
            immutable b = this.nextne;
            immutable c = this.nextne;
            immutable d = this.nextne;
            immutable e = this.nextne;
            immutable f = this.nextne;
            immutable g = this.nextne;
            immutable h = this.nextne;
            immutable point = cast(dchar) parsehex([a, b, c, d, e, f, g, h]);
            if(!unicodevalid(point)) throw utferror;
            this.setpoints(point);
        }catch(NumberParseException){
            throw hexerror;
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
        static const nameerror = new StringUnescapeNameException();
        char[NamedChar.LongestName] stname;
        size_t i = 0;
        while(true){
            if(i >= NamedChar.LongestName) throw nameerror;
            immutable ch = this.nextne;
            if(ch == ';') break;
            else stname[i++] = ch;
        }
        immutable name = cast(string) stname[0 .. i];
        if(!NamedChar.isname(name)) throw nameerror;
        immutable pointseq = NamedChar.getpoints(name);
        if(!this.escaper.nameescmulti && pointseq.length != 1) throw nameerror;
        this.setpoints(pointseq);
    }
    
    void popFront(){
        static const eoferror = new StringUnescapeEOFException();
        if(!this.inpoint){
            if(this.source.empty){
                this.isempty = true;
            }else{
                immutable ch0 = this.source.next;
                if(ch0 == this.escaper.escapechar){
                    immutable ch1 = this.nextne;
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
                        static const error = new StringUnescapeUnknownException();
                        throw error;
                    }
                }else{
                    this.frontchar = ch0;
                }
            }
        }
        found:
        if(this.inpoint){
            immutable point = this.points[this.onpointindex];
            this.frontchar = point[this.inpointindex++];
            if(this.inpointindex >= point.length){
                this.inpointindex = 0;
                this.onpointindex++;
                this.inpoint = (this.onpointindex < this.points.length);
            }
        }
    }
}
