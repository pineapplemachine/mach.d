module mach.io.file.stat;

private:

import std.datetime : SysTime; // TODO: Ewww, this.st module. I should write my own
import mach.error : ErrnoException;
import mach.io.file.common;

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
        @property auto isfile() const{
            return (this.mode & S_IFMT) == S_IFREG;
        }
        /// Whether the stat describes a directory.
        @property auto isdir() const{
            return (this.mode & S_IFMT) == S_IFDIR;
        }
        /// Whether the stat describes a character device.
        @property auto ischar() const{
            return (this.mode & S_IFMT) == S_IFDIR;
        }
        /// Whether the stat describes a block device.
        @property auto isblock() const{
            return (this.mode & S_IFMT) == S_IFDIR;
        }
        /// Whether the stat describes a named pipe.
        @property auto isfifo() const{
            version(Windows){
                // Not 100% sure this is correct but docs are proving scarce
                return (this.mode & S_IFMT) == S_IFNAM;
            }else{
                return (this.mode & S_IFMT) == S_IFIFO;
            }
        }
        /// Whether the stat describes a symbolic link.
        /// Only meaningful for some Posix platforms.
        @property auto islink() const{
            static if(is(typeof({S_IFLNK;}))){
                return (this.mode & S_IFMT) == S_IFLNK;
            }else{
                return false;
            }
        }
        /// Whether the stat describes a symbolic link.
        /// Only meaningful for some Posix platforms.
        @property auto issocket() const{
            static if(is(typeof({S_ISSOCK;}))){
                return (this.mode & S_IFMT) == S_ISSOCK;
            }else{
                return false;
            }
        }
    }
    
    cstatstruct st;
    bool valid = false;
    
    this(string path){
        cstatstruct st = void;
        version(Windows) auto result = stat(cast(char*) path.ptr, &st);
        else auto result = stat(path.ptr, &st);
        this(st, result == 0);
    }
    this(FileHandle file){
        import core.stdc.stdio : fileno;
        cstatstruct st = void;
        auto result = fstat(file.fileno, &st);
        this(st, result == 0);
    }
    this(cstatstruct st, bool valid = true){
        this.st = st;
        this.valid = valid;
    }
    
    /// Get the permissions on the file.
    @property auto permissions() const{
        return this.st.st_mode;
    }
    /// Get the inode.
    @property auto inode() const{
        return this.st.st_ino;
    }
    /// Get the device that the file resides on.
    @property auto device() const{
        return this.st.st_dev;
    }
    /// Get the user ID.
    @property auto userid() const{
        return this.st.st_uid;
    }
    /// Get the group ID.
    @property auto groupid() const{
        return this.st.st_gid;
    }
    /// Get the most recent time that the file was accessed.
    @property auto accessedtime() const{
        return SysTime.fromUnixTime(this.st.st_atime);
    }
    
    /// Get ctime.
    /// On Unix, represents time of the most recent metadata change.
    /// On Windows, represents file creation time.
    /// Not valid on FAT-formatted drives.
    @property auto ctime() const{
        return SysTime.fromUnixTime(this.st.st_ctime);
    }
    
    version(Windows) alias creationtime = ctime;
    else version(Posix) alias changetime = ctime;
    
    /// Get the most recent time that the file's contents were modified.
    @property auto modifiedtime() const{
        return SysTime.fromUnixTime(this.st.st_mtime);
    }
    /// Get the number of links to the file.
    @property auto links() const{
        return this.st.st_nlink;
    }
    /// Get the size of the file.
    @property auto size() const{
        return this.st.st_size;
    }
    
    @property auto mode() const{
        return Mode(this.st.st_mode);
    }
}



version(unittest){
    private:
    import std.path;
    import mach.test;
    enum string TestPath = __FILE_FULL_PATH__.dirName ~ "/stat.txt";
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
            testf(Stat("not a real file path").valid);
        });
    });
}
