module mach.math.collatz;

private:

import std.traits : isIntegral;

public:



/// Determine whether a given type is valid for Collatz sequence calculation.
alias canCollatz = isIntegral;



/// Get a range which enumerates the Collatz sequence of a given number.
auto collatzseq(N)(N value) if(canCollatz!N){
    return CollatzRange!N(value);
}



/// Enumerates the Collatz sequence of an input number.
struct CollatzRange(N) if(canCollatz!N){
    N front;
    bool empty;
    
    this(N front, bool empty = false) in{
        assert(front >= 1, "Operation is only meaningful for positive integers.");
    }body{
        this.front = front;
        this.empty = empty;
    }
    
    void popFront(){
        if(this.front == 1){
            this.empty = true;
        }else if(this.front % 2 == 0){
            this.front /= 2;
        }else{
            this.front *= 3;
            this.front++;
        }
    }
    
    @property typeof(this) save(){
        return typeof(this)(this.front, this.empty);
    }
}



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("Collatz sequence", {
        test(collatzseq(1).equals([1]));
        test(collatzseq(2).equals([2, 1]));
        test(collatzseq(3).equals([3, 10, 5, 16, 8, 4, 2, 1]));
        fail({collatzseq(0);});
        fail({collatzseq(-1);});
    });
}
