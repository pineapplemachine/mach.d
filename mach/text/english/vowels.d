module mach.text.english.vowels;

private:

import std.algorithm : canFind;

public:

static immutable char[] Vowels = [
    'a', 'e', 'i', 'o', 'u', 'y',
    'A', 'E', 'I', 'O', 'U', 'Y'
];

bool isVowel(in char ch){
    return Vowels.canFind(ch);
}

// I hate camelCase but also don't want to go totally against the standard
// library's convention. Consequently, both isvowel and isVowel are valid.
alias isvowel = isVowel;

version(unittest){
    private:
    import mach.test;
}
unittest{
    tests("Vowels", {
        test('a'.isVowel);
        test('A'.isVowel);
        test('e'.isVowel);
        test('i'.isVowel);
        test('o'.isVowel);
        test('u'.isVowel);
        test('y'.isVowel); // Sometimes
        testf('b'.isVowel);
        testf('B'.isVowel);
        testf('c'.isVowel);
        testf('d'.isVowel);
        testf('z'.isVowel);
    });
}
