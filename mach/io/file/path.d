module mach.io.file.path;

private:

import mach.meta : All;
import mach.traits : isIterable, isString;
import mach.io.stream : FileStream, write, asrange, asarray;
import mach.range : asarray;
import mach.text.utf : utf8encode;
import mach.io.file.exceptions;
import mach.io.file.sys;
import mach.io.file.traverse;

// TODO: More better docs

/++ Docs

The `Path` type may be used to perform actions and manipulations with file paths.
An instance should be created simply by calling the constructor with some string
representing a file path.

+/

unittest{ /// Example
    import mach.range : tailis;
    auto path = Path(__FILE_FULL_PATH__); // .../mach/io/file/path.d
    assert(path.exists); // Refers to an actual file or directory?
    assert(path.isfile); // It's a file,
    assert(!path.isdir); // It's not a directory,
    assert(!path.islink); // Nor is it a symbolic link.
    assert(path.basename == "path.d"); // Get the file name
    assert(path.directory.tailis("file")); // Get the directory, .../mach/io/file
    assert(path.extension == "d"); // Get the file extension
    assert(path.stripext.tailis("path")); // Get the path without the extension
    assert(path.filesize > 100); // Get the file size in bytes
}

/++ Docs

Also supported are `copy`, `rename`, and `remove` methods.

+/

unittest{ /// Example
    auto path = Path(__FILE_FULL_PATH__); // .../mach/io/file/path.d
    auto copy = path.copy(path ~ ".unittest.copied");
    auto renamed = copy.rename(path ~ ".unittest.renamed");
    renamed.remove();
    assert(!renamed.exists);
}

public:



/// Represents a file path.
struct Path{
    version(Windows){
        enum CaseInsensitive = true;
        enum DefaultSeparator = '/';
        static bool issep(in dchar ch){
            return ch == '/' || ch == '\\';
        }
    }else{
        enum CaseInsensitive = false;
        enum DefaultSeparator = '/';
        static bool issep(in dchar ch){
            return ch == '/';
        }
    }
    
    string path;
    alias path this;
    
    this(string path){
        this.path = path;
    }
    this(S)(auto ref S path) if(isString!S){
        this(path.utf8encode.asarray!(immutable char));
    }
    
    /// Get the current working directory.
    static @property auto currentdir(){
        return typeof(this)(.currentdir());
    }
    /// Set the current working directory.
    static @property void currentdir(in string path){
        chdir(path);
    }
    
    /// Join together paths or parts of paths.
    static Path join(T...)(in T paths) if(All!(isString, T)){
        static if(paths.length == 0){
            return Path("");
        }else static if(paths.length == 1){
            return Path(paths[0]);
        }else{
            string result = paths[0];
            foreach(path; paths[1 .. $]){
                if(result.length == 0){
                    result = path;
                }else if(path.length > 0){
                    immutable pstring = path.utf8encode.asarray!(immutable char);
                    if(typeof(this).issep(result[$-1]) || typeof(this).issep(path[0])){
                        result ~= pstring;
                    }else{
                        result ~= DefaultSeparator ~ pstring;
                    }
                }
            }
            return Path(result);
        }
    }
    
    /// Get the base name of the file, directory, etc. that this path refers to.
    /// For example, `Path("a/b/c").basename == "c"`.
    string basename(bool includeslash = false)() const{
        if(this.path.length > 0){
            bool firstnonslash = false;
            size_t firstnonslashi = this.path.length;
            int i = cast(int) this.path.length;
            while(--i >= 0){
                if(this.issep(this.path[i])){
                    if(firstnonslash) return this.path[i + 1 .. firstnonslashi];
                }else if(!firstnonslash){
                    firstnonslash = true;
                    static if(!includeslash) firstnonslashi = i + 1;
                }
            }
            return firstnonslash ? this.path[0 .. firstnonslashi] : "";
        }else{
            return "";
        }
    }
    /// Get the directory in which the file, directory, etc. resides.
    /// For example, `Path("a/b/c").directory == "a/b"`.
    Path directory(bool includeslash = false)() const{
        if(this.path.length > 0){
            int i = cast(int) this.path.length;
            while(--i >= 0){
                if(!this.issep(this.path[i])) break;
            }
            static if(includeslash){
                if(i == 0) return this;
                while(--i >= 0){
                    if(this.issep(this.path[i])){
                        return Path(this.path[0 .. i + 1]);
                    }
                }
                return Path("");
            }else{
                while(--i >= 0){
                    if(this.issep(this.path[i])) break;
                }
                if(i == 0) return Path("");
                while(--i >= 0){
                    if(!this.issep(this.path[i])){
                        return Path(this.path[0 .. i + 1]);
                    }
                }
                return Path("");
            }
        }else{
            return this;
        }
    }
    /// Get the file extension.
    /// For example, `Path("a/b/c.txt").extension == "txt"`.
    string extension() const{
        if(this.path.length > 0 && !this.issep(this.path[$-1])){
            immutable basename = this.basename!true;
            if(basename.length > 0){
                int i = cast(int) basename.length;
                while(--i > 0){
                    if(basename[i] == '.') return basename[i + 1 .. $];
                }
            }
        }
        return "";
    }
    /// Get the path sans extension as would be returned by `path.extension`,
    /// if any.
    Path stripext() const{
        immutable ext = this.extension;
        return Path(this.path[0 .. $ - (ext.length ? ext.length + 1 : 0)]);
    }
    
    /// Get the size of a file to which the path refers.
    auto filesize() const{
        return .filesize(this.path);
    }
    
    alias TraverseMode = .TraverseDirMode;
    /// Get a range for recursively enumerating all files, subdirectories, and
    /// files in subdirectories contained in the directory referred to by this
    /// path.
    auto traversedir(TraverseMode mode = TraverseMode.DepthFirst)() const{
        return .traversedir(this.path);
    }
    /// Get a range for enumerating all files and subdirectories contained in
    /// the directory referred to by this path.
    /// The listing is not recursive and files in subdirectories are not
    /// included in the output.
    auto listdir() const{
        return .listdir(this.path);
    }
    
    /// Create and open a file stream for a new temporary file.
    /// TODO: Provide a function that returns a path with an optionally
    /// specified temp file directory.
    static auto temp(){
        return FileStream.temp();
    }
    
    /// Copy a file.
    /// Returns a `Path` object referring to the destination path.
    auto copy(in Path destination) const{
        .copyfile(this.path, destination.path);
        return destination;
    }
    /// Ditto
    auto copy(in string destination) const{
        return this.copy(typeof(this)(destination));
    }
    
    /// Rename a file.
    /// Returns a new `Path` object referring to the destination path.
    auto rename(in Path destination) const{
        .rename(this.path, destination.path);
        return destination;
    }
    /// Ditto
    auto rename(in string destination) const{
        return this.rename(typeof(this)(destination));
    }
    
    /// Remove the file or directory at a path.
    /// TODO: This needs to be able to remove links
    void remove() const{
        if(this.isfile){
            rmfile(this.path);
        }else if(this.isdir){
            rmdir(this.path);
        }else{
            throw new FileRemoveException(this.path);
        }
    }
    
    /// Get whether the path exists.
    auto exists() const{
        return .exists(this.path);
    }
    
    /// Get whether a path refers to a file.
    auto isfile() const{
        return .isfile(this.path);
    }
    /// Get whether a path refers to a directory.
    auto isdir() const{
        return .isdir(this.path);
    }
    /// Get whether a path refers to a symbolic link.
    auto islink() const{
        return .islink(this.path);
    }
    
    /// Open the file at a path.
    auto open(in string mode = "rb") const{
        return FileStream(this.path, mode);
    }
    /// Open the file at a path in read mode.
    auto read() const{
        return this.open("rb");
    }
    /// Open the file at a path in write mode.
    auto write() const{
        return this.open("w+b");
    }
    /// Open the file at a path in append mode.
    auto append() const{
        return this.open("ab");
    }
    
    /// Read data from a file path as a range with elements of type T.
    /// The returned stream should be closed when no longer needed by using
    /// e.g. `stream.close();`.
    auto readfrom(T = char)() const{
        return this.read.asrange!T;
    }
    /// Read data from a file path as an array with elements of type T.
    /// The data is consumed all at once and stored in-memory, and then the
    /// file stream is automatically closed.
    auto readall(T = immutable char)() const{
        auto stream = this.read();
        scope(exit) stream.close;
        return stream.asarray!T;
    }
    
    /// Write some data to a file path and then automatically close the stream.
    auto writeto(T)(auto ref T data){
        auto stream = this.write();
        scope(exit) stream.close();
        stream.write(data);
    }
    /// Append some data to a file path and then automatically close the stream.
    auto appendto(T)(auto ref T data){
        auto stream = this.append();
        scope(exit) stream.close();
        stream.write(data);
    }
    
    /// Get a string representation of this path object.
    auto toString() const{
        return this.path;
    }
    
    /// Check equality with another path.
    /// Ignores trailing slashes, or repeated slashes.
    /// Comparison is case-sensitive, even on Windows.
    /// TODO: Investigate using case-insensitive comparison on Windows.
    bool opEquals(in Path path) const{
        return this == path.path;
    }
    /// Ditto
    bool opEquals(in string path) const{
        size_t i = 0;
        size_t j = 0;
        while(i < this.path.length && j < path.length){
            if(this.issep(this.path[i]) && this.issep(path[j])){
                while(i < this.path.length && this.issep(this.path[i])) i++;
                while(j < path.length && this.issep(path[j])) j++;
            }else if(this.path[i] == path[j]){
                i++; j++;
            }else{
                return false;
            }
        }
        while(i < this.path.length){
            if(!this.issep(this.path[i++])) return false;
        }
        while(j < path.length){
            if(!this.issep(path[j++])) return false;
        }
        return true;
    }
    
    /// Get a hash of the file path.
    /// Paths which are equal according to opEquals will have identical hashes.
    size_t toHash() const{
        // Based on the djb2 hashing algorithm http://www.cse.yorku.ca/~oz/hash.html
        size_t hash = 0;
        int i = cast(int) this.path.length;
        size_t slashi = 0xfffe;
        bool firstnonslash = false;
        while(--i >= 0){
            firstnonslash = firstnonslash || !this.issep(this.path[i]);
            if(firstnonslash){
                if(this.issep(this.path[i])){
                    while(i < this.path.length && this.issep(this.path[i])) i--;
                    hash = (hash << 5 + hash) ^ slashi;
                    slashi = slashi << 5 - slashi;
                }else{
                    hash = (hash << 5 + hash) ^ this.path[i];
                }
            }
        }
        return hash;
    }
}


import mach.io.stdio;
private version(unittest){
    import mach.range : headis, equals;
    import mach.io.stream : read;
}

unittest{ /// Directory name and base name
    // Directory name
    assert(Path(``).directory == ``);
    assert(Path(`/`).directory == ``);
    assert(Path(`x`).directory == ``);
    assert(Path(`x/`).directory == ``);
    assert(Path(`/x`).directory == ``);
    assert(Path(`x/y`).directory == `x`);
    assert(Path(`x/y/z`).directory == `x/y`);
    assert(Path(`xx/`).directory!false == ``);
    assert(Path(`xx/yy/`).directory!false == `xx`);
    assert(Path(`xx//yy//`).directory!false == `xx`);
    assert(Path(`xx/`).directory!true == ``);
    assert(Path(`xx/yy/`).directory!true == `xx/`);
    assert(Path(`xx//yy//`).directory!true == `xx//`);
    assert(Path(`hello.txt/world.txt`).directory == `hello.txt`);
    // Base name
    assert(Path(``).basename == ``);
    assert(Path(`/`).basename == ``);
    assert(Path(`x`).basename == `x`);
    assert(Path(`x/`).basename == `x`);
    assert(Path(`/x`).basename == `x`);
    assert(Path(`x/y`).basename == `y`);
    assert(Path(`x/y/z`).basename == `z`);
    assert(Path(`xx`).basename!false == `xx`);
    assert(Path(`xx/`).basename!false == `xx`);
    assert(Path(`xx/yy/`).basename!false == `yy`);
    assert(Path(`xx//yy//`).basename!false == `yy`);
    assert(Path(`xx`).basename!true == `xx`);
    assert(Path(`xx/`).basename!true == `xx/`);
    assert(Path(`xx/yy/`).basename!true == `yy/`);
    assert(Path(`xx//yy//`).basename!true == `yy//`);
    assert(Path(`hello.txt/world.txt`).basename == `world.txt`);
    // Platform-specific
    version(Windows){
        assert(Path(`hi/hello\world`).directory == `hi/hello\`);
        assert(Path(`hi/hello\world`).basename == `world`);
    }else{
        assert(Path(`hi/hello\world`).directory == `hi/`);
        assert(Path(`hi/hello\world`).basename == `hello\world`);
    }
        
}

unittest{ /// Extension
    /// Get extension
    assert(Path(``).extension == ``);
    assert(Path(`.`).extension == ``);
    assert(Path(`a.`).extension == ``);
    assert(Path(`a.b`).extension == `b`);
    assert(Path(`a.txt`).extension == `txt`);
    assert(Path(`x/y.pdf`).extension == `pdf`);
    assert(Path(`ab.cd/ef.gh/hi`).extension == ``);
    assert(Path(`ab.cd/ef.gh/hi.there`).extension == `there`);
    assert(Path(`hello/worl.d`).extension == `d`);
    assert(Path(`.x`).extension == ``); // Initial period doesn't begin an extension
    assert(Path(`abc/.x`).extension == ``); // Ditto
    assert(Path(`x.y/`).extension == ``); // Directories don't have extensions
    /// Get without extension
    assert(Path(``).stripext == ``);
    assert(Path(`.`).stripext == `.`);
    assert(Path(`a.`).stripext == `a.`); // Trailing period isn't an extension
    assert(Path(`a.b`).stripext == `a`);
    assert(Path(`a.txt`).stripext == `a`);
    assert(Path(`x/y.pdf`).stripext == `x/y`);
    assert(Path(`ab.cd/ef.gh/hi`).stripext == `ab.cd/ef.gh/hi`);
    assert(Path(`ab.cd/ef.gh/hi.there`).stripext == `ab.cd/ef.gh/hi`);
    assert(Path(`hello/worl.d`).stripext == `hello/worl`);
    assert(Path(`.x`).stripext == `.x`); // Initial period doesn't begin an extension
    assert(Path(`abc/.x`).stripext == `abc/.x`); // Ditto
    assert(Path(`x.y/`).stripext == `x.y/`); // Directories don't have extensions
}

unittest{ /// Exists; is file, directory, or link
    immutable source = Path(__FILE_FULL_PATH__);
    assert(source == __FILE_FULL_PATH__);
    assert(source.exists);
    assert(source.isfile);
    assert(!source.isdir);
    assert(!source.islink);
    immutable dir = Path(source.directory.path);
    assert(source.path.headis(dir.path));
    assert(dir.exists);
    assert(dir.isdir);
    assert(!dir.isfile);
    assert(!dir.islink);
    immutable nope = source ~ "_not_a_real_file";
    assert(nope == __FILE_FULL_PATH__ ~ "_not_a_real_file");
    assert(!nope.exists);
    assert(!nope.isdir);
    assert(!nope.isfile);
    assert(!nope.islink);
}

unittest{ /// Compare paths for equality
    assert(Path("") == Path(""));
    assert(Path("") == Path("/"));
    assert(Path("/") == Path(""));
    assert(Path("/") == Path("/"));
    assert(Path("//") == Path("/"));
    assert(Path("xyz") == Path("xyz"));
    assert(Path("xyz/") == Path("xyz"));
    assert(Path("/xyz") != Path("xyz"));
    assert(Path("xy/z") != Path("xyz"));
    assert(Path("abc/def") == Path("abc/def"));
    assert(Path("abc/def") == Path("abc//def"));
    assert(Path("abc/def") == Path("abc/def/"));
    assert(Path("abc/def") == Path("abc/def//"));
    assert(Path("abc/def") != Path("abcdef"));
    assert(Path("abc/def") != Path("abcd/ef"));
    assert(Path("abc/def") != Path("/abc/def"));
}

unittest{ /// Path to hash
    assert(Path("").toHash() == Path("").toHash());
    assert(Path("x").toHash() != Path("y").toHash());
    assert(Path("abc").toHash() == Path("abc").toHash());
    assert(Path("abc").toHash() == Path("abc/").toHash());
    assert(Path("abc").toHash() == Path("abc//").toHash());
    assert(Path("abc").toHash() != Path("/abc").toHash());
    assert(Path("abc/def").toHash() == Path("abc/def").toHash());
    assert(Path("abc/def").toHash() == Path("abc//def").toHash());
    assert(Path("abc/def").toHash() == Path("abc/def/").toHash());
    assert(Path("abc/def").toHash() == Path("abc//def//").toHash());
}

unittest{ /// Get/set current directory
    assert(Path.currentdir.exists);
    assert(Path.currentdir.isdir);
    assert(!Path.currentdir.isfile);
    assert(!Path.currentdir.islink);
    immutable dir = Path(__FILE_FULL_PATH__).directory;
    Path.currentdir = dir;
    assert(Path.currentdir == dir);
}

unittest{ /// Get file size
    assert(Path(__FILE_FULL_PATH__).filesize == filesize(__FILE_FULL_PATH__));
}

unittest{ /// Copy, rename, and remove
    enum CopyTo = Path(__FILE_FULL_PATH__ ~ ".unittest.copied");
    enum RenameTo = Path(__FILE_FULL_PATH__ ~ ".unittest.renamed");
    auto source = Path(__FILE_FULL_PATH__);
    assert(source.exists);
    assert(!CopyTo.exists);
    assert(!RenameTo.exists);
    auto copied = source.copy(CopyTo);
    assert(source.exists);
    assert(CopyTo.exists);
    assert(!RenameTo.exists);
    assert(CopyTo.filesize == source.filesize);
    auto renamed = copied.rename(RenameTo);
    assert(source.exists);
    assert(!CopyTo.exists);
    assert(RenameTo.exists);
    assert(RenameTo.filesize == source.filesize);
    renamed.remove();
    assert(source.exists);
    assert(!CopyTo.exists);
    assert(!RenameTo.exists);
}

unittest{ /// Read from file
    auto source = Path(__FILE_FULL_PATH__);
    auto stream = source.read;
    assert(stream.read!char(6) == "module");
    stream.close();
}

unittest{ /// Read, write, and append to file
    enum WriteTo = Path(__FILE_FULL_PATH__ ~ ".unittest.written");
    assert(!WriteTo.exists);
    WriteTo.writeto("hello");
    assert(WriteTo.exists);
    auto range = WriteTo.readfrom!char;
    assert(range.equals("hello"));
    range.close();
    assert(WriteTo.readall!char == "hello");
    WriteTo.appendto(" world");
    assert(WriteTo.readall!char == "hello world");
    WriteTo.remove();
    assert(!WriteTo.exists);
}

unittest{ /// List and traverse directory
    enum source = Path(__FILE_FULL_PATH__);
    // List
    uint lcount = 0;
    foreach(entry; source.directory.listdir){
        lcount += entry.name == source.basename;
    }
    assert(lcount == 1);
    // Traverse
    uint tcount = 0;
    foreach(entry; source.directory.traversedir){
        tcount += entry.name == source.basename;
    }
    assert(tcount == 1);
}

unittest{ /// Join paths
    assert(Path.join().path == "");
    assert(Path.join("").path == "");
    assert(Path.join("abc").path == "abc");
    assert(Path.join("abc//").path == "abc//");
    assert(Path.join("abc", "def").path == "abc/def");
    assert(Path.join("abc/", "def").path == "abc/def");
    assert(Path.join("abc//", "def").path == "abc//def");
    assert(Path.join("abc", "/def").path == "abc/def");
    assert(Path.join("abc/", "/def").path == "abc//def");
    assert(Path.join("abc/", "def/", "gh").path == "abc/def/gh");
}
