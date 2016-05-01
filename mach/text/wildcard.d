module mach.text.wildcard;

private:

import std.ascii : toLower;

public:

/// Relatively simple implementation for wildcard characters in strings
class Matcher{
    
    /// Escape a metacharacter in a pattern
    char escapechar = '\\';
    /// Match one of any character
    char wildsingle = '?';
    /// Greedily match at least one character
    char wildplusgreedy = '+';
    /// Lazily match at least one character
    char wildpluslazy = '%';
    /// Greedily match any number of characters
    char wildanygreedy = '*';
    /// Lazily match any number of characters
    char wildanylazy = '.';
    
    bool casesensitivedefault = true;
    
    this(){}
    this(in bool casesensitive){
        this.casesensitivedefault = casesensitive;
    }

    bool match(in string pattern, in string text) const{
        return this.match(pattern, text, 0, 0, this.casesensitivedefault);
    }
    bool match(in string pattern, in string text, in bool casesensitive) const{
        return this.match(pattern, text, 0, 0, casesensitive);
    }
    bool match(in string pattern, in string text, in size_t fromx, in size_t fromy, in bool casesensitive) const{
        
        size_t x = fromx; // Position in text
        size_t y = fromy; // Position in pattern
        
        size_t matchchar(){
            if((pattern[y] == this.escapechar) & (y + 1 < pattern.length)){
                return pattern[y + 1] == text[x] ? 2 : 0;
            }else{
                char ch = pattern[y];
                return(
                    (
                        (ch == text[x]) || (ch == wildsingle) ||
                        (!casesensitive && ch.toLower() == text[x].toLower())
                    ) && !(
                        (ch == wildplusgreedy) | (ch == wildpluslazy) |
                        (ch == wildanygreedy) | (ch == wildanylazy)
                    )
                );
            }
        }
        
        static const string matchlazy = q{
            if(++y >= pattern.length) return true;
            while((x < text.length) & (y < pattern.length)){
                if(matchchar() > 0) break;
                x++;
            }
        };
        static const string matchgreedy = q{
            if(++y >= pattern.length) return true;
            while((x < text.length) & (y < pattern.length)){
                if(matchchar() > 0 && this.match(pattern, text, x, y, casesensitive)){
                    return true;
                }else{
                    x++;
                }
            }
        };
        
        while(true){
            if(y >= pattern.length){
                return x >= text.length;
            }else if(x >= text.length){
                while(y < pattern.length){
                    if((pattern[y] != this.wildanygreedy) & (pattern[y] != this.wildanylazy)) return false;
                    y++;
                }
                return true;
            }
            
            if(pattern[y] == this.wildanylazy){
                mixin(matchlazy);
            }else if(pattern[y] == this.wildpluslazy){
                if(++x >= text.length) return false;
                mixin(matchlazy);
            }else if(pattern[y] == this.wildanygreedy){
                mixin(matchgreedy);
            }else if(pattern[y] == this.wildplusgreedy){
                if(++x >= text.length) return false;
                mixin(matchgreedy);
            }else{
                auto matched = matchchar();
                if(matched > 0){
                    y += matched; x++;
                }else{
                    return false;
                }
            }
        }
        
    }
    
}

unittest{
    
    Matcher wild = new Matcher();
    
    assert(wild.match("test", "test") == true);
    assert(wild.match("test", "toast") == false);
    assert(wild.match("t?st", "test") == true);
    assert(wild.match("t?st", "toot") == false);
    
    assert(wild.match("*", "teeeeeeEEEESSSt") == true);
    assert(wild.match("te*st", "test") == true);
    assert(wild.match("t*st", "teeest") == true);
    assert(wild.match("t*st", "test test test") == true);
    assert(wild.match("one*two*three*four", "onebbbdddtwobbthreefour") == true);
    assert(wild.match("*yes", "testyes") == true);
    assert(wild.match("test*", "testyes") == true);
    assert(wild.match("*testyes*", "testyes") == true);
    assert(wild.match("t*st", "testno") == false);
    
    assert(wild.match(".", "teeeeeeEEEESSSt") == true);
    assert(wild.match("te.st", "test") == true);
    assert(wild.match("t.st", "teeest") == true);
    assert(wild.match("t.st", "test test test") == false);
    assert(wild.match("t.st", "testno") == false);
    
    assert(wild.match("+", "teeeeeeEEEESSSt") == true);
    assert(wild.match("te+st", "test") == false);
    assert(wild.match("t+t", "test") == true);
    assert(wild.match("te+st", "test test test") == true);
    assert(wild.match("t+st", "testno") == false);
    assert(wild.match("testno+", "testno") == false);
    assert(wild.match("test+", "testyes") == true);
    
    assert(wild.match("%", "teeeeeeEEEESSSt") == true);
    assert(wild.match("te%st", "test") == false);
    assert(wild.match("t%t", "test") == true);
    assert(wild.match("te%st", "test test test") == false);
    assert(wild.match("testno%", "testno") == false);
    assert(wild.match("test%", "testyes") == true);
    
    assert(wild.match("**", "test") == true);
    assert(wild.match("+*", "test") == true);
    assert(wild.match("*+", "test") == false);
    assert(wild.match("t.s*t", "test") == true);
    
    assert(wild.match("", "") == true);
    assert(wild.match("*", "") == true);
    assert(wild.match(".", "") == true);
    assert(wild.match("+", "") == false);
    assert(wild.match("%", "") == false);
    
    assert(wild.match("test", "TEST") == false);
    assert(wild.match("test", "TEST", false) == true);
    
    assert(wild.match("a*\\*", "a*") == true);
    assert(wild.match("\\?", "?") == true);
    assert(wild.match("esc*\\?\\?", "escape??") == true);
    assert(wild.match("esc*b\\?\\?", "escape??") == false);
    
}
