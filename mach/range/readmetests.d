/// These are the examples used in the readme.md, expressed as unit tests to
/// help ensure that they are always accurate.
module mach.range.readmetests;

version(unittest){
    private:
    import mach.range;
    import std.ascii;
}
unittest{
    
    string hello_there = ["hello", "there"].join(" ").asarray;

    assert("hello".asrange.front == 'h');

    assert(["D", " ", "Man"].chain.asarray == "D Man");
    assert(chain("D", " ", "Man").asarray == "D Man");
    assert(["D", " ", "Man"].chainiter.asarray == "D Man");
    assert(chainranges("D", " ", "Man").asarray == "D Man");

    auto chunks = "abc123xyz!!".chunk(3);
    assert(chunks[0] == "abc");
    assert(chunks[$-1] == "!!");

    assert("hello".contains('h'));
    assert(!"hello".contains!isUpper);

    assert("hello world".distinct.asarray == "helo wrd");
    assert([1, 3, 2, 4].distinct!(n => n % 2).asarray == [1, 2]);

    string hello_each = "";
    "hello".each!(e => hello_each ~= e);
    assert(hello_each == "hello");

    assert("hello".head(3).asarray == "hel");
    assert("hello".tail(3).asarray == "llo");

    foreach(index, character; "hello".enumerate){
        assert("hello"[index] == character);
    }

    assert("h e l l o!".filter!isAlpha.asarray == "hello");

    assert("hi".find('i').index == 1);
    assert(!"hi".find('o').exists);
    assert("aha!".findfirst('a').index == 0);
    assert("aha!".findlast('a').index == 2);
    assert("aha!".findall('a').front.index == 0);
    assert("aha!".findall('a').back.index == 2);

    assert("hello".find("el").index == 1);
    assert(!"hello".find("no").exists);
    assert("abcabc".findfirst("abc").index == 0);
    assert("abcabc".findlast("abc").index == 3);
    assert("abcabc".findall("abc").front.index == 0);

    assert(["a", "b", "c"].join(',').asarray == "a,b,c");
    assert(["x", "y", "z"].join(", ").asarray == "x, y, z");

    assert([0, 1, 2].map!(e => e + 1).asarray == [1, 2, 3]);
    assert(map!((a, b) => (a + b))([0, 1, 2], [1, 4, 7]).asarray == [1, 5, 9]);

    auto ints = [0, 1, 2];
    ints.mutate!(e => e + 1).consume;
    assert(ints == [1, 2, 3]);

    auto bigrams = "hey".ngrams!2.asarray;
    assert(bigrams.length == 2);
    assert(bigrams[0] == "he");
    assert(bigrams[1] == "ey");

    assert("12".padfront('0', 4).asarray == "0012");
    assert("12".padback('0', 4).asarray == "1200");

    assert([0, 1, 2, 3].reduce!((a, b) => (a + b)) == 6);
    assert([0, 1, 2, 3].reduceeager!((a, b) => (a + b)) == 6);
    assert([0, 1, 2, 3].reducelazy!((a, b) => (a + b)).asarray == [0, 1, 3, 6]);

    assert([2, 3, 4].sum == 9);
    assert([2, 3, 4].product == 24);

    assert("hello".retro.asarray == "olleh");

    auto splitted = "how are you".split(" ").asarray;
    assert(splitted.length == 3);
    assert(splitted[0] == "how");
    assert(splitted[$-1] == "you");

    assert("__hello__".stripfront('_').asarray == "hello__");
    assert("__hello__".stripback('_').asarray == "__hello");
    assert("__hello__".stripboth('_').asarray == "hello");
    assert("  hello  ".stripboth!isWhite.asarray == "hello");

    auto tapcount = 0;
    auto range = "hello".tap!(e => tapcount++);
    assert(tapcount == 0);
    range.consume();
    assert(tapcount == 5);

}
