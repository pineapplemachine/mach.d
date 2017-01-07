module mach.io.file;

public:

import mach.io.file.attributes;
import mach.io.file.exceptions;
import mach.io.file.file;
import mach.io.file.stat;
import mach.io.file.traverse;



version(unittest){
    private:
    import std.path;
    import mach.test;
}
unittest{
    tests("Stat file handle", {
        import mach.io.file.sys : fopen, fclose;
        enum string TestPath = __FILE__.dirName ~ "/stat.txt";
        auto file = fopen(TestPath, "rb");
        testeq(Stat(file).size, 85);
        file.fclose;
    });
}
