module mach.io.file.stat;

private:

import std.datetime : SysTime; // TODO: Ewww, this.st module. I should write my own
import mach.error : ErrnoException;
import mach.io.file.common;
import mach.io.file.exceptions;

version(Windows){
    private import core.sys.windows.stat;
    alias cstatstruct = struct_stat;
}else{
    private import core.sys.posix.sys.stat;
    alias cstatstruct = stat_t;
}
alias cstat = stat;
alias cfstat = fstat;

public:

// References:
// http://codewiki.wikidot.com/c:struct-stat
// http://cboard.cprogramming.com/c-programming/91931-difference-between-st_atime-st_mtime-st_ctime.html
// https://mail.python.org/pipermail/python-list/2012-September/632015.html
// https://mail.python.org/pipermail/python-list/2012-September/632124.html
// http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/sys_stat.h.html
// https://www.freebsd.org/cgi/man.cgi?query=fstat&sektion=2&manpath=SuSE+Linux/i386+11.3



struct Stat{
    struct Mode{
        typeof(cstatstruct.st_mode) mode;
        
        /// Whether the stat describes a regular file.
        @property auto isfile(){
            return (this.mode & S_IFMT) == S_IFREG;
        }
        /// Whether the stat describes a directory.
        @property auto isdir(){
            return (this.mode & S_IFMT) == S_IFDIR;
        }
        /// Whether the stat describes a character device.
        @property auto ischar(){
            return (this.mode & S_IFMT) == S_IFDIR;
        }
        /// Whether the stat describes a block device.
        @property auto isblock(){
            return (this.mode & S_IFMT) == S_IFDIR;
        }
        /// Whether the stat describes a named pipe.
        @property auto isfifo(){
            version(Windows){
                // Not 100% sure this is correct but docs are proving scarce
                return (this.mode & S_IFMT) == S_IFNAM;
            }else{
                return (this.mode & S_IFMT) == S_IFIFO;
            }
        }
        /// Whether the stat describes a symbolic link.
        /// Only meaningful for some Posix platforms.
        @property auto islink(){
            static if(is(typeof({S_IFLNK;}))){
                return (this.mode & S_IFMT) == S_IFLNK;
            }else{
                return false;
            }
        }
        /// Whether the stat describes a symbolic link.
        /// Only meaningful for some Posix platforms.
        @property auto issocket(){
            static if(is(typeof({S_ISSOCK;}))){
                return (this.mode & S_IFMT) == S_ISSOCK;
            }else{
                return false;
            }
        }
    }
    
    cstatstruct st;
    
    this(string path){
        cstatstruct st = void;
        version(Windows) auto result = stat(cast(char*) path.ptr, &st);
        else auto result = stat(path.ptr, &st);
        if(result != 0) throw new FileStatException(path, new ErrnoException);
        this(st);
    }
    this(FileHandle file){
        import core.stdc.stdio : fileno;
        cstatstruct st = void;
        auto result = fstat(file.fileno, &st);
        if(result != 0) throw new FileStatException(new ErrnoException);
        this(st);
    }
    this(cstatstruct st){
        this.st = st;
    }
    
    /// Get the permissions on the file.
    @property auto permissions(){
        return this.st.st_mode;
    }
    /// Get the inode.
    @property auto inode(){
        return this.st.st_ino;
    }
    /// Get the device that the file resides on.
    @property auto device(){
        return this.st.st_dev;
    }
    /// Get the user ID.
    @property auto userid(){
        return this.st.st_uid;
    }
    /// Get the group ID.
    @property auto groupid(){
        return this.st.st_gid;
    }
    /// Get the most recent time that the file was accessed.
    @property auto accessedtime(){
        return SysTime.fromUnixTime(this.st.st_atime);
    }
    
    /// Get ctime.
    /// On Unix, represents time of the most recent metadata change.
    /// On Windows, represents file creation time.
    /// Not valid on FAT-formatted drives.
    @property auto ctime(){
        return SysTime.fromUnixTime(this.st.st_ctime);
    }
    
    version(Windows) alias creationtime = ctime;
    else version(Posix) alias changetime = ctime;
    
    /// Get the most recent time that the file's contents were modified.
    @property auto modifiedtime(){
        return SysTime.fromUnixTime(this.st.st_mtime);
    }
    /// Get the number of links to the file.
    @property auto links(){
        return this.st.st_nlink;
    }
    /// Get the size of the file.
    @property auto size(){
        return this.st.st_size;
    }
    
    @property auto mode(){
        return Mode(this.st.st_mode);
    }
}



version(unittest){
    private:
    import std.path;
    import mach.test;
    enum string TestPath = __FILE__.dirName ~ "/stat.txt";
}
unittest{
    tests("Stat", {
        tests("File path", {
            auto st = Stat(TestPath);
            st.permissions;
            st.inode;
            st.device;
            st.userid;
            st.groupid;
            st.accessedtime;
            st.ctime;
            st.modifiedtime;
            st.links;
            version(CRuntime_Microsoft){} else{
                // MSVC libc doesn't correctly support these operations
                testeq(st.size, 85);
                test(st.mode.isfile);
            }
        });
        version(CRuntime_Microsoft){} else tests("Directory path", {
            // MSVC libc doesn't correctly support mode
            auto st = Stat(".");
            test(st.mode.isdir);
        });
        tests("Nonexistent path", {
            testfail({Stat("not a real file path");});
        });
    });
}
