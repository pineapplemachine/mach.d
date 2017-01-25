module mach.text.english;

private:

/++ Docs

This package provides functions for performing common operations with
English words.

+/

unittest{ /// Example
    // Get the name of a number in English
    assert(100.englishnumber == "one hundred");
    // Get the plural form of a singular English word
    assert("hello".plural == "hellos");
    // Get whether a noun would be preceded by "a" or "an"
    assert("world".aan == "a");
    assert("island".aan == "an");
}

public:

import mach.text.english.aan;
import mach.text.english.numbers;
import mach.text.english.plural;
import mach.text.english.vowels;
