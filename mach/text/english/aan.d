module mach.text.english.aan;

private:

import mach.range : contains, all, headis;
import mach.text.ascii : isvowel, isupper, tolower; // TODO: Unicode instead of ASCII

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
        }else if(!allcaps && word.all!isupper()){
            static enum string UseAn = "AEFHILMNORSX";
            an = UseAn.contains(word[0]);
        }else if(word[0].isvowel){
            an = !word.tolower.headis("eu");
        }else if(word[0] == 'h' || word[0] == 'H'){
            an = word[1].isvowel;
        }
        return an ? "an" : "a";
    }
}



version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("A and an", {
        testeq("test".aan, "a");
        testeq("boat".aan, "a");
        testeq("egg".aan, "an");
        testeq("apple".aan, "an");
        testeq("history".aan, "an");
    });
}
