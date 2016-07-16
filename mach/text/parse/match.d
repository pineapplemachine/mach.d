module mach.text.parse.match;

private:

//

public:



enum MatchStep: int{
    Forward = +1,
    Backward = -1
}



auto matchflat(
    MatchStep step = MatchStep.Forward, char escape = '\\'
)(
    string text, char delim, size_t offset = 0
){
    if(offset < text.length && text[offset] == delim){
        bool escaped = false;
        for(size_t index = offset + step; (index >= 0) & (index < text.length); index += step){
            if(!escaped){
                escaped = text[index] == escape;
                if(text[index] == delim){
                    static if(step > 0) return text[offset + step .. index];
                    else return text[index - step .. offset];
                }
            }else{
                escaped = false;
            }
        }
    }
    return null;
}

auto matchnested(
    MatchStep step = MatchStep.Forward, char escape = '\\'
)(
    string text, char[2] delims, size_t offset = 0
){
    return matchnested!(step, escape)(text, delims[0], delims[1], offset);
}
auto matchnested(
    MatchStep step = MatchStep.Forward, char escape = '\\'
)(
    string text, char open, char close, size_t offset = 0
){
    if(offset < text.length && text[offset] == (step > 0 ? open : close)){
        bool escaped = false;
        size_t nest = 1;
        for(size_t index = offset + step; (index >= 0) & (index < text.length); index += step){
            if(!escaped){
                nest += (text[index] == open) * step;
                nest -= (text[index] == close) * step;
                escaped = text[index] == escape;
            }else{
                escaped = false;
            }
            if(nest == 0){
                static if(step > 0) return text[offset + step .. index];
                else return text[index - step .. offset];
            }
        }
    }
    return null;
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Parse Block", {
        immutable char[2] Braces = ['{', '}'];
        tests("Flat", {
            testeq("{}".matchnested(Braces), "");
            testeq("{test}".matchnested(Braces), "test");
            testeq("{test}}".matchnested(Braces), "test");
            testeq("{{test}}".matchnested(Braces), "{test}");
            testeq("{\\{test}}".matchnested(Braces), "\\{test");
            testeq("{\\{test\\}}".matchnested(Braces), "\\{test\\}");
            testeq("{test}".matchnested!(MatchStep.Backward)(Braces, 5), "test");
        });
        tests("Nested", {
            testeq("``".matchflat('`'), "");
            testeq("`test`".matchflat('`'), "test");
            testeq("`test``".matchflat('`'), "test");
            testeq("`\\`test``".matchflat('`'), "\\`test");
            testeq("`\\`test\\``".matchflat('`'), "\\`test\\`");
            testeq("`test`".matchflat!(MatchStep.Backward)('`', 5), "test");
        });
    });
}
