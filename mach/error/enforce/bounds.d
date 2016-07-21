module mach.error.enforce.bounds;

private:

import std.format : format;
import std.traits : isNumeric;
import mach.traits : canCompare, hasNumericLength, LengthType;

public:



auto enforcebounds(I = size_t, L = size_t, H = size_t)(
    I index, L low, H high, size_t line = __LINE__, string file = __FILE__
) if(isNumeric!I && isNumeric!L && isNumeric!H){
    OutOfBoundsException!(I, L, H).enforce(index, low, high, line, file);
    return index;
}

auto enforcebounds(I = size_t, In)(
    I index, In inobj, size_t line = __LINE__, string file = __FILE__
) if(isNumeric!I && hasNumericLength!In){
    return enforcebounds(index, cast(LengthType!In) 0, inobj.length, line, file);
}



auto enforcelowbound(I = size_t, L = size_t,)(
    I index, L low, size_t line = __LINE__, string file = __FILE__
) if(isNumeric!I && isNumeric!L){
    OutOfBoundsException!(I, L, L).enforcelow(index, low, line, file);
    return index;
}

auto enforcehighbound(I = size_t, H = size_t)(
    I index, H high, size_t line = __LINE__, string file = __FILE__
) if(isNumeric!I && isNumeric!H){
    OutOfBoundsException!(I, H, H).enforcehigh(index, high, line, file);
    return index;
}



private enum CanOOB(I = size_t, L = size_t, H = size_t) = (
    canCompare!(I, L, ">=") && canCompare!(I, H, "<")
);

class OutOfBoundsException(I = size_t, L = size_t, H = size_t): Exception if(
    CanOOB!(I, L, H)
){
    I index;
    L low;
    H high;
    bool haslow;
    bool hashigh;
    
    this(I index, size_t line = __LINE__, string file = __FILE__){
        this(index, 0, 0, false, false, line, file);
    }
    this(
        I index, L low, H high,
        size_t line = __LINE__, string file = __FILE__
    ){
        this(index, low, high, true, true, line, file);
    }
    this(
        I index, L low, H high, bool haslow, bool hashigh,
        size_t line = __LINE__, string file = __FILE__
    ){
        this.index = index; this.low = low; this.high = high;
        this.haslow = haslow; this.hashigh = hashigh;
        string message = void;
        if(haslow & hashigh){
            message = "Value %s is out of bounds %s..%s".format(index, low, high);
        }else if(haslow){
            message = "Value %s is out of bounds, must be at least %s".format(index, low);
        }else if(hashigh){
            message = "Value %s is out of bounds, must be no greater than %s".format(index, high);
        }else{
            message = "Value %s is out of bounds.".format(index);
        }
        super(message, file, line, null);
    }
    
    static void enforce(
        I index, L low, H high,
        size_t line = __LINE__, string file = __FILE__
    ){
        if((index < low) | (index >= high)){
            throw new OutOfBoundsException(index, low, high, line, file);
        }
    }
    static void enforcelow(
        I index, L low,
        size_t line = __LINE__, string file = __FILE__
    ){
        if(index < low){
            throw new OutOfBoundsException(index, low, H.init, true, false, line, file);
        }
    }
    static void enforcehigh(
        I index, H high,
        size_t line = __LINE__, string file = __FILE__
    ){
        if(index >= high){
            throw new OutOfBoundsException(index, L.init, high, false, true, line, file);
        }
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("Index Bounds", {
        tests("Low", {
            testeq(enforcelowbound(0, 0), 0);
            testeq(enforcelowbound(0, -1), 0);
            testeq(enforcelowbound(100, 0), 100);
            fail({enforcelowbound(0, 1);});
        });
        tests("High", {
            testeq(enforcehighbound(0, 1), 0);
            testeq(enforcehighbound(-1, 1), -1);
            testeq(enforcehighbound(0, 100), 0);
            fail({enforcehighbound(1, 0);});
        });
        tests("Low And High", {
            testeq(enforcebounds(0, 0, 10), 0);
            testeq(enforcebounds(0, -10, 10), 0);
            fail({enforcebounds(-1, 0, 10);});
            fail({enforcebounds(11, -10, 10);});
            fail({enforcebounds(0, 1, 10);});
        });
    });
}
