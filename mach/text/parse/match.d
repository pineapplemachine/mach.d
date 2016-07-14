module mach.text.parse.match;

private:

//

public:



auto matchflat(string text, char delim, char escape = '\\'){
    if(text.length && text[0] == delim){
        bool escaped = false;
        for(size_t index = 1; index < text.length; index++){
            if(!escaped){
                escaped = text[index] == escape;
                if(text[index] == delim) return text[1 .. index];
            }else{
                escaped = false;
            }
        }
    }
    return null;
}

auto matchnested(string text, char open, char close, char escape = '\\'){
    if(text.length && text[0] == open){
        bool escaped = false;
        size_t nest = 1;
        for(size_t index = 0; index < text.length; index++){
            if(!escaped){
                nest += text[index] == open;
                nest -= text[index] == close;
                escaped = text[index] == escape;
            }else{
                escaped = false;
            }
            if(nest == 1) return text[1 .. index];
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
        tests("Flat", {
            testeq("{}".matchnested('{', '}'), "");
            testeq("{test}".matchnested('{', '}'), "test");
            testeq("{test}}".matchnested('{', '}'), "test");
            testeq("{{test}}".matchnested('{', '}'), "{test}");
            testeq("{\\{test}}".matchnested('{', '}'), "\\{test");
            testeq("{\\{test\\}}".matchnested('{', '}'), "\\{test\\}");
        });
        tests("Nested", {
            testeq("``".matchflat('`'), "");
            testeq("`test`".matchflat('`'), "test");
            testeq("`test``".matchflat('`'), "test");
            testeq("`\\`test``".matchflat('`'), "\\`test");
            testeq("`\\`test\\``".matchflat('`'), "\\`test\\`");
        });
    });
}
