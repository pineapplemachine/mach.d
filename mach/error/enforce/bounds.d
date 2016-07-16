module mach.error.enforce.bounds;

private:

import std.format : format;
import mach.traits : canCompare;

public:



auto enforcebounds(T = size_t)(
    T index, T low, T high, size_t line = __LINE__, string file = __FILE__
){
    OutOfBoundsException!T.enforce(index, low, high, line, file);
    return index;
}

auto enforcelowbound(T = size_t)(
    T index, T low, size_t line = __LINE__, string file = __FILE__
){
    OutOfBoundsException!T.enforcelow(index, low, line, file);
    return index;
}

auto enforcehighbound(T = size_t)(
    T index, T high, size_t line = __LINE__, string file = __FILE__
){
    OutOfBoundsException!T.enforcehigh(index, high, line, file);
    return index;
}



class OutOfBoundsException(T = size_t): Exception if(canCompare!T){
    T index;
    T low, high;
    bool haslow, hashigh;
    
    this(T index, size_t line = __LINE__, string file = __FILE__){
        this(index, 0, 0, false, false, line, file);
    }
    this(
        T index, T low, T high,
        size_t line = __LINE__, string file = __FILE__
    ){
        this(index, low, high, true, true, line, file);
    }
    this(
        T index, T low, T high, bool haslow, bool hashigh,
        size_t line = __LINE__, string file = __FILE__
    ){
        this.index = index; this.low = low; this.high = high;
        this.haslow = haslow; this.hashigh = hashigh;
        string message = void;
        if(haslow & hashigh){
            message = "Value %s is out of bounds %s..%s.".format(index, low, high);
        }else if(haslow){
            message = "Value %s is out of bounds, must be at least %s.".format(index, low);
        }else if(hashigh){
            message = "Value %s is out of bounds, must be no greater than %s.".format(index, high);
        }else{
            message = "Value %s is out of bounds.".format(index);
        }
        super(message, file, line, null);
    }
    
    static void enforce(
        T index, T low, T high,
        size_t line = __LINE__, string file = __FILE__
    ){
        if((index < low) | (index >= high)){
            throw new OutOfBoundsException(index, low, high, line, file);
        }
    }
    static void enforcelow(
        T index, T low,
        size_t line = __LINE__, string file = __FILE__
    ){
        if(index < low){
            throw new OutOfBoundsException(index, low, 0, true, false, line, file);
        }
    }
    static void enforcehigh(
        T index, T high,
        T line = __LINE__, string file = __FILE__
    ){
        if(index >= high){
            throw new OutOfBoundsException(index, 0, high, false, true, line, file);
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
