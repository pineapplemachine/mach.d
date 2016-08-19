module mach.text.parse.ini.parse;

private:

import std.conv : to;
import std.format : format;
import mach.io.file : File;
import mach.text.parse.match : matchflat;
import mach.range : map, pluck, skipindexes;
import mach.text.parse.ini.exceptions;
import mach.text.parse.ini.properties;

public:



class IniFile{
    
    
    static struct Settings{
        import mach.text.escape : Escaper;
        
        static enum DuplicateNameBehavior{Abort, Ignore, Overwrite, List}
        static enum InvalidSyntaxBehavior{Abort, Ignore}
        
        /// What character sequence to use for name/value delimiting?
        /// Most common are '=' or ':'.
        string assignment = "=";
        /// What character sequence denotes the beginning of a comment?
        /// Most common are ';' or '#'.
        string comment = ";";
        /// Determines whether a comment character not appearing at the
        /// beginning of a line may denote a comment, or if it's interpreted
        /// as part of the value.
        bool allow_end_of_line_comments = false;
        /// Whether to allow blank lines.
        bool allow_blank_lines = true;
        /// How to handle duplicate property names.
        DuplicateNameBehavior duplicate_name_behavior = DuplicateNameBehavior.List;
        /// How to handle lines that are neither comments nor valid assignments.
        InvalidSyntaxBehavior invalid_syntax_behavior = InvalidSyntaxBehavior.Abort;
        /// Which characters may denote the beginning and end of a name, if
        /// any. If the array is empty, then values may not be quoted.
        string quotes = "\"'";
        /// Whether whitespace at the beginning of a line is ignored.
        bool ignore_line_leading_whitespace = true;
        /// Whether whitespace following a name definition is ignored.
        bool ignore_name_trailing_whitespace = true;
        /// Whether whitespace prior to a value definition is ignored.
        bool ignore_value_leading_whitespace = true;
        /// Whether whitespace at the end of a line is ignored.
        bool ignore_line_trailing_whitespace = true;
        /// Whether names under no section are legal.
        bool allow_globals = true;
        /// Name of section in which to place names that have no explicitly-
        /// declared section.
        string default_section_name = "globals";
        /// Whether names of keys and sections are case-sensitive.
        bool case_sensitive_names = true;
        /// Whether properties within sections should be ordered or unordered.
        bool ordered = true;
        /// Character to begin section names
        char begin_section_name = '[';
        /// Character to end section names
        char end_section_name = ']';
        
        /// Determines which escape sequences are valid and what they map to.
        Escaper escaper = null;
        
        /// Constructs a probably correct default Escaper object based on the
        /// current settings.
        auto defaultescaper(){
            import mach.range : each;
            Escaper.Escapes escapes = [
                ['\'', '\''],
                [char(0x00), '0'],
                [char(0x07), 'a'],
                [char(0x08), 'b'],
                [char(0x0A), 'n'],
                [char(0x0D), 'r'],
                [char(0x09), 't'],
            ];
            this.assignment.each!((char ch) => (escapes ~= [ch, ch]));
            this.quotes.each!((char ch) => (escapes ~= [ch, ch]));
            if(this.allow_end_of_line_comments){
                this.comment.each!((char ch) => (escapes ~= [ch, ch]));
            }
            return new Escaper(escapes);
        }
        auto escape(in string text){
            if(this.escaper is null) this.escaper = this.defaultescaper;
            return this.escaper.escape(text);
        }
        auto unescape(in string text){
            if(this.escaper is null) this.escaper = this.defaultescaper;
            return this.escaper.unescape(text);
        }
    }
    
    
    static class Section{
        IniFile file;
        string name;
        IniProperties properties;
        
        this(IniFile file, string name){
            this(file, name, new IniProperties);
        }
        this(IniFile file, string name, IniProperties properties){
            this.file = file;
            this.name = name;
            this.properties = properties;
        }
        
        //Section sub(string name){
        //}
    }
    
    Settings settings;
    Section[] sections;
    
    static IniFile parse(
        in string data, Settings settings,
        string path = null, bool ordered = true
    ){ // TODO: also ranges
        import std.ascii : isWhite;
        import mach.range : all, split, count, asarray, stripfront, stripback; 
        import mach.range : findfirst, findall, retro, contains, headis;
        
        auto lines = data.split('\n').map!asarray;
        size_t linenumber = 1;
        
        IniFile file = new IniFile;
        file.settings = settings;
        
        Section section = null;
        if(settings.allow_globals){
            section = new Section(file, settings.default_section_name, new IniProperties);
            file.sections ~= section;
        }
        
        // Handle a line defining a section
        void parsesection(string line){
            auto nameend = line.findfirst(settings.end_section_name);
            if(nameend.exists){
                auto sectionname = line[1 .. nameend.index];
                section = new Section(file, sectionname);
                file.sections ~= section;
            }else if(settings.invalid_syntax_behavior == Settings.InvalidSyntaxBehavior.Abort){
                throw new IniParseException(
                    "Encountered malformed section declaration.", linenumber, path
                );
            }
        }
        // Handle a line defining an assignment
        void parseassignment(string line){
            if(section !is null){
                string[] parts = line.split(settings.assignment).map!asarray.asarray;
                if(parts.length == 2){
                    string key = parts[0];
                    string value = parts[1];
                    if(settings.ignore_name_trailing_whitespace){
                        key = key.stripback!isWhite.asarray;
                    }
                    if(settings.ignore_value_leading_whitespace){
                        value = value.stripfront!isWhite.asarray;
                    }
                    if(settings.quotes.contains(key[0])){
                        key = key.matchflat(key[0]);
                    }
                    if(settings.quotes.contains(value[0])){
                        value = value.matchflat(value[0]);
                    }
                    key = settings.unescape(key);
                    value = settings.unescape(value);
                    section.properties.add(key, value);
                }else if(settings.invalid_syntax_behavior == Settings.InvalidSyntaxBehavior.Abort){
                    throw new IniParseException(
                        "Encountered malformed property assignment.", linenumber, path
                    );
                }
            }else{
                throw new IniParseException(
                    "Encountered property without an encapsulating section.", linenumber, path
                );
            }
        }
        // Get a line's contents to the left of its comment, if any
        string parsecomment(string line){
            bool escaped = false;
            size_t index = 0;
            while(index < line.length - settings.comment.length){
                if(!escaped){
                    if(settings.quotes.contains(line[index])){
                        index += line.matchflat(line[index], index).length + 1;
                    }else if(line[index] == '\\'){
                        escaped = true;
                    }else if(line[index .. index + settings.comment.length] == settings.comment){
                        return line[0 .. index];
                    }
                }else{
                    escaped = false;
                }
                index++;
            }
            return line;
        }
        
        foreach(string line; lines){
            
            if(settings.ignore_line_leading_whitespace){
                line = line.stripfront!isWhite.asarray;
            }
            if(settings.ignore_line_trailing_whitespace){
                line = line.stripback!isWhite.asarray;
            }else if(line.length && line[$-1] == '\r'){ // Ew, Windows newlines
                line = line[0 .. $-1];
            }
        
            if(!settings.allow_blank_lines && line.length == 0){
                throw new IniParseException(
                    "Encountered blank line.", linenumber, path
                );
            }else if(line.length){
                if(!line.headis(settings.comment)){
                    if(settings.allow_end_of_line_comments){
                        line = parsecomment(line);
                    }
                    if(line[0] == settings.begin_section_name){
                        parsesection(line);
                    }else{
                        parseassignment(line);
                    }
                }
            }
            
            linenumber++;
        }
        
        return file;
    }
}


unittest{
}
