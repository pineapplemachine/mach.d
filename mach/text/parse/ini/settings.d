module mach.text.parse.ini.settings;

private:

import mach.text.escape : Escaper;

public:



struct IniSettings{
    static enum DuplicateNameBehavior{Abort, Ignore, Overwrite, List}
    static enum InvalidSyntaxBehavior{Abort, Ignore}
    
    /// What character sequence to use for name/value delimiting?
    /// Most common are '=' or ':'.
    string assignment_sequence = "=";
    /// What character sequence denotes the beginning of a comment?
    /// Most common are ';' or '#'.
    string comment_sequence = ";";
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
    string quote_characters = "\"'";
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
    
    @property auto assignment() const{
        return this.assignment_sequence;
    }
    @property void assignment(string value){
        this.escaper = null;
        this.assignment_sequence = value;
    }
    @property void assignment(char value){
        this.escaper = null;
        this.assignment_sequence = [value];
    }
    @property auto comment() const{
        return this.comment_sequence;
    }
    @property void comment(string value){
        this.escaper = null;
        this.comment_sequence = value;
    }
    @property void comment(char value){
        this.escaper = null;
        this.comment_sequence = [value];
    }
    @property auto quotes() const{
        return this.quote_characters;
    }
    @property void quotes(string value){
        this.escaper = null;
        this.quote_characters = value;
    }
    @property void quotes(char value){
        this.escaper = null;
        this.quote_characters = [value];
    }
    
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
        this.comment.each!((char ch) => (escapes ~= [ch, ch]));
        return new Escaper(escapes);
    }
    void setdefaultescaper(){
        this.escaper = this.defaultescaper;
    }
    auto escape(in string text){
        if(this.escaper is null) this.setdefaultescaper();
        return this.escaper.escape(text);
    }
    auto unescape(in string text){
        if(this.escaper is null) this.setdefaultescaper();
        return this.escaper.unescape(text);
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Ini parse settings", {
        tests("Escape sequences", {
            IniSettings settings;
            settings.assignment = '=';
            settings.comment = "//";
            settings.quotes = '\'';
            testeq(
                settings.escape(`=funky= "test" /string/`),
                `\=funky\= "test" \/string\/`
            );
            testeq(
                settings.unescape(`\=funky\= "test" \/string\/`),
                `=funky= "test" /string/`
            );
        });
    });
}
