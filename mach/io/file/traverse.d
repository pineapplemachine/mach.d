module mach.io.file.traverse;

private:

import mach.error : errno, ErrnoException, SysErrorException;
import mach.text.cstring : tocstring, fromcstring;
import mach.text.utf : utf8encode;
import mach.range.asarray : asarray;
import mach.io.file.attributes : Attributes;
import mach.io.file.common;
import mach.io.file.exceptions;
import mach.io.file.path : Path;

public:



/// Exception thrown when listing or traversing a directory fails.
class FileListDirException: FileException{
    string path;
    this(string path, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        super("Failure listing files in directory \"" ~ path ~ "\".", next, line, file);
        this.path = path;
    }
}



/// Get a range for enumerating the files in a directory.
auto listdir(in string path){
    return ListDirRange(path);
}

/// Get a range for traversing all the files and subdirectories in a directory.
/// Accepts a template argument determining whether the traversal is depth-first
/// or breadth-first.
auto traversedir(TraverseDirMode mode = TraverseDirMode.DepthFirst)(in string path){
    return TraverseDirRange!mode(path);
}



struct ListDirRange{
    /// The directory being listed.
    string path;
    /// Whether to include "." and ".." in the output.
    bool skipdots = true;
    
    string toString() const{
        return this.path;
    }
    
    version(Windows){
        import std.datetime : FILETIMEToSysTime; // TODO: Don't depend on this
        import core.sys.windows.winbase;
        import core.sys.windows.winnt;
        
        /// https://msdn.microsoft.com/en-us/library/windows/desktop/aa365740(v=vs.85).aspx
        static struct Entry{
            string listpath;
            WIN32_FIND_DATAW finddata;
            
            @property auto attributes() const{
                return Attributes(this.finddata.dwFileAttributes);
            }
            @property bool isfile() const{
                return this.attributes.isfile;
            }
            @property bool isdir() const{
                return this.attributes.isdir;
            }
            @property bool islink() const{
                return this.attributes.islink;
            }
            
            @property auto creationtime() const{
                return FILETIMEToSysTime(&this.finddata.ftCreationTime);
            }
            @property auto accesstime() const{
                return FILETIMEToSysTime(&this.finddata.ftLastAccessTime);
            }
            @property auto writetime() const{
                return FILETIMEToSysTime(&this.finddata.ftLastWriteTime);
            }
            
            @property auto size() const{
                return (
                    (this.finddata.nFileSizeHigh * (DWORD.max + ulong(1))) +
                    this.finddata.nFileSizeLow
                );
            }
            
            @property string name() const{
                return this.finddata.cFileName.ptr.fromcstring.utf8encode.asarray!(immutable char);
            }
            @property Path path() const{
                return Path(this.listpath ~ "/" ~ this.name);
            }
            
            @property bool isdots() const{
                return (
                    this.finddata.cFileName[0 .. 2] == ".\0"w ||
                    this.finddata.cFileName[0 .. 3] == "..\0"w
                );
            }
        }
        
        WinHandle handle;
        WIN32_FIND_DATAW finddata;
        bool isempty = false;
        
        this(string path){
            this.path = path;
            this.handle = FindFirstFileW((path ~ "\\*.*").tocstring!wchar, &this.finddata);
            if(this.handle == INVALID_HANDLE_VALUE){
                throw new FileListDirException(path, new SysErrorException);
            }
            if(this.skipdots && this.front.isdots) this.popFront();
        }
        
        @property bool empty() const{
            return this.isempty;
        }
        @property auto front() in{assert(!this.empty);} body{
            return Entry(this.path, this.finddata);
        }
        void popFront() in{assert(!this.empty);} body{
            auto result = FindNextFile(this.handle, &this.finddata);
            if(!result){
                if(GetLastError() == ERROR_NO_MORE_FILES){
                    this.isempty = true;
                    FindClose(this.handle);
                }else{
                    throw new FileListDirException(path, new SysErrorException);
                }
            }else{
                if(this.skipdots && this.front.isdots) this.popFront();
            }
        }
    }else{
        import core.sys.posix.dirent;
        
        DIR* handle;
        dirent* current;
        
        /// http://pubs.opengroup.org/onlinepubs/009695399/functions/readdir_r.html
        static struct Entry{
            static if(is(typeof(dirent.d_fileno))){
                alias FileNo = typeof(dirent.d_fileno);
                static private auto getdirentfileno(in dirent* entry){
                    return entry.d_fileno;
                }
            }else static if(is(typeof(dirent.d_ino))){
                alias FileNo = typeof(dirent.d_ino);
                static private auto getdirentfileno(in dirent* entry){
                    return entry.d_ino;
                }
            }else{
                static assert(false, "Unsupported platform.");
            }
            
            string listpath;
            FileNo d_fileno;
            typeof(dirent.d_type) d_type;
            string entryname;
            
            this(string listpath, dirent* entry){
                this.listpath = listpath;
                // This memory is liable to be overwritten later, so dup it now.
                this.d_fileno = this.getdirentfileno(entry);
                this.d_type = entry.d_type;
                // TODO: This will not work on Solaris because of a different
                // representation of file name in the dirent struct.
                // See http://stackoverflow.com/a/563411/4099022
                static if(is(typeof({size_t x = entry.d_namlen;}))){
                    // Optimization available on most posix platforms
                    this.entryname = entry.d_name[0 .. entry.d_namlen].idup;
                }else{
                    this.entryname = entry.d_name.fromcstring;
                }
            }
            
            @property auto fileno() const{
                return this.d_fileno;
            }
            
            @property bool isfile() const{
                return this.d_type == DT_REG;
            }
            @property bool isdir() const{
                return this.d_type == DT_DIR;
            }
            @property bool islink() const{
                return this.d_type == DT_LNK;
            }
            
            @property string name() const{
                return this.entryname;
            }
            @property Path path() const{
                return Path(this.listpath ~ "/" ~ this.name);
            }
            @property bool isdots() const{
                return this.entryname == "." || this.entryname == "..";
            }
        }
        
        this(string path){
            this.path = path;
            this.handle = opendir(path.tocstring!char);
            if(this.handle is null){
                throw new FileListDirException(path, new ErrnoException);
            }else{
                this.nextFront();
            }
        }
        
        @property bool empty() const{
            return this.current is null;
        }
        @property auto front() in{assert(!this.empty);} body{
            return Entry(this.path, this.current);
        }
        void popFront() in{assert(!this.empty);} body{
            this.nextFront();
        }
        private void nextFront() in{assert(this.handle !is null);} body{
            // According to readdir docs, setting errno and checking after the
            // readdir call is the only way to reliably distinguish between EOF
            // and an an error having occurred, when readdir returns null.
            errno = 0;
            this.current = readdir(this.handle);
            ErrnoException.check(
                "Failure listing directory \"" ~ this.path ~ "\"."
            );
            if(this.current !is null){
                if(this.skipdots && (
                    this.current.d_name[0 .. 2] == ".\0" ||
                    this.current.d_name[0 .. 3] == "..\0"
                )){
                    this.nextFront();
                }
            }else{
                closedir(this.handle);
            }
        }
    }
}



static enum TraverseDirMode{
    DepthFirst, BreadthFirst
}

struct TraverseDirRange(TraverseDirMode mode = TraverseDirMode.DepthFirst){
    import mach.collect : LinkedList;
    
    alias Mode = TraverseDirMode;
    
    /// The directory being traversed.
    string path;
    /// If set, the traversal will follow symbolic links.
    bool traverselinks = true;
    
    static if(mode is Mode.DepthFirst){
        ListDirRange*[] dirstack;
    }else{
        LinkedList!(ListDirRange*)* dirstack;
    }
    
    static struct Entry{
        string traversepath;
        ListDirRange.Entry listentry;
        alias listentry this;
    }
    
    this(string path){
        this.path = path;
        this.initdirstack(path);
    }
    
    /// Initialize the stack of directory list ranges.
    private void initdirstack(in string path){
        static if(mode is Mode.BreadthFirst){
            this.dirstack = new LinkedList!(ListDirRange*)();
        }
        this.pushdir(path);
    }
    /// Append a new path to the stack of directories to list.
    private void pushdir(in string path){
        auto dir = new ListDirRange(path);
        if(!dir.empty){
            static if(mode is Mode.DepthFirst){
                this.dirstack ~= dir;
            }else{
                this.dirstack.append(dir);
            }
        }
    }
    /// Remove the current path from the directory list stack.
    /// When depth-first, this is the most recently pushed item.
    /// When breadth-first, this is the oldest pushed item.
    private void popdir() in{assert(!this.empty);} body{
        static if(mode is Mode.DepthFirst){
            this.dirstack.length -= 1;
        }else{
            this.dirstack.removefront;
        }
    }
    /// Get the current directory being listed.
    /// When depth-first, this is the most recently pushed item.
    /// When breadth-first, this is the oldest pushed item.
    private auto currentdir() in{assert(!this.empty);} body{
        static if(mode is Mode.DepthFirst){
            return this.dirstack[$-1];
        }else{
            return this.dirstack.front;
        }
    }
    
    /// Get whether all entries in the directory have been traversed.
    @property bool empty() const{
        static if(mode is Mode.DepthFirst){
            return this.dirstack.length == 0;
        }else{
            return this.dirstack.empty;
        }
    }
    /// Get the file path at the front of the range.
    @property auto front() in{assert(!this.empty);} body{
        return Entry(this.path, this.currentdir.front);
    }
    /// Pop the front file path and continue traversal of the directory tree.
    void popFront() in{assert(!this.empty);} body{
        auto addpath = "";
        if(this.currentdir.front.isdir && (
            this.traverselinks || !this.currentdir.front.islink
        )){
            addpath = this.currentdir.front.path;
        }
        this.currentdir.popFront();
        if(this.currentdir.empty) this.popdir();
        if(addpath != "") this.pushdir(addpath);
    }
}



version(unittest){
    import std.path;
    import mach.test;
    import mach.range : filter, asarray;
    enum string TestPath = __FILE_FULL_PATH__.dirName ~ "/traverse";
    struct Entry{
        string path;
        bool isdir = false;
    }
}
unittest{
    tests("Directory listing", {
        auto expected = [
            Entry(TestPath ~ "/dir", true),
            Entry(TestPath ~ "/a.txt"),
            Entry(TestPath ~ "/b.txt"),
            Entry(TestPath ~ "/c"),
            Entry(TestPath ~ "/readme.txt"),
            Entry(TestPath ~ "/unicodeツ.txt"),
        ];
        auto files = listdir(TestPath).asarray;
        testeq(files.length, expected.length);
        foreach(entry; expected){
            auto file = files.filter!(f => f.path == entry.path).asarray;
            testeq(file.length, 1);
            testeq(file[0].isdir, entry.isdir);
        }
    });
    tests("Directory traversal", {
        auto expected = [
            Entry(TestPath ~ "/dir", true),
            Entry(TestPath ~ "/a.txt"),
            Entry(TestPath ~ "/b.txt"),
            Entry(TestPath ~ "/c"),
            Entry(TestPath ~ "/readme.txt"),
            Entry(TestPath ~ "/unicodeツ.txt"),
            Entry(TestPath ~ "/dir/d.txt"),
            Entry(TestPath ~ "/dir/nesteddir", true),
            Entry(TestPath ~ "/dir/nesteddir/deep.txt", true),
            Entry(TestPath ~ "/dir/nesteddir/deep.txt/deeper.txt", false),
        ];
        void TestTraverse(TraverseDirMode mode)(){
            auto files = traversedir!mode(TestPath).asarray;
            testeq(files.length, expected.length);
            foreach(entry; expected){
                auto file = files.filter!(f => f.path == entry.path).asarray;
                testeq(file.length, 1);
                testeq(file[0].isdir, entry.isdir);
            }
        }
        tests("Depth-first", {
            TestTraverse!(TraverseDirMode.DepthFirst)();
        });
        tests("Breadth-first", {
            TestTraverse!(TraverseDirMode.BreadthFirst)();
        });
    });
}
