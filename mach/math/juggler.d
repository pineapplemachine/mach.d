module mach.math.juggler;

private:

import std.traits : isIntegral, isFloatingPoint;
import std.math : pow;

public:



// Reference: https://en.wikipedia.org/wiki/Juggler_sequence



/// Determine whether the types are valid for juggler sequence calculation.
enum canJuggler(N, F = real) = isIntegral!N && isFloatingPoint!F;



/// Get a range which enumerates the juggler sequence of a given number.
auto jugglerseq(N, F = real)(N value) if(canJuggler!(N, F)){
    return JugglerRange!(N, F)(value);
}



/// Enumerates the juggler sequence of an input number. N will be the type of
/// each element and F an interim floating point type used to calculate each step.
struct JugglerRange(N, F) if(canJuggler!(N, F)){
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
        }else{
            this.front = cast(N)(cast(F) this.front.pow(this.front % 2 == 0 ? 0.5 : 1.5));
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
    tests("Juggler sequence", {
        test(jugglerseq(1).equals([1]));
        test(jugglerseq(2).equals([2, 1]));
        test(jugglerseq(3).equals([3, 5, 11, 36, 6, 2, 1]));
        test(jugglerseq(4).equals([4, 2, 1]));
        test(jugglerseq(5).equals([5, 11, 36, 6, 2, 1]));
        fail({jugglerseq(0);});
        fail({jugglerseq(-1);});
    });
}
