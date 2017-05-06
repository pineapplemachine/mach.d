module mach.json.escape;

private:

import mach.range : asarray;
import mach.text.escape : Escaper;

/++ Docs

This module defines an object that is used to handle escape sequences
in json.

+/

public:



/// Used to escape and unescape string literals.
static immutable Escaper jsonescaper = {
    xesc: false,
    u16esc: true,
    unprintable: true,
    pairs: [
        Escaper.Pair('"'),
        Escaper.Pair('/'),
        Escaper.Pair(dchar(0x08), 'b'), // Backspace
        Escaper.Pair(dchar(0x0C), 'f'), // Form feed
        Escaper.Pair(dchar(0x0A), 'n'), // Newline
        Escaper.Pair(dchar(0x0D), 'r'), // Carriage return
        Escaper.Pair(dchar(0x09), 't'), // Horizontal tab
    ]
};

/// Escape a string literal so that it can be safely represented in json.
static auto jsonescape(in string str){
    return jsonescaper.utf8escape(str).asarray;
}

/// Unescape a json string literal.
static auto jsonunescape(in string str){
    return jsonescaper.unescape(str).asarray;
}
