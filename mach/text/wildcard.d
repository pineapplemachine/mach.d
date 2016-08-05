module mach.text.wildcard;

private:

import std.ascii : toLower;

public:



/// Relatively simple implementation for wildcard characters in strings.
class WildMatcher{
    
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



version(unittest) import mach.error.unit;
unittest{
    tests("Wildcards", {
        WildMatcher wild = new WildMatcher();
        tests("Match single character", {
            test (wild.match("test", "test"));
            testf(wild.match("test", "toast"));
            test (wild.match("t?st", "test"));
            testf(wild.match("t?st", "toot"));
        });
        tests("Match any characters greedily", {
            test (wild.match("*", "teeeeeeEEEESSSt"));
            test (wild.match("te*st", "test"));
            test (wild.match("t*st", "teeest"));
            test (wild.match("t*st", "test test test"));
            test (wild.match("one*two*three*four", "onebbbdddtwobbthreefour"));
            test (wild.match("*yes", "testyes"));
            test (wild.match("test*", "testyes"));
            test (wild.match("*testyes*", "testyes"));
            testf(wild.match("t*st", "testno"));
            testf(wild.match("t*st", "notest"));
        });
        tests("Match any characters lazily", {
            test (wild.match(".", "teeeeeeEEEESSSt"));
            test (wild.match("te.st", "test"));
            test (wild.match("t.st", "teeest"));
            testf(wild.match("t.st", "test test test"));
            testf(wild.match("t.st", "testno"));
            testf(wild.match("t.st", "notest"));
        });
        tests("Match at least one character greedily", {
            test (wild.match("+", "teeeeeeEEEESSSt"));
            testf(wild.match("te+st", "test"));
            test (wild.match("t+t", "test"));
            test (wild.match("te+st", "test test test"));
            testf(wild.match("t+st", "testno"));
            testf(wild.match("testno+", "testno"));
            test (wild.match("test+", "testyes"));
        });
        tests("Match at least one character lazily", {
            test (wild.match("%", "teeeeeeEEEESSSt"));
            testf(wild.match("te%st", "test"));
            test (wild.match("t%t", "test"));
            testf(wild.match("te%st", "test test test"));
            testf(wild.match("testno%", "testno"));
            test (wild.match("test%", "testyes"));
        });
        tests("Freaky combinations of metacharacters", {
            test (wild.match("**", "test"));
            test (wild.match("+*", "test"));
            testf(wild.match("*+", "test"));
            test (wild.match("t.s*t", "test"));
        });
        tests("Match an empty string", {
            test (wild.match("", ""));
            test (wild.match("*", ""));
            test (wild.match(".", ""));
            testf(wild.match("+", ""));
            testf(wild.match("%", ""));
        });
        tests("Match without case sensitivity", {
            testf(wild.match("test", "TEST"));
            test (wild.match("test", "TEST", false));
        });
        tests("Match with escaped metacharacters", {
            test (wild.match("a*\\*", "a*"));
            test (wild.match("\\?", "?"));
            test (wild.match("esc*\\?\\?", "escape??"));
            testf(wild.match("esc*b\\?\\?", "escape??"));
        });
    });
}
