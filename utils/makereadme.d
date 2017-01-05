/// This module is used to create markdown readmes from D source files
/// containing unittests. This way, it's easy to verify that code examples
/// in readmes don't become obsolete.

private:

import std.uni;
import mach.io;
import mach.range;
import mach.text.utf;

public:



immutable readmepaths = [
    "readme.d",
    "mach/collect/readme.d",
    "mach/math/floats/readme.d",
    "mach/meta/readme.d",
    "mach/range/readme.d",
    "mach/text/html/namedchar/readme.d",
    "mach/text/json/readme.d",
    "mach/text/str/readme.d"
];

void main(){
    foreach(path; readmepaths){
        log("Making readme for path: ", path);
        makereadme("../" ~ path);
    }
}



auto makereadmecontent(dstring content){
    auto lines = content.split("\n");
    
    string[] markdown;
    dstring mdline = "";
    bool addtext = false;
    bool addcode = false;
    bool addmdcode = false;
    
    void flushmdline(){
        if(mdline.length){
            markdown ~= [cast(string) mdline.utfencode.asarray, ""];
            mdline = "";
        }
    }
    
    foreach(line; lines){
        if(line.headis("/++ md")){
            addtext = true;
        }else if(line.headis("+/")){
            addtext = false;
            flushmdline();
        }else if(addtext){
            if(line.headis("``` D")){
                addmdcode = true;
            }else if(line.headis("```")){
                addmdcode = false;
            }
            if(addmdcode){
                markdown ~= [cast(string) line.utfencode.asarray];
            }else{
                auto l = line.strip!isWhite.asarray;
                if(l.length){
                    if(mdline.length) mdline ~= " ";
                    mdline ~= l;
                }else{
                    flushmdline();
                }
            }
        }else if(line.headis("unittest{")){
            addcode = true;
            flushmdline();
            markdown ~= "``` D";
        }else if(addcode && line.headis("}")){
            addcode = false;
            markdown ~= ["```", ""];
        }else if(addcode){
            markdown ~= cast(string) line[4 .. $].utfencode.asarray;
        }
    }
    
    return markdown.join("\n").asarray;
}

auto makereadme(in string path){
    return makereadme(path, path[0 .. $-1] ~ "md");
}

auto makereadme(in string inpath, in string outpath){
    auto infile = File.read(inpath);
    scope(exit) infile.close();
    auto content = infile.asrange!char.utfdecode.asarray;
    auto mdcontent = makereadmecontent(cast(dstring) content);
    File.writeto(outpath, mdcontent);
}
