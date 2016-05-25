module mach.text.english.plural;

private:

import std.conv : to;
import std.algorithm : canFind;
import std.string : join, endsWith, toLower, toUpper;
import mach.text.english.vowels : isVowel;
import mach.text.cases : isUpper;

public:

/// Pluralize a single English word using the default Pluralizer.
/// Not perfect, but can be expected to work in the vast majority of cases.
string plural(bool allcaps = false)(in string word){
    return Pluralizer.getdefault().plural!(allcaps)(word);
}

class Pluralizer{
    
    static Pluralizer Default = null;
    
    static Pluralizer getdefault(){
        if(Pluralizer.Default is null) Pluralizer.Default = new Pluralizer();
        return Pluralizer.Default;
    }
    
    string[string] PluralUniqueExceptions;
    string[] PluralSameAsSingular;
    string[] PluralOSuffixExceptions;
    string[] PluralFSuffixExceptions;

    this(){
        // Not even close to exhaustive lists, just sensible defaults.
        this.PluralUniqueExceptions = [
            "man": "men", "woman": "women", "child": "children", "brother": "brethren",
            "ox": "oxen", "foot": "feet", "goose": "geese", "louse": "lice",
            "mouse": "mice", "tooth": "teeth", "money": "monies", "person": "people",
            "axis": "axes", "genesis": "geneses", "nemesis": "nemeses",
            "crisis": "crises", "testis": "testes", "addendum": "addenda",
            "corrigendum": "corrigenda", "datum": "data", "memoranda": "memorandum",
            "millennium": "millennia", "ovum": "ova", "spectrum": "spectra",
            "alumnus": "alumni", "corpus": "corpora", "focus": "foci", "genus": "genera",
            "radius": "radii", "succubus": "succubi", "viscus": "viscera",
            "cactus": "cacti", "fungus": "fungi", "terminus": "termini",
            "criterion": "criteria", "phenomenon": "phenomena", "polyhedron": "polyhedra",
            "benshi": "benshi", "otaku": "otaku", "samurai": "samurai"
        ];
        this.PluralSameAsSingular = [
            "bison", "buffalo", "deer", "duck", "fish", "moose", "salmon",
            "sheep", "squid", "swine", "trout", "aircraft", "watercraft", "spacecraft",
            "hovercraft", "blues", "series", "species", "swiss", "cherokee", "cree",
            "comanche", "delaware", "hopi", "iroquois", "kiowa", "navajo", "ojibwa",
            "sioux", "zuni", "dice", "data"
        ];
        this.PluralOSuffixExceptions = [
            "canto", "hetero", "homo", "photo", "zero", "piano", "portico",
            "pro", "quarto", "kimono", "hello"
        ];
        this.PluralFSuffixExceptions = [
            "roof", "staff", "turf"
        ];
    }
    
    string plural(bool allcaps = false)(in string word){
        if(word is null || word.length < 1){
            return word;
            
        }else if(word.length == 1){
            // http://english.stackexchange.com/a/25280
            return word ~ (isUpper(word[0]) ? "s" : "'s");
            
        }else if(!allcaps && word.isUpper){
            // If not allcaps, assume this is an abbreviation, e.g. CIA
            return word ~ "s";
            
        }else if(word.toLower in PluralUniqueExceptions){
            string result = PluralUniqueExceptions[word.toLower];
            if(word[0].isUpper){
                if(word.isUpper){
                    return result.toUpper;
                }else{
                    return to!string(result[0].toUpper) ~ result[1 .. $];
                }
            }else{
                return result;
            }
            
        }else if(PluralSameAsSingular.canFind(word.toLower)){
            return word;
            
        }else{
            
            // Case-insensitive endsWith
            bool ends(in string word, in string suffix){
                return word.toLower.endsWith(suffix);
            }
            
            string suffix = "s"; // String to append
            size_t trimright = 0; // Number of chars to trim from right of string
            
            if(word[$-1] == 'o'){
                if(word[$-2] != 'o' && !PluralOSuffixExceptions.canFind(word.toLower)){
                    suffix = "es";
                }
            }else if(word[$-1] == 'y'){
                if(!word[$-2].isVowel || ends(word, "-by")){
                    suffix = "ies";
                    trimright = 1;
                }
            }else if(word[$-1] == 'f'){
                if(!PluralFSuffixExceptions.canFind(word.toLower)){
                    suffix = "ves";
                    trimright = 1;
                }
            }else if(ends(word, "ife")){
                suffix = "ives";
                trimright = 3;
            }else if(!allcaps && word[0].isUpper && ends(word, "ese")){
                // Assume a nationality e.g. Chinese, Japanese
                suffix = "";
            }else if(word[$-1] == 's' && word.length <= 3){
                // TODO: More reliably check for a single syllable
                suffix = "ses"; // e.g. "busses"
            }else if(
                word[$-1] == 's' || word[$-1] == 'z' || word[$-1] == 'x' ||
                ends(word, "sh") || ends(word, "ch")
            ){
                suffix = "es";
            }
            
            // Build the finished string
            return word[0 .. $-trimright] ~ (word.isUpper ? suffix.toUpper : suffix);
            
        }
    }
    
}

version(unittest) import mach.error.unit;
unittest{
    tests("Plurals", {
        testeq(plural("hello"), "hellos");
        testeq(plural("world"), "worlds");
        testeq(plural("program"), "programs");
        testeq(plural("code"), "codes");
        testeq(plural("life"), "lives");
        testeq(plural("mask"), "masks");
        testeq(plural("orange"), "oranges");
        testeq(plural("apple"), "apples");
        testeq(plural("buzz"), "buzzes");
        testeq(plural("box"), "boxes");
        testeq(plural("flake"), "flakes");
        testeq(plural("bus"), "busses");
        testeq(plural("wretch"), "wretches");
        testeq(plural("log"), "logs");
        testeq(plural("dagger"), "daggers");
        testeq(plural("dwarf"), "dwarves");
        testeq(plural("game"), "games");
        testeq(plural("gene"), "genes");
        testeq(plural("data"), "data");
        testeq(plural("woman"), "women");
        testeq(plural("photo"), "photos");
        testeq(plural("tooth"), "teeth");
        testeq(plural("roof"), "roofs");
        testeq(plural("hoof"), "hooves");
        testeq(plural("ability"), "abilities");
        testeq(plural("vertex"), "vertexes"); // Fuck grammar: "verticies" is stupid
        testeq(plural("flex"), "flexes");
        testeq(plural("Chinese"), "Chinese");
        testeq(plural("Mexican"), "Mexicans");
        testeq(plural("dwarf"), "dwarves");
        testeq(plural("CIA"), "CIAs");
        testeq(plural("A"), "As");
        testeq(plural("a"), "a's");
        testeq(plural!true("KILL"), "KILLS");
        testeq(plural!true("KNIFE"), "KNIVES");
        testeq(plural!true("RADIUS"), "RADII");
    });
}
