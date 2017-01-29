module mach.text.escape;

public:

import mach.text.escape.escaper;
import mach.text.escape.exceptions;
import mach.text.escape.unescape;



private version(unittest){
    import mach.test;
    import mach.range : consume, equals, any;
    void CommonTests(in Escaper esc){
        tests("Common", {
            tests("Escape", {
                test!equals(esc.escape(""), ``);
                test!equals(esc.escape(" "), ` `);
                test!equals(esc.escape("x"), `x`);
                test!equals(esc.escape("test"), `test`);
                test!equals(esc.escape("\\"), `\\`);
                test!equals(esc.escape("\\\\"), `\\\\`);
                test!equals(esc.utf8escape(""), ``);
                test!equals(esc.utf8escape(" "), ` `);
                test!equals(esc.utf8escape("x"), `x`);
                test!equals(esc.utf8escape("test"), `test`);
                test!equals(esc.utf8escape("\\"), `\\`);
                test!equals(esc.utf8escape("\\\\"), `\\\\`);
            });
            tests("Unescape", {
                test!equals(esc.unescape(``), "");
                test!equals(esc.unescape(` `), " ");
                test!equals(esc.unescape(`x`), "x");
                test!equals(esc.unescape(`test`), "test");
                test!equals(esc.unescape(`\\`), "\\");
                test!equals(esc.unescape(`\\\\`), "\\\\");
                testfail({esc.unescape(`\`).consume;});
                testfail({esc.unescape(`\\\`).consume;});
            });
        });
        tests("Pairs", {
            if(esc.pairs.any!(e => e.original == '"')){
                test!equals(esc.escape("\""), `\"`);
                test!equals(esc.escape("\"quotes\""), `\"quotes\"`);
                test!equals(esc.utf8escape("\""), `\"`);
                test!equals(esc.utf8escape("\"quotes\""), `\"quotes\"`);
                test!equals(esc.unescape(`\"`), "\"");
                test!equals(esc.unescape(`\"quotes\"`), "\"quotes\"");
            }
            if(esc.pairs.any!(e => e.original == '\t')){
                test!equals(esc.escape("\t"), `\t`);
                test!equals(esc.escape("\t-tab"), `\t-tab`);
                test!equals(esc.utf8escape("\t"), `\t`);
                test!equals(esc.utf8escape("\t-tab"), `\t-tab`);
                test!equals(esc.unescape(`\t`), "\t");
                test!equals(esc.unescape(`\t-tab`), "\t-tab");
            }
        });
        tests("\\x", {
            if(esc.xesc){
                tests("Escape", {
                    test!equals(esc.escape("\x05"), `\x05`);
                    test!equals(esc.escape("\x05\x06"), `\x05\x06`);
                    test!equals(esc.escape("\x01\x02\x03"), `\x01\x02\x03`);
                    test!equals(esc.utf8escape("\x05"), `\x05`);
                    test!equals(esc.utf8escape("\x05\x06"), `\x05\x06`);
                    test!equals(esc.utf8escape("\xE3\x83\x84"), `\xE3\x83\x84`);
                    test!equals(esc.utf8escape("\x01\x02\x03"), `\x01\x02\x03`);
                });
                tests("Unescape", {
                    test!equals(esc.unescape(`\x05`), "\x05");
                    test!equals(esc.unescape(`\x05\x06`), "\x05\x06");
                    test!equals(esc.unescape(`\xE3\x83\x84`), "\xE3\x83\x84");
                    test!equals(esc.unescape(`\x01\x02\x03`), "\x01\x02\x03");
                });
            }else{
                testfail({esc.unescape(`\x05`);});
                testfail({esc.unescape(`\x05\x06`);});
            }
        });
        tests("\\u", {
            if(esc.u16esc){
                if(!esc.xesc) tests("Escape", {
                    test!equals(esc.escape("\u1E02"d), `\u1E02`);
                    test!equals(esc.escape("\u1E02\u1E03"d), `\u1E02\u1E03`);
                    test!equals(esc.escape("\u03D5\u03D6"d), `\u03D5\u03D6`);
                    test!equals(esc.escape("hi\u03D5\u03D6hi"d), `hi\u03D5\u03D6hi`);
                    static assert(!is(typeof({esc.utf8escape("\u1E02"d);})));
                });
                tests("Unescape", {
                    test!equals(esc.unescape(`\u1E02`), "\u1E02");
                    test!equals(esc.unescape(`\u1E02\u1E03`), "\u1E02\u1E03");
                    test!equals(esc.unescape(`\u03D5\u03D6`), "\u03D5\u03D6");
                    test!equals(esc.unescape(`hi\u03D5\u03D6hi`), "hi\u03D5\u03D6hi");
                });
            }else{
                testfail({esc.unescape(`\u1E02`);});
                testfail({esc.unescape(`\u1E02\u1E03`);});
            }
        });
        tests("\\U", {
            if(esc.u32esc){
                if(!esc.xesc) tests("Escape", {
                    test!equals(esc.escape("\U0001F603"d), `\U0001F603`);
                    test!equals(esc.escape("\U0001F603\U0001F604"d), `\U0001F603\U0001F604`);
                    test!equals(esc.escape("hi\U0001F603hi"d), `hi\U0001F603hi`);
                });
                tests("Unescape", {
                    test!equals(esc.unescape(`\U0001F603`), "\U0001F603");
                    test!equals(esc.unescape(`\U0001F603\U0001F604`), "\U0001F603\U0001F604");
                    test!equals(esc.unescape(`hi\U0001F603hi`), "hi\U0001F603hi");
                });
            }else{
                testfail({esc.unescape(`\U0001F603`);});
                testfail({esc.unescape(`\U0001F603\U0001F604`);});
            }
        });
        tests("Octal", {
            if(esc.octesc){
                if(!esc.xesc) tests("Escape", {
                    test!equals(esc.escape("\0"), `\0`);
                    test!equals(esc.escape("\1\2\3"), `\1\2\3`);
                    test!equals(esc.escape("hi\1\2\3hi"), `hi\1\2\3hi`);
                });
                tests("Unescape", {
                    test!equals(esc.unescape(`\0`), "\0");
                    test!equals(esc.unescape(`\1\2\3`), "\1\2\3");
                    test!equals(esc.unescape(`hi\1\2\3hi`), "hi\1\2\3hi");
                    if(esc.octesclength >= 2) test!equals(esc.unescape(`\41\41\41`), "!!!");
                    if(esc.octesclength >= 3) test!equals(esc.unescape(`\101\102\103`), "ABC");
                    if(esc.octesclength == 1) test!equals(esc.unescape(`\50`), "\x050");
                    if(esc.octesclength == 2) test!equals(esc.unescape(`\410`), "!0");
                    if(esc.octesclength == 3) test!equals(esc.unescape(`\1010`), "A0");
                });
            }else{
                testfail({esc.unescape(`\1`);});
                testfail({esc.unescape(`\1\2\3`);});
                testfail({esc.unescape(`\101\102\103`);});
            }
        });
        tests("Named", {
            if(esc.nameesc){
                if(!esc.xesc && !esc.u16esc && !esc.u32esc) tests("Escape", {
                    test!equals(esc.escape("\&alpha;"d), `\&alpha;`);
                    test!equals(esc.escape("\&alpha;\&beta;\&gamma;"d), `\&alpha;\&beta;\&gamma;`);
                    test!equals(esc.escape("hi\&alpha;\&beta;\&gamma;hi"d), `hi\&alpha;\&beta;\&gamma;hi`);
                });
                tests("Unescape", {
                    test!equals(esc.unescape(`\&amp;`), "\&amp;");
                    test!equals(esc.unescape(`\&alpha;\&beta;\&gamma;`), "\&alpha;\&beta;\&gamma;");
                    test!equals(esc.unescape(`hi\&alpha;\&beta;\&gamma;hi`), "hi\&alpha;\&beta;\&gamma;hi");
                });
                tests("Multi-code-point sequences", {
                    if(esc.nameescmulti){
                        test!equals(esc.unescape(`\&lates;`), "\u2AAD\uFE00");
                    }else{
                        testfail({esc.unescape(`\&lates;`);});
                    }
                });
            }else{
                testfail({esc.unescape(`\&amp;`);});
                testfail({esc.unescape(`\&alpha;\&beta;\&gamma;`);});
            }
        });
    }
}

unittest{
    tests("Escaper", {
        tests("Only \\x", {
            immutable Escaper xesc = {xesc: true};
            CommonTests(xesc);
        });
        tests("Only \\u", {
            immutable Escaper u16 = {u16esc: true};
            CommonTests(u16);
        });
        tests("Only \\U", {
            immutable Escaper u32 = {u32esc: true};
            CommonTests(u32);
        });
        tests("Only octal", {
            immutable Escaper oct1 = {octesc: true, octesclength: 1};
            CommonTests(oct1);
            immutable Escaper oct2 = {octesc: true, octesclength: 2};
            CommonTests(oct2);
            immutable Escaper oct3 = {octesc: true, octesclength: 3};
            CommonTests(oct3);
        });
        tests("Only named", {
            immutable Escaper name1 = {nameesc: true, nameescmulti: false};
            CommonTests(name1);
            immutable Escaper namen = {nameesc: true, nameescmulti: true};
            CommonTests(namen);
        });
        tests("D", {
            CommonTests(Escaper.D);
        });
        tests("Unprintable", {
            immutable Escaper cool = {unprintable: true};
            CommonTests(cool);
            test!equals(cool.escape("\x00"), "\x00");
            immutable Escaper dumb = {unprintable: false};
            CommonTests(dumb);
            testfail({dumb.escape("\x00");});
        });
    });
}

unittest{
    tests("Unescape UTF-16 surrogate pair", {
        test!equals(Escaper.D.unescape(`\ud83d\ude03`), "😃");
        testfail({Escaper.D.unescape(`\ud83d`);});
    });
}
