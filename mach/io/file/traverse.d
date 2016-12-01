module mach.io.file.traverse;

private:

import std.datetime : FILETIMEToSysTime;
import std.internal.cstring : tempCString;
import mach.error : ErrnoException, SysErrorException;
import mach.text : text;
import mach.io.file.attributes : Attributes;
import mach.io.file.stat : Stat;
import mach.io.file.common;
import mach.io.file.exceptions;

public:



alias FileListDirException = FilePathExceptionTemplate!"Failed to list files in directory";



auto listdir(string path){
    return ListDirRange(path);
}



struct ListDirRange{
    string path; /// The directory being listed.
    bool skipdots = true; /// Whether to include "." and ".." in the output.
    
    version(Windows){
        import core.sys.windows.winbase;
        import core.sys.windows.winnt;
        
        /// https://msdn.microsoft.com/en-us/library/windows/desktop/aa365740(v=vs.85).aspx
        static struct Entry{
            string listpath;
            WinHandle handle;
            WIN32_FIND_DATAW finddata;
            
            @property auto attributes() const{
                return Attributes(this.finddata.dwFileAttributes);
            }
            @property bool isfile() const{return this.attributes.isfile;}
            @property bool isdir() const{return this.attributes.isdir;}
            @property bool islink() const{return this.attributes.islink;}
            
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
                import mach.range : until, asarray;
                import mach.text.utf : utfencode;
                return cast(string) this.finddata.cFileName.until!false(0).utfencode.asarray;
            }
            @property string path() const{
                return this.listpath ~ '\\' ~ this.name;
            }
            
            @property bool isdots(){
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
            this.handle = FindFirstFileW((path ~ "\\*.*").tempCString!FSChar(), &this.finddata);
            if(this.handle == INVALID_HANDLE_VALUE){
                throw new FileListDirException(path, new SysErrorException);
            }
            if(this.skipdots && this.front.isdots) this.popFront();
        }
        
        @property bool empty() const{
            return this.isempty;
        }
        @property auto front() in{assert(!this.empty);} body{
            return Entry(this.path, this.handle, this.finddata);
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
        // TODO: Posix
    }
}

struct TraverseDirRange{
    /// If set, then the traversal will be depth-first. Otherwise, the
    /// traversal with be breadth-first.
    bool depth = true;
    /// If set, only files in the same file system as the root path will be
    /// reported.
    bool mount = true;
    /// If set, the traversal will follow symbolic links.
    bool links = true;
    
    
}



//import mach.io.log;
unittest{
    // TODO
    //import mach.range;
    //auto range = listdir("C:\\Program Files");
    //range.head(30).each!(e => e.name.log);
}
