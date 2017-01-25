module mach.text.escape.unescape;

private:

import mach.text.utf : utf8encode, UTF8EncodePoint;
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
        StringUnescapeEOFException.enforce(!this.source.empty);
        return this.source.next;
    }
    void setpoints(in dchar ch){
        this.setpoints([ch]);
    }
    void setpoints(in const(dchar)[] chars){
        this.points.length = 0;
        this.points.reserve(chars.length);
        foreach(ch; chars) this.points ~= ch.utf8encode;
        this.onpointindex = 0;
        this.inpointindex = 0;
        this.inpoint = true;
    }
    
    void xunescape(){
        try{
            auto a = this.nextne;
            auto b = this.nextne;
            this.frontchar = cast(char) parsehex([a, b]);
        }catch(NumberParseException e){
            throw new StringUnescapeHexException(e);
        }
    }
    void u16unescape(){
        try{
            auto a = this.nextne;
            auto b = this.nextne;
            auto c = this.nextne;
            auto d = this.nextne;
            this.setpoints(cast(wchar) parsehex([a, b, c, d]));
        }catch(NumberParseException e){
            throw new StringUnescapeHexException(e);
        }
    }
    void u32unescape(){
        try{
            auto a = this.nextne;
            auto b = this.nextne;
            auto c = this.nextne;
            auto d = this.nextne;
            auto e = this.nextne;
            auto f = this.nextne;
            auto g = this.nextne;
            auto h = this.nextne;
            this.setpoints(cast(dchar) parsehex([a, b, c, d, e, f, g, h]));
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
