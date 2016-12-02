module mach.io.path;

/// Note: This module is not yet ready for general consumption

private:

//

public:



version(Windows){
    alias Path = WindowsPath;
}else{
    alias Path = PosixPath;
}



struct PosixPath{
    mixin commonpath!(
        '/', ch => ch == '/'
    );
}

struct WindowsPath{
    mixin commonpath!(
        '/', ch => ch == '/' || ch == '\\'
    );
}



private template commonpath(char separator, alias isseparator){
    
    /// Find the common root of some normalized paths.
    /// Returns an empty string when there is no common root.
    /// TODO: Case-insensitivity on windows
    static string common(in const(string)[] paths...){
        if(paths.length == 0){
            return "";
        }else if(paths.length == 1){
            return paths[0];
        }else{
            // Compare paths
            size_t minlength = paths[0].length;
            for(size_t i = 1; i < paths.length; i++){
                if(paths[i].length < minlength) minlength = paths[i].length;
            }
            size_t index = 0;
            size_t lastsep = 0;
            for(size_t i = 0; i < minlength; i++){
                for(size_t j = 0; j < paths.length - 1; j++){
                    if(paths[j][i] != paths[j+1][i]) goto uncommon;
                }
                if(isseparator(paths[0][i])){
                    lastsep = i;
                }
            }
            
            // Paths are identical, up to the shortest one.
            foreach(path; paths){
                if(path.length > minlength && !isseparator(path[minlength])){
                    goto uncommon;
                }
            }
            
            // The shortest path *is* the common prefix.
            return paths[0][0 .. minlength];
            
            // The paths were not identical up to the length of the shortest one.
            uncommon:
            return paths[0][0 .. lastsep+1];
        }
    }
    
    /// Strip a path of its leading directory.
    static string basename(in string path){
        if(path.length == 0){
            return "";
        }else{
            size_t i = path.length;
            while(i > 0){
                if(!isseparator(path[i - 1])) break;
                i--;
            }
            immutable high = i;
            while(i > 0){
                if(isseparator(path[i - 1])) break;
                i--;
            }
            immutable low = i;
            return path[low .. high];
        }
    }
    
}



unittest{
    assert(Path.basename("") == "");
    assert(Path.basename("x") == "x");
    assert(Path.basename("x/") == "x");
    assert(Path.basename("x/y") == "y");
    assert(Path.basename("x/y/") == "y");
    assert(Path.basename("abc/xyz/123") == "123");
    assert(Path.basename("abc/xyz/123/") == "123");
}
