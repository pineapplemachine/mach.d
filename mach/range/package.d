module mach.range;

public:

import mach.range.asarray : asarray;
import mach.range.asrange : asrange;
import mach.range.associate : associate, group, distribute;
import mach.range.chain : chain;
import mach.range.chunk : chunk, divide;
import mach.range.compare : compare, equals, iterequals, recursiveequals;
import mach.range.consume : consume, consumereverse;
import mach.range.contains : contains, containsiterable, containselement;
import mach.range.distinct : distinct;
import mach.range.each : each, eachreverse;
import mach.range.ends : head, tail;
import mach.range.enumerate : enumerate;
import mach.range.fill : fill;
import mach.range.filter : filter;
import mach.range.find : find, findfirst, findlast, findall;
import mach.range.include : include, exclude;
import mach.range.indexof : indexof, indexofiterable, indexofelement;
import mach.range.interpolate : interpolate, lerp, coslerp;
import mach.range.logical : any, all, none, first, last, count, exactly, more, less, atleast, atmost;
import mach.range.map : map;
import mach.range.mutate : mutate;
import mach.range.pad : pad, padleft, padright, padleftcount, padrightcount;
import mach.range.pluck : pluck;
import mach.range.recur : recur;
import mach.range.reduce : reduce, reduceeager, reducelazy;
import mach.range.reduction : sum, product;
import mach.range.repeat : repeat, repeatrandomaccess, repeatsaving, repeatelement;
import mach.range.reversed : reversed;
import mach.range.rotate : rotate;
import mach.range.select : select, from, until;
import mach.range.stride : stride;
import mach.range.tap : tap;
import mach.range.walk : walk;
import mach.range.zip : zip;
