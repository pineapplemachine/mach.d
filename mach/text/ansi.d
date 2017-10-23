module mach.text.ansi;

private:

import mach.text.ascii : isdigit, isupper;

/++ Docs

This module implements a tool for parsing ANSI escape sequences.

+/

public:

/// Enumeration of standard ANSI escape sequences
/// http://wiki.bash-hackers.org/scripting/terminalcodes
enum EscapeSequence: string{
    Up = "[A",
    Down = "[B",
    Right = "[C",
    Left = "[D",
    End = "[F",
    Pos1 = "[H",
    Ins = "[2~",
    Del = "[3~",
    PgUp = "[5~",
    PdDown = "[6~",
    F1 = "OP",
    F2 = "OQ",
    F3 = "OR",
    F4 = "OS",
    F5 = "[15~",
    F6 = "[17~",
    F7 = "[18~",
    F8 = "[19~",
    F9 = "[20~",
    F10 = "[21~",
    F11 = "[23~",
    F12 = "[24~",
    Apps = "[29~",
    Win = "[34~",
    S_Up = "[1;2A",
    S_Down = "[1;2B",
    S_Right = "[1;2C",
    S_Left = "[1;2D",
    S_End = "[1;2F",
    S_Pos1 = "[1;2H",
    S_Ins = "[2;2~",
    S_Del = "[3;2~",
    S_PgUp = "[5;2~",
    S_PdDown = "[6;2~",
    S_F1 = "[1;2P",
    S_F2 = "[1;2Q",
    S_F3 = "[1;2R",
    S_F4 = "[1;2S",
    S_F5 = "[15;2~",
    S_F6 = "[17;2~",
    S_F7 = "[18;2~",
    S_F8 = "[19;2~",
    S_F9 = "[20;2~",
    S_F10 = "[21;2~",
    S_F11 = "[23;2~",
    S_F12 = "[24;2~",
    S_Apps = "[29;2~",
    S_Win = "[34;2~",
    M_Up = "[1;3A",
    M_Down = "[1;3B",
    M_Right = "[1;3C",
    M_Left = "[1;3D",
    M_End = "[1;3F",
    M_Pos1 = "[1;3H",
    M_Ins = "[2;3~",
    M_Del = "[3;3~",
    M_PgUp = "[5;3~",
    M_PdDown = "[6;3~",
    M_F1 = "[1;3P",
    M_F2 = "[1;3Q",
    M_F3 = "[1;3R",
    M_F4 = "[1;3S",
    M_F5 = "[15;3~",
    M_F6 = "[17;3~",
    M_F7 = "[18;3~",
    M_F8 = "[19;3~",
    M_F9 = "[20;3~",
    M_F10 = "[21;3~",
    M_F11 = "[23;3~",
    M_F12 = "[24;3~",
    M_Apps = "[29;3~",
    M_Win = "[34;3~",
    C_Up = "[1;5A",
    C_Down = "[1;5B",
    C_Right = "[1;5C",
    C_Left = "[1;5D",
    C_End = "[1;5F",
    C_Pos1 = "[1;5H",
    C_Ins = "[2;5~",
    C_Del = "[3;5~",
    C_PgUp = "[5;5~",
    C_PdDown = "[6;5~",
    C_F1 = "[1;5P",
    C_F2 = "[1;5Q",
    C_F3 = "[1;5R",
    C_F4 = "[1;5S",
    C_F5 = "[15;5~",
    C_F6 = "[17;5~",
    C_F7 = "[18;5~",
    C_F8 = "[19;5~",
    C_F9 = "[20;5~",
    C_F10 = "[21;5~",
    C_F11 = "[23;5~",
    C_F12 = "[24;5~",
    C_Apps = "[29;5~",
    C_Win = "[34;5~",
    S_C_Up = "[1;6A",
    S_C_Down = "[1;6B",
    S_C_Right = "[1;6C",
    S_C_Left = "[1;6D",
    S_C_End = "[1;6F",
    S_C_Pos1 = "[1;6H",
    S_C_Ins = "[2;6~",
    S_C_Del = "[3;6~",
    S_C_PgUp = "[5;6~",
    S_C_PdDown = "[6;6~",
    S_C_F1 = "[1;6P",
    S_C_F2 = "[1;6Q",
    S_C_F3 = "[1;6R",
    S_C_F4 = "[1;6S",
    S_C_F5 = "[15;6~",
    S_C_F6 = "[17;6~",
    S_C_F7 = "[18;6~",
    S_C_F8 = "[19;6~",
    S_C_F9 = "[20;6~",
    S_C_F10 = "[21;6~",
    S_C_F11 = "[23;6~",
    S_C_F12 = "[24;6~",
    S_C_Apps = "[29;6~",
    S_C_Win = "[34;6~",
    C_M_Up = "[1;7A",
    C_M_Down = "[1;7B",
    C_M_Right = "[1;7C",
    C_M_Left = "[1;7D",
    C_M_End = "[1;7F",
    C_M_Pos1 = "[1;7H",
    C_M_Ins = "[2;7~",
    C_M_Del = "[3;7~",
    C_M_PgUp = "[5;7~",
    C_M_PdDown = "[6;7~",
    C_M_F1 = "[1;7P",
    C_M_F2 = "[1;7Q",
    C_M_F3 = "[1;7R",
    C_M_F4 = "[1;7S",
    C_M_F5 = "[15;7~",
    C_M_F6 = "[17;7~",
    C_M_F7 = "[18;7~",
    C_M_F8 = "[19;7~",
    C_M_F9 = "[20;7~",
    C_M_F10 = "[21;7~",
    C_M_F11 = "[23;7~",
    C_M_F12 = "[24;7~",
    C_M_Apps = "[29;7~",
    C_M_Win = "[34;7~",
}

/// Parser for detecting and finding the end of escape sequences
struct EscapeSequenceParser{
    enum EscapeCharacter = char(0x1B);
    
    /// Enumeration of possible parser states
    enum State{
        /// Searching for the beginning of the next escape sequence
        Searching,
        /// Found an ANSI escape character 0x1B
        Escape,
        /// Found an open bracket '[' following the escape character
        Bracket,
        /// Found a letter 'O' following the escape character
        OFunction,
        /// Found a digit '0'-'9' following the escape character
        FirstNumberFirstDigit,
        /// Found a second digit '0'-'9' after the first one
        FirstNumberSecondDigit,
        /// Found a semicolon ';' at the end of the first number
        TailNumberInitial,
        /// Process the second character in the tail number(-ish string)
        TailNumberFirstDigit,
        /// Just completed a well-formed escape sequence
        Completed,
        /// Just encountered a malformed escape sequence
        Failed,
    }
    
    /// The parser's current state
    State state = State.Searching;
    
    /// Returns the escape sequence the input string began with if it did begin
    /// with an escape sequence. Returns null when the input string did not
    /// begin with an escape sequence.
    static getSequence(in string input){
        EscapeSequenceParser parser;
        for(size_t i = 0; i < input.length; i++){
            parser.feed(input[i]);
            if(parser.state is State.Completed){
                return input[1 .. i + 1];
            }
        }
        return null;
    }
    
    /// Push the next character to the parser.
    void feed(in char next){
        return this.feed(cast(int) next);
    }
    /// Push the next character to the parser, e.g. from a call to getchar.
    void feed(in int next){
        if(next < 0){
            if(this.state !is State.Searching){
                this.state = State.Failed;
            }
            return;
        }
        final switch(this.state){
            case State.Completed:
                goto case;
            case State.Failed:
                this.state = State.Searching;
                goto case;
            case State.Searching:
                if(next == this.EscapeCharacter){
                    this.state = State.Escape;
                }
                break;
            case State.Escape:
                if(next == '['){
                    this.state = State.Bracket;
                }else if(next == 'O'){
                    this.state = State.OFunction;
                }
                break;
            case State.OFunction:
                if(next >= 'P' && next <= 'S'){
                    this.state = State.Completed;
                }else{
                    this.state = State.Failed;
                }
                break;
            case State.Bracket:
                if(isdigit(cast(char) next)){
                    this.state = State.FirstNumberFirstDigit;
                }else if((next >= 'A' && next <= 'D') || next == 'F' || next == 'H'){
                    this.state = State.Completed;
                }else{
                    this.state = State.Failed;
                }
                break;
            case State.FirstNumberFirstDigit:
                if(next == '~'){
                    this.state = State.Completed;
                }else if(next == ';'){
                    this.state = State.TailNumberInitial;
                }else if(isdigit(cast(char) next)){
                    this.state = State.FirstNumberSecondDigit;
                }else{
                    this.state = State.Failed;
                }
                break;
            case State.FirstNumberSecondDigit:
                if(next == '~'){
                    this.state = State.Completed;
                }else if(next == ';'){
                    this.state = State.TailNumberInitial;
                }else{
                    this.state = State.Completed;
                }
                break;
            case State.TailNumberInitial:
                if(isdigit(cast(char) next)){
                    this.state = State.TailNumberFirstDigit;
                }else{
                    this.state = State.Failed;
                }
                break;
            case State.TailNumberFirstDigit:
                if(next == '~' || isdigit(cast(char) next) || isupper(cast(char) next)){
                    this.state = State.Completed;
                }else{
                    this.state = State.Failed;
                }
        }
    }
    
    /// True when the parser has begun parsing an escape sequence and has not
    /// yet finished.
    bool parsing() const{
        return !this.done() && this.state !is State.Searching;
    }
    /// True when the parser has just found the end of a valid or invalid escape
    /// sequence.
    bool completed() const{
        return this.state is State.Completed;
    }
    /// True when the parser found an unexpected character in an escape sequence
    /// or an unexpected EOF.
    bool failed() const{
        return this.state is State.Failed;
    }
    /// True when the parser has just found the final character in an escape
    /// sequence.
    bool done() const{
        return this.completed() || this.failed();
    }
}

unittest{ // Test all known sequences
    foreach(sequenceName; __traits(allMembers, EscapeSequence)){
        mixin(`string sequence = EscapeSequence.` ~ sequenceName ~ `;`);
        const parsed = EscapeSequenceParser.getSequence(
            EscapeSequenceParser.EscapeCharacter ~ sequence
        );
        assert(sequence == parsed);
    }
}

unittest{ // Test some invalid sequences
    const string[] InvalidSequences = [
        "\033OX",
        "\033[*",
        "\033[1",
        "\033[11",
        "\033[12;",
        "\033[12;1",
        "nope",
        "",
    ];
    foreach(nonSequence; InvalidSequences){
        assert(
            EscapeSequenceParser.getSequence(nonSequence) == null
        );
    }
}
