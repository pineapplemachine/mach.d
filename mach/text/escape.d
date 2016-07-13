/++
    Written by Sophie Kirschner: sophiek@pineapplemachine.com
    zlib/libpng license: https://opensource.org/licenses/Zlib
+/

module mach.text.escape;

public:

class Escaper{
    
    alias Escapes = char[2][];
    
    const char escapechar;
    const Escapes escapes;
    
    static const Escaper D = new Escaper(
        '\\', [
            ['\'', '\''], ['"', '"'], ['?', '?'],
            [cast(char) 0x00, '0'], // Null
            [cast(char) 0x08, 'b'], // Backspace
            [cast(char) 0x0C, 'f'], // Form feed
            [cast(char) 0x0A, 'n'], // Newline
            [cast(char) 0x0D, 'r'], // Carriage return
            [cast(char) 0x09, 't'], // Tab
            [cast(char) 0x0B, 'v'], // Vertical tab
            [cast(char) 0x07, 'a']  // Alarm
        ]
    );
    
    static const Escaper C = new Escaper(
        '\\', [
            ['\'', '\''], ['"', '"'], ['?', '?'],
            [cast(char) 0x08, 'b'], // Backspace
            [cast(char) 0x0C, 'f'], // Form feed
            [cast(char) 0x0A, 'n'], // Newline
            [cast(char) 0x0D, 'r'], // Carriage return
            [cast(char) 0x09, 't'], // Tab
            [cast(char) 0x0B, 'v'], // Vertical tab
            [cast(char) 0x07, 'a']  // Alarm
        ]
    );
        
    static const Escaper Json = new Escaper(
        '\\', [
            ['\'', '\''],
            [cast(char) 0x08, 'b'], // Backspace
            [cast(char) 0x0C, 'f'], // Form feed
            [cast(char) 0x0A, 'n'], // Newline
            [cast(char) 0x0D, 'r'], // Carriage return
            [cast(char) 0x09, 't'], // Tab
            [cast(char) 0x0B, 'v']  // Vertical tab
        ]
    );
    
    static const Escaper Js = new Escaper(
        '\\', [
            ['\'', '\''], ['"', '"'],
            [cast(char) 0x08, 'b'], // Backspace
            [cast(char) 0x0C, 'f'], // Form feed
            [cast(char) 0x0A, 'n'], // Newline
            [cast(char) 0x0D, 'r'], // Carriage return
            [cast(char) 0x09, 't'], // Tab
        ]
    );
    
    static const Escaper Bmax = new Escaper(
        '~', [
            [cast(char) 0x00, '0'], // Null
            [cast(char) 0x0A, 'n'], // Newline
            [cast(char) 0x0D, 'r'], // Carriage return
            [cast(char) 0x09, 't'], // Tab
            [cast(char) 0x22, 'q'], // Quote
        ]
    );
    
    this(Escapes escapes){
        this('\\', escapes);
    }
    this(char escapechar, Escapes escapes){
        this.escapechar = escapechar;
        this.escapes = escapes;
    }
    
    string escape(in char ch) const{
        if(ch == this.escapechar){
            return [this.escapechar, this.escapechar];
        }else{
            foreach(escapepair; this.escapes){
                if(ch == escapepair[0]){
                    return [this.escapechar, escapepair[1]];
                }
            }
        }
        return [ch];
    }
    char unescape(in char ch) const{
        if(ch == this.escapechar){
            return this.escapechar;
        }else{
            foreach(escapepair; this.escapes){
                if(ch == escapepair[1]){
                    return escapepair[0];
                }
            }
        }
        return ch;
    }
    string escape(in string text) const{
        string output = ""; 
        foreach(ch; text){
            output ~= this.escape(ch);
        }
        return output;
    }
    
    string unescape(in string text) const{
        string output = "";
        for(int i = 0; i < text.length; i++){
            auto ch = text[i];
            if(ch == this.escapechar){
                output ~= this.unescape(text[++i]);
            }else{
                output ~= ch;
            }
        }
        return output;
    }
    
}

unittest{
    
    // TODO: More unit tests
    
    void test(string text){
        assert(Escaper.D.unescape(Escaper.D.escape(text)) == text);
    }
    
    test("hi this is a test");
    test("\\");
    test("abc \\\\");
    test("abc \0 \f \t \\\\");
    test("\b\b\t\v");
    test("\\b\\b\\t\\v");
    test("\b\b\t\v ");
    test("\\b\\b\\t\\v ");
    test("\\\\\\\\\\\\");
    
}
