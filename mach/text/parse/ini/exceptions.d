module mach.text.parse.ini.exceptions;

private:

import std.format : format;

public:



static class IniException: Exception{
    this(
        string message, Throwable next = null,
        size_t line = __LINE__, string file = __FILE__
    ){
        super(message, file, line, next);
    }
}

static class IniParseException: IniException{
    size_t iniline;
    string inipath;
    this(
        string message, size_t iniline, string inipath = null,
        Throwable next = null,
        size_t line = __LINE__, string file = __FILE__
    ){
        string msg;
        if(iniline > 0 && inipath !is null){
            msg = "%s (line %d in file \"%s\")".format(message, iniline, inipath);
        }else if(iniline > 0){
            msg = "%s (line %d)".format(message, iniline);
        }else if(inipath !is null){
            msg = "%s (in file \"%s\")".format(message, inipath);
        }else{
            msg = message;
        }
        this.iniline = iniline;
        this.inipath = inipath;
        super(msg, next, line, file);
    }
}
