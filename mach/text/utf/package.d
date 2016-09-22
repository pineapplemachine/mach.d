module mach.text.utf;

public:

import mach.text.utf.common;
import mach.text.utf.decode;
import mach.text.utf.encode;



version(unittest){
    private:
    import mach.error.unit;
    import mach.range.compare : equals;
}
unittest{
    tests("UTF encoding & decoding", {
        auto encoded = "!\xD7\x90\xE3\x83\x84\xF0\x9F\x98\x83";
        test(encoded.utfdecode.utfencode.equals(encoded));
        auto decoded = "!אツ😃"d;
        test(decoded.utfencode.utfdecode.equals(decoded));
    });
}
