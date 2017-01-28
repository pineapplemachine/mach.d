module mach.range.random.testrandom;

private:

import mach.test;
import mach.meta : Aliases;
import mach.range.random.lcong : lcong;
import mach.range.random.mersenne : mersenne;
import mach.range.random.xorshift : xorshift;
import mach.math : abs, mean;
import mach.range : top, bottom, mergesort;
import mach.io : stdio;

/++ Docs

This module contains tests for the PRNGs implemented in `mach.range.random`.

+/

public:



void main(){
    foreach(RNG; Aliases!(lcong, mersenne, xorshift)){
        stdio.writeln("Testing PRNG implementation: ", RNG.stringof);
        auto rng = RNG();
        booleantest(rng);
        integertest(rng);
        floattest(rng);
    }
}



/// Test accuracy of P when calling `rng.random!bool(P)`
auto booleantest(T)(auto ref T rng){
    stdio.writeln(" Testing boolean distribution.");
    foreach(prob; [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]){
        immutable total = 1_000_000;
        ulong t = 0;
        ulong f = 0;
        foreach(i; 0 .. total){
            if(rng.random!bool(prob)){
                t++;
            }else{
                f++;
            }
        }
        immutable actual = t / cast(double) total;
        immutable error = abs(actual - prob);
        stdio.writeln(
            "  Expected: ", prob, " Actual: ", actual, " Error: ", error
        );
    }
}

/// Test accuracy for groups of integers.
auto integertest(T)(auto ref T rng){
    stdio.writeln(" Testing integer distribution.");
    foreach(bucketcount; [5, 9, 10, 12, 20, 70, 3000]){
        immutable total = bucketcount * 10_000;
        auto buckets = new ulong[bucketcount];
        foreach(i; 0 .. total){
            buckets[rng.random!int(0, bucketcount - 1)]++;
        }
        auto proportions = new double[bucketcount];
        foreach(i; 0 .. bucketcount){
            proportions[i] = buckets[i] / cast(double) total;
        }
        immutable expected = double(1) / bucketcount;
        immutable min = proportions.top;
        immutable max = proportions.bottom;
        stdio.writeln(
            "  Expected: ", expected, " Lowest: ", min, " Highest: ", max, " Delta: ", abs(max - min)
        );
    }
}

/// Test distribution of floating point values.
auto floattest(T)(auto ref T rng){
    stdio.writeln(" Testing float distribution.");
    auto values = new double[2 << 16];
    foreach(i; 0 .. values.length){
        values[i] = rng.random!double;
    }
    mergesort(values);
    assert(values[0] >= 0);
    assert(values[$-1] < 1);
    auto deltas = new double[values.length - 1];
    foreach(i; 0 .. deltas.length){
        deltas[i] = values[i + 1] - values[i];
    }
    immutable mindelta = deltas.top;
    immutable maxdelta = deltas.bottom;
    immutable meandelta = mean(deltas);
    immutable expected = double(1) / values.length;
    stdio.writeln(
        "  Expected: ", expected, " Mean: ", meandelta, " Lowest: ", mindelta, " Highest: ", maxdelta
    );
}
