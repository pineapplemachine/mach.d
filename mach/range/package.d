module mach.range;

public:

import mach.range.asarray : asarray;
import mach.range.asrange : asrange, asindexrange;
import mach.range.associate : associate, group, distribution;
import mach.range.cache : cache;
import mach.range.chain : chain, chainiter, chainranges;
import mach.range.chunk : chunk;
import mach.range.compare : compare, equals, iterequals, recursiveequals;
import mach.range.compareends : headis, tailis;
import mach.range.consume : consume, consumereverse;
import mach.range.contains : contains, containsiter, containselement;
import mach.range.distinct : distinct;
import mach.range.each : each, eachreverse;
import mach.range.ends : head, tail;
import mach.range.enumerate : enumerate;
import mach.range.fill : fill;
import mach.range.filter : filter;
import mach.range.find : find, findfirst, findlast, findall;
import mach.range.flatten : flatten;
import mach.range.include : include, exclude;
import mach.range.indexof : indexof, indexofiter, indexofelement;
import mach.range.interpolate : interpolate, lerp, coslerp;
import mach.range.intersperse : intersperse;
import mach.range.join : join;
import mach.range.logical : any, all, none, first, last, count, exactly, more, less, atleast, atmost;
import mach.range.map : map;
import mach.range.mutate : mutate;
import mach.range.next : next, nextfront, nextback;
import mach.range.ngrams : ngrams;
import mach.range.pad : pad, padfront, padback, padfrontcount, padbackcount;
import mach.range.pluck : pluck;
import mach.range.random : lcong, mersenne, xorshift, shuffle;
import mach.range.recur : recur;
import mach.range.reduce : reduce, reduceeager, reducelazy;
import mach.range.reduction : sum, product;
import mach.range.repeat : repeat, repeatrandomaccess, repeatsaving, repeatelement;
import mach.range.retro : retro;
import mach.range.rotate : rotate;
import mach.range.select : select, from, until;
import mach.range.skipindexes : skipindexes, skipindex;
import mach.range.split : split;
import mach.range.stride : stride;
import mach.range.strip : stripfront, stripback, stripboth;
import mach.range.tap : tap;
import mach.range.top : top, bottom;
import mach.range.walklength : walklength;
import mach.range.zip : zip;



alias lpad = padfront;
alias rpad = padback;
alias lstrip = stripfront;
alias rstrip = stripback;



version(unittest){
    private:
    import std.stdio;
    import mach.error.unit;
    import mach.traits;
}
unittest{
    tests("Combinations of functions", {
        tests("Retro, Pad, Distribution, Count", {
            auto input = "hello world";
            auto rev = input.retro;
            test(rev.equals("dlrow olleh"));
            auto padded = rev.padfrontcount('_', 2);
            test(padded.equals("__dlrow olleh"));
            auto distro = padded.distribution;
            testeq(distro['h'], 1);
            testeq(distro['l'], 3);
            testeq(distro['o'], 2);
            testeq(distro['_'], 2);
            foreach(key, value; distro) testeq(padded.count(key), value);
        });
        tests("Lerp, Tap, Sum", {
            real counter = 0;
            real summed = lerp(0, 1, 32).tap!((e){counter += e;}).sum;
            testeq(counter, 16.0);
            testeq(counter, summed);
        });
    });
}




