module mach.text.html.namedchar.named;

private:

import mach.text.html.namedchar.data : NamedChars;

public:



/// Records HTML5 named character references as defined here:
/// https://www.w3.org/TR/html5/syntax.html#named-character-references
struct NamedChar{
    alias Point = dchar;
    alias Points = immutable(Point)[];
    
    string name; /// The name of the sequence of code points.
    Points points; /// The named sequence of code points.
    
    static Points[string] bynamearray;
    static string[Points] bypointsarray;
    
    static void buildbyname(){
        foreach(named; NamedChars) bynamearray[named.name] = named.points;
    }
    static void buildbypoints(){
        foreach(named; NamedChars) bypointsarray[named.points] = named.name;
    }
    
    /// Get an associative array mapping names to code points.
    /// The array is built the first time it's requested, and only the first time.
    static @property auto byname(){
        if(!bynamearray) buildbyname();
        return bynamearray;
    }
    /// Get an associative array mapping code points to names.
    /// The array is built the first time it's requested, and only the first time.
    static @property auto bypoints(){
        if(!bypointsarray) buildbypoints();
        return bypointsarray;
    }
    
    /// Get whether some string represents a recognized character name.
    static auto isname(string name){
        return name in byname;
    }
    /// Get the code points corresponding to some character name.
    static auto getpoints(string name){
        return byname[name];
    }
    /// Get whether a code point has a known name.
    static auto isnamed(Point point){
        return isnamed([point]);
    }
    /// Get whether some sequence of code points has a known name.
    static auto isnamed(Points points){
        return points in bypoints;
    }
    /// Get the name of a code point.
    /// Note that some inputs may have multiple valid names, and this
    /// method will only return one of them.
    static auto getname(Point point){
        return getname([point]);
    }
    /// Get the name of a sequence of code points.
    /// Note that some inputs may have multiple valid names, and this
    /// method will only return one of them.
    static auto getname(Points points){
        return bypoints[points];
    }
}



version(unittest){
    private:
    import mach.error.unit;
}
unittest{
    tests("HTML5 named chars", {
        tests("Is name", {
            test(NamedChar.isname("amp"));
            test(NamedChar.isname("AMP"));
            test(NamedChar.isname("gt"));
            test(NamedChar.isname("GT"));
            test(NamedChar.isname("acE"));
            test(NamedChar.isname("nbsp"));
            testf(NamedChar.isname(""));
            testf(NamedChar.isname(" "));
            testf(NamedChar.isname("hello"));
        });
        tests("Has name", {
            test(NamedChar.isnamed('&'));
            test(NamedChar.isnamed("&"));
            test(NamedChar.isnamed(">"));
            test(NamedChar.isnamed("<"));
            test(NamedChar.isnamed("é"));
            test(NamedChar.isnamed("\u223E\u0333")); // acE;
            testf(NamedChar.isnamed(""));
            testf(NamedChar.isnamed("a"));
            testf(NamedChar.isnamed("hi"));
        });
        tests("Get name", {
            auto amp = NamedChar.getname('&');
            test(amp == "amp" || amp == "AMP");
            auto gt = NamedChar.getname(">");
            test(gt == "gt" || gt == "GT");
        });
        tests("Get code points", {
            testeq(NamedChar.getpoints("amp"), "&"d);
            testeq(NamedChar.getpoints("AMP"), "&"d);
            testeq(NamedChar.getpoints("gt"), ">"d);
            testeq(NamedChar.getpoints("GT"), ">"d);
            testeq(NamedChar.getpoints("acE"), "\u223E\u0333"d);
        });
    });
}
