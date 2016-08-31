module mach.io.file.stat;

private:

import std.datetime : SysTime; // TODO: Ewww, this module. I should write my own

public:

import mach.io.file.sys : Stat;



// References:
// http://codewiki.wikidot.com/c:struct-stat
// http://cboard.cprogramming.com/c-programming/91931-difference-between-st_atime-st_mtime-st_ctime.html
// https://mail.python.org/pipermail/python-list/2012-September/632015.html
// https://mail.python.org/pipermail/python-list/2012-September/632124.html



/// Get the permissions on a file given the result of an fstat call.
auto permissions(Stat stat){
    return stat.st_mode;
}
/// Get the inode of a file given the result of an fstat call.
auto inode(Stat stat){
    return stat.st_ino;
}
/// Get the device that a file resides on given the result of an fstat call.
auto device(Stat stat){
    return stat.st_dev;
}
/// Get the user ID for a file given the result of an fstat call.
auto userid(Stat stat){
    return stat.st_uid;
}
/// Get the group ID for a file given the result of an fstat call.
auto groupid(Stat stat){
    return stat.st_gid;
}
/// Get the most recent time that a file was accessed given the result of an
/// fstat call.
auto accessedtime(Stat stat){
    return SysTime.fromUnixTime(stat.st_atime);
}
/// Get ctime for a file given the result of an fstat call.
/// On Unix, represents time of the most recent metadata change.
/// On Windows, represents file creation time.
/// Not valid on FAT-formatted drives.
auto ctime(Stat stat){
    return SysTime.fromUnixTime(stat.st_ctime);
}
version(Windows) alias creationtime = ctime;
else version(Posix) alias changetime = ctime;
/// Get the most recent time that a file's contents were modified given the
/// result of an fstat call.
auto modifiedtime(Stat stat){
    return SysTime.fromUnixTime(stat.st_mtime);
}
/// Get the number of links to a file given the result of an fstat call.
auto links(Stat stat){
    return stat.st_nlink;
}
/// Get the size of a file given the result of an fstat call.
auto size(Stat stat){
    return stat.st_size;
}



version(unittest){
    private:
    import std.path;
    import mach.error.unit;
    import mach.io.file.sys : dstat;
    enum string TestPath = __FILE__.dirName ~ "/stat.txt";
}
unittest{
    tests("Stat", {
        auto stat = dstat(TestPath);
        stat.permissions;
        stat.inode;
        stat.device;
        stat.userid;
        stat.groupid;
        stat.accessedtime;
        stat.ctime;
        stat.modifiedtime;
        stat.links;
        testeq(stat.size, 86);
    });
}
