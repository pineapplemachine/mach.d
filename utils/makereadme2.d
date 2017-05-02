/// This module is used to create markdown readmes from D source files
/// containing unittests. This way, it's easy to verify that code examples
/// in readmes don't become obsolete.

private:

import mach.text.ascii;
import mach.io;
import mach.io.file.sys;
import mach.range;
import mach.text.utf;

public:



immutable readmepaths = [
    "mach/io",
    "mach/io/file",
    "mach/math",
    "mach/math/bits",
    "mach/math/ints",
    "mach/math/trig",
    "mach/meta",
    "mach/range",
    "mach/sys",
    "mach/text",
    "mach/text/cstring",
    "mach/text/english",
    "mach/text/numeric",
    "mach/text/str",
    "mach/text/utf",
    "mach/text/utf/utf8",
    "mach/text/utf/utf16",
];

void main(){
    foreach(path; readmepaths){
        stdio.writeln("Making readme for path: ", path);
        makereadme("../" ~ path);
    }
}



void makereadme(in string path){
    dstring[][dstring] docs;
    ParseResult[] stats;
    void handlepath(in string path){
        auto file = Path(path).readfrom;
        dstring source = cast(dstring) file.utf8decode.asarray;
        file.close();
        auto result = parsemodule(path, source, docs);
        if(result.modulename.length) stats ~= result;
    }
    foreach(entry; Path(path).listdir){
        if(
            !entry.name.headis("wip_") &&
            !entry.name.headis("old_") &&
            !entry.name.headis("reject_")
        ){
            if(entry.isfile && entry.name.tailis(".d")){
                handlepath(entry.path);
            }else if(entry.isdir && exists(entry.path ~ "/package.d")){
                handlepath(entry.path ~ "/package.d");
            }
        }
    }
    reportstats(stats);
    dstring content = makecontent(docs);
    Path(path ~ "/readme.md").writeto(content.utf8encode);
}

struct ParseResult{
    string filepath;
    dstring modulename;
    uint lines;
}

ParseResult parsemodule(in string path, in dstring content, ref dstring[][dstring] docs){
    uint countlines = 0;
    auto lines = content.split("\n");
    dstring stripws(dstring str){
        return cast(dstring) str.strip!iswhitespace.asarray;
    }
    dstring nextline(){
        return stripws(cast(dstring) lines.next.asarray);
    }
    dstring section = "";
    dstring modulename = "";
    while(!lines.empty){
        auto line = nextline;
        if(line.headis("module") && line.tailis(";")){
            modulename = stripws(line[6 .. $-1]);
            section = modulename;
        }else if(line.headis("/++ Docs")){
            if(line.length > 8 && line[8] == ':'){
                section = stripws(line[9 .. $]);
            }else if(section == ""){
                assert(false, "Must specify a section in file \"" ~ path ~ "\".");
            }
            while(!lines.empty){
                auto docsline = nextline();
                if(docsline.equals("+/")) break;
                docs[section] ~= docsline;
                countlines++;
            }
        }else if(line.headis("unittest{ /// Example")){
            if(section == ""){
                assert(false, "Must specify a section in file \"" ~ path ~ "\".");
            }
            dstring[] codelines;
            uint braces = 1;
            uint commonws = 0;
            bool first = true;
            while(!lines.empty){
                auto codeline = cast(dstring) lines.next.asarray;
                braces += codeline.count('{').total;
                braces -= codeline.count('}').total;
                if(braces == 0) break;
                uint ws = cast(uint) codeline.until!(ch => ch != ' ').walklength;
                if(first){
                    commonws = ws;
                    first = false;
                }else{
                    commonws = ws < commonws ? ws : commonws;
                }
                codelines ~= codeline;
                countlines++;
            }
            dstring code = cast(dstring) codelines.map!(l => l[commonws .. $]).join("\n").asarray;
            docs[section] ~= "``` D\n" ~ code ~ "\n```\n";
        }
    }
    return ParseResult(
        path, modulename, countlines
    );
}

void reportstats(ref ParseResult[] stats){
    stats.mergesort!((a, b) => (a.lines < b.lines));
    ulong totallines = 0;
    foreach(result; stats){
        totallines += result.lines;
        if(result.lines == 0){
            stdio.writeln(
                "NO DOCS in module ", result.modulename, "."
            );
        }else if(result.lines < 6 && !result.filepath.tailis("package.d")){
            stdio.writeln(
                "MINIMAL DOCS in module ", result.modulename, ": ", result.lines, " lines."
            );
        }
    }
    foreach(i; 0 .. (stats.length < 5 ? stats.length : 5)){
        auto result = stats[$-i-1];
        stdio.writeln(
            "TOP DOCS in module ", result.modulename, ": ", result.lines, " lines."
        );
    }
}

dstring makecontent(ref dstring[][dstring] docs){
    dstring content = ""d;
    dstring[] sections = docs.byKey().asarray;
    sections.mergesort!((a, b) => lexorder(a, b) == -1);
    uint mindots = cast(uint) sections.map!(s => s.count('.').total).top;
    foreach(section; sections){
        uint hashes = cast(uint)(1 + section.count('.') - mindots);
        dstring header = cast(dstring) finiterangeof(hashes, dchar('#')).asarray ~ " "d ~ section;
        content ~= header ~ "\n\n"d;
        foreach(line; docs[section]){
            content ~= line ~ "\n"d;
        }
        content ~= "\n"d;
    }
    return content;
}

