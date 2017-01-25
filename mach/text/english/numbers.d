module mach.text.english.numbers;

private:

import mach.traits : isIntegral;
import mach.math.abs : uabs;

/++ Docs

The `englishnumber` can be used to get a verbose English representation of any
integer.
It optionally accepts a `EnglishNumberSettings` object as a template argument
to change its behavior.

+/

unittest{ /// Example
    assert(englishnumber(0) == "zero");
    assert(englishnumber(1) == "one");
    assert(englishnumber(-1) == "negative one");
    assert(englishnumber(100) == "one hundred");
    assert(englishnumber(1000) == "one thousand");
    assert(englishnumber(1000000000) == "one billion");
}

unittest{ /// Example
    enum settings = EnglishNumberSettings.Ordinal;
    assert(englishnumber!settings(1) == "first");
    assert(englishnumber!settings(2) == "second");
    assert(englishnumber!settings(3) == "third");
    assert(englishnumber!settings(999) == "nine hundred ninety-ninth");
}

public:



struct EnglishNumberSettings{
    static enum EnglishNumberSettings Default = EnglishNumberSettings();
    static enum EnglishNumberSettings Ordinal = {
        wordform: WordForm.Ordinal
    };
    
    static enum WordForm{
        Number, /// e.g. "one"
        Ordinal, // e.g. "first"
    }
    
    /// What form to output words in, e.g. "one" vs. "first".
    WordForm wordform = WordForm.Number;
    /// Whether to hyphenate numbers like "twenty-five".
    bool hyphenatetens = true;
    
    /// Get a settings object the same as this one, except with
    /// `WordForm.Number` set for the `wordform` attribute.
    @property typeof(this) numberform() const{
        return typeof(this)(WordForm.Number, this.hyphenatetens);
    }
}



/// Get a verbose english representation of an integer.
string englishnumber(
    EnglishNumberSettings settings = EnglishNumberSettings.Default, T
)(in T value) if(isIntegral!T){
    auto absvalue = uabs(value);
    immutable str = unsignedengnum!settings(absvalue);
    return value >= 0 ? str : "negative " ~ str;
}

/// Helper function used by `englishnumber`.
private string unsignedengnum(
    EnglishNumberSettings settings = EnglishNumberSettings.Default, T
)(in T value) if(isIntegral!T){
    static const ones = [
        "zero", "one", "two", "three", "four", "five",
        "six", "seven", "eight", "nine",
        "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
        "sixteen", "seventeen", "eighteen", "nineteen"
    ];
    static const ordinalones = [
        "zeroth", "first", "second", "third", "fourth", "fifth",
        "sixth", "seventh", "eighth", "ninth",
        "tenth", "eleventh", "twelfth", "thirteenth", "fourteenth", "fifteenth",
        "sixteenth", "seventeenth", "eighteenth", "nineteenth"
    ];
    static const tens = [
        "twenty", "thirty", "forty", "fifty",
        "sixty", "seventy", "eighty", "ninety"
    ];
    // https://en.wikipedia.org/wiki/Names_of_large_numbers
    static const large = [
        "thousand", "million", "billion", "trillion", "quadrillion",
        "quintillion", "sextillion", "septillion", "octillion",
        "nonillion", "decillion", "undecillion", "duodecillion",
        "tredecillion", "quattuordecillion", "quindecillion",
        "sexdecillion", "septendecillion", "octodecillion",
        "novemdecillion", "vigintillion"
    ];
    if(value < ones.length){ // Handle values <= 19
        static if(settings.wordform is settings.WordForm.Number){
            return ones[cast(size_t) value];
        }else{
            return ordinalones[cast(size_t) value];
        }
    }else if(value < 100){
        immutable ten = tens[cast(size_t)(value / 10 - 2)];
        if(value % 10 == 0){ // e.g. twenty, thirty, forty
            static if(settings.wordform is settings.WordForm.Number){
                return ten;
            }else{
                return ten[0 .. $-1] ~ "ieth";
            }
        }else{ // e.g. twenty-one, twenty-two, twenty-three
            enum hyphen = settings.hyphenatetens ? "-" : " ";
            static if(settings.wordform is settings.WordForm.Number){
                return ten ~ hyphen ~ ones[cast(size_t)(value % 10)];
            }else{
                return ten ~ hyphen ~ ordinalones[cast(size_t)(value % 10)];
            }
        }
    }else if(value < 1000){
        immutable hundred = ones[cast(size_t)(value / 100)] ~ " hundred";
        if(value % 100 == 0){ // e.g. one hundred, two hundred
            static if(settings.wordform is settings.WordForm.Number){
                return hundred;
            }else{
                return hundred ~ "th";
            }
        }else{ // e.g. one hundred twenty, one hundred thirty
            return hundred ~ " " ~ unsignedengnum!settings(value % 100);
        }
    }else{ // Value is at least one thousand
        // Determine the values of thousands, millions, billions, etc. places
        uint[] thousands;
        int firstnonzero = -1;
        T x = value;
        uint y = 0;
        while(x != 0){
            immutable place = x % 1000;
            if(place != 0 && firstnonzero < 0) firstnonzero = y;
            thousands ~= place;
            x /= 1000;
            y++;
        }
        assert(firstnonzero >= 0); // Shouldn't fail (value would have to be 0)
        // Build a sequence of terms from those places
        string str = "";
        string[] parts;
        immutable imax = cast(int) thousands.length - 1;
        for(int i = imax; i >= firstnonzero; i--){
            enum subsettings = settings.numberform;
            if(thousands[i] != 0){
                if(i == 0){ // e.g. one, ten, one hundred
                    parts ~= unsignedengnum!settings(thousands[i] % 1000);
                }else{ // e.g. one thousand, ten million, one hundred billion
                    parts ~= unsignedengnum!subsettings(thousands[i] % 1000);
                    static if(settings.wordform is settings.WordForm.Number){
                        parts ~= large[cast(size_t)(i - 1)];
                    }else{
                        // In the case of ordinals, only the final "thousand",
                        // "million", etc. should have "th" appended.
                        // All prior ones should be as normal.
                        if(i == firstnonzero){
                            parts ~= large[cast(size_t)(i - 1)] ~ "th";
                        }else{
                            parts ~= large[cast(size_t)(i - 1)];
                        }
                    }
                }
            }
        }
        assert(parts.length > 0); // Shouldn't fail (value would have to be 0)
        // Build the output string by joining the sequence of terms with spaces
        string joinedparts = parts[0];
        for(int i = 1; i < parts.length; i++){
            joinedparts ~= " " ~ parts[i];
        }
        // All done!
        return joinedparts;
    }
}



unittest{ /// Positive integers
    assert(0.englishnumber == "zero");
    assert(1.englishnumber == "one");
    assert(2.englishnumber == "two");
    assert(3.englishnumber == "three");
    assert(4.englishnumber == "four");
    assert(5.englishnumber == "five");
    assert(6.englishnumber == "six");
    assert(7.englishnumber == "seven");
    assert(8.englishnumber == "eight");
    assert(9.englishnumber == "nine");
    assert(10.englishnumber == "ten");
    assert(11.englishnumber == "eleven");
    assert(12.englishnumber == "twelve");
    assert(13.englishnumber == "thirteen");
    assert(14.englishnumber == "fourteen");
    assert(15.englishnumber == "fifteen");
    assert(16.englishnumber == "sixteen");
    assert(17.englishnumber == "seventeen");
    assert(18.englishnumber == "eighteen");
    assert(19.englishnumber == "nineteen");
    assert(20.englishnumber == "twenty");
    assert(21.englishnumber == "twenty-one");
    assert(22.englishnumber == "twenty-two");
    assert(23.englishnumber == "twenty-three");
    assert(24.englishnumber == "twenty-four");
    assert(25.englishnumber == "twenty-five");
    assert(26.englishnumber == "twenty-six");
    assert(27.englishnumber == "twenty-seven");
    assert(28.englishnumber == "twenty-eight");
    assert(29.englishnumber == "twenty-nine");
    assert(30.englishnumber == "thirty");
    assert(35.englishnumber == "thirty-five");
    assert(40.englishnumber == "forty");
    assert(45.englishnumber == "forty-five");
    assert(50.englishnumber == "fifty");
    assert(55.englishnumber == "fifty-five");
    assert(60.englishnumber == "sixty");
    assert(65.englishnumber == "sixty-five");
    assert(70.englishnumber == "seventy");
    assert(75.englishnumber == "seventy-five");
    assert(80.englishnumber == "eighty");
    assert(85.englishnumber == "eighty-five");
    assert(90.englishnumber == "ninety");
    assert(95.englishnumber == "ninety-five");
    assert(100.englishnumber == "one hundred");
    assert(112.englishnumber == "one hundred twelve");
    assert(1000.englishnumber == "one thousand");
    assert(1001000.englishnumber == "one million one thousand");
    assert(1100000.englishnumber == "one million one hundred thousand");
    assert(1000000000.englishnumber == "one billion");
    assert(1000000000000L.englishnumber == "one trillion");
    assert(1000000000000000L.englishnumber == "one quadrillion");
    assert(1000000000000000000L.englishnumber == "one quintillion");
    assert(ulong.max.englishnumber == // 18,446,744,073,709,551,615
        "eighteen quintillion four hundred forty-six quadrillion " ~
        "seven hundred forty-four trillion seventy-three billion " ~
        "seven hundred nine million five hundred fifty-one thousand " ~
        "six hundred fifteen"
    );
}

unittest{ /// Positive ordinals
    enum settings = EnglishNumberSettings.Ordinal;
    assert(0.englishnumber!settings == "zeroth");
    assert(1.englishnumber!settings == "first");
    assert(2.englishnumber!settings == "second");
    assert(3.englishnumber!settings == "third");
    assert(4.englishnumber!settings == "fourth");
    assert(5.englishnumber!settings == "fifth");
    assert(6.englishnumber!settings == "sixth");
    assert(7.englishnumber!settings == "seventh");
    assert(8.englishnumber!settings == "eighth");
    assert(9.englishnumber!settings == "ninth");
    assert(10.englishnumber!settings == "tenth");
    assert(11.englishnumber!settings == "eleventh");
    assert(12.englishnumber!settings == "twelfth");
    assert(13.englishnumber!settings == "thirteenth");
    assert(14.englishnumber!settings == "fourteenth");
    assert(15.englishnumber!settings == "fifteenth");
    assert(16.englishnumber!settings == "sixteenth");
    assert(17.englishnumber!settings == "seventeenth");
    assert(18.englishnumber!settings == "eighteenth");
    assert(19.englishnumber!settings == "nineteenth");
    assert(20.englishnumber!settings == "twentieth");
    assert(21.englishnumber!settings == "twenty-first");
    assert(22.englishnumber!settings == "twenty-second");
    assert(23.englishnumber!settings == "twenty-third");
    assert(24.englishnumber!settings == "twenty-fourth");
    assert(25.englishnumber!settings == "twenty-fifth");
    assert(26.englishnumber!settings == "twenty-sixth");
    assert(27.englishnumber!settings == "twenty-seventh");
    assert(28.englishnumber!settings == "twenty-eighth");
    assert(29.englishnumber!settings == "twenty-ninth");
    assert(30.englishnumber!settings == "thirtieth");
    assert(35.englishnumber!settings == "thirty-fifth");
    assert(40.englishnumber!settings == "fortieth");
    assert(45.englishnumber!settings == "forty-fifth");
    assert(50.englishnumber!settings == "fiftieth");
    assert(55.englishnumber!settings == "fifty-fifth");
    assert(60.englishnumber!settings == "sixtieth");
    assert(65.englishnumber!settings == "sixty-fifth");
    assert(70.englishnumber!settings == "seventieth");
    assert(75.englishnumber!settings == "seventy-fifth");
    assert(80.englishnumber!settings == "eightieth");
    assert(85.englishnumber!settings == "eighty-fifth");
    assert(90.englishnumber!settings == "ninetieth");
    assert(95.englishnumber!settings == "ninety-fifth");
    assert(100.englishnumber!settings == "one hundredth");
    assert(112.englishnumber!settings == "one hundred twelfth");
    assert(1000.englishnumber!settings == "one thousandth");
    assert(1001000.englishnumber!settings == "one million one thousandth");
    assert(1100000.englishnumber!settings == "one million one hundred thousandth");
    assert(1000000000.englishnumber!settings == "one billionth");
    assert(1000000000000L.englishnumber!settings == "one trillionth");
    assert(1000000000000000L.englishnumber!settings == "one quadrillionth");
    assert(1000000000000000000L.englishnumber!settings == "one quintillionth");
    assert(ulong.max.englishnumber!settings == // 18,446,744,073,709,551,615th
        "eighteen quintillion four hundred forty-six quadrillion " ~
        "seven hundred forty-four trillion seventy-three billion " ~
        "seven hundred nine million five hundred fifty-one thousand " ~
        "six hundred fifteenth"
    );
}

unittest{ /// Negative integers
    assert((-1).englishnumber == "negative one");
    assert((-2).englishnumber == "negative two");
    assert((-10).englishnumber == "negative ten");
    assert((-100).englishnumber == "negative one hundred");
    assert((-100000).englishnumber == "negative one hundred thousand");
}

unittest{ /// Negative ordinals
    // Note: technically the English language does not acknowledge that these
    // terms are valid but, fuck it, I do what I want.
    // http://english.stackexchange.com/questions/309713/ordinal-form-of-negative-numbers-especially-1-2-3
    enum settings = EnglishNumberSettings.Ordinal;
    assert((-1).englishnumber!settings == "negative first");
    assert((-2).englishnumber!settings == "negative second");
    assert((-10).englishnumber!settings == "negative tenth");
    assert((-100).englishnumber!settings == "negative one hundredth");
    assert((-100000).englishnumber!settings == "negative one hundred thousandth");
}
