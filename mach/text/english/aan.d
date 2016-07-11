module mach.text.english.aan;

private:

import mach.range : contains;
import mach.text.english.vowels;
import std.string : startsWith, toLower;
import mach.text.cases;

public:



/// Given a word, prefix it with either "a" or "an", algorithmically determining
/// which article is most likely the correct one. Not perfect, but should be
/// correct for the vast majority of inputs.
auto aan(bool allcaps = false)(string word){
    if(word is null || word.length == 0){
        return word;
    }else{
        bool an = false;
        if(word.length == 1){
            an = true;
        }else if(!allcaps && word.isUpper()){
            static enum string UseAn = "AEFHILMNORSX";
            an = UseAn.contains(word[0]);
        }else if(word[0].isVowel()){
            an = !word.toLower.startsWith("eu");
        }else if(word[0] == 'h' || word[0] == 'H'){
            an = word[1].isVowel();
        }
        return (an ? "an " : "a ") ~ word;
    }
}



version(unittest){
    import mach.error.unit;
}
unittest{
    tests("A and an", {
        testeq("test".aan, "a test");
        testeq("boat".aan, "a boat");
        testeq("egg".aan, "an egg");
        testeq("apple".aan, "an apple");
        testeq("history".aan, "an history");
    });
}
