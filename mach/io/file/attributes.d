module mach.io.file.attributes;

private:

version(Windows){
    import core.sys.windows.winbase : GetFileAttributesW;
    import core.sys.windows.windows : DWORD;
    import core.sys.windows.winnt;
}

import std.internal.cstring : tempCString;
import mach.io.file.common;

public:



/// https://msdn.microsoft.com/en-us/library/windows/desktop/gg258117(v=vs.85).aspx
version(Windows){
    struct Attributes{
        alias Attr = DWORD;
        
        Attr attr;
        
        this(string path){
            this(GetFileAttributesW(path.tempCString!FSChar()));
        }
        this(Attr attr){
            this.attr = attr;
        }
        
        @property bool valid() const{
            return this.attr != INVALID_FILE_ATTRIBUTES;
        }
        
        /// Get whether the file or directory is an archive, typically used to mark
        /// files for backup or removal.
        @property bool isarchive() const{
            return (this.attr & FILE_ATTRIBUTE_ARCHIVE) != 0;
        }
        /// Set whether the file or directory is an archive, typically used to mark
        /// files for backup or removal.
        @property void isarchive(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_ARCHIVE;
            else this.attr |= FILE_ATTRIBUTE_ARCHIVE;
        }
        /// Get whether the file or directory is compressed.
        @property bool iscompressed() const{
            return (this.attr & FILE_ATTRIBUTE_COMPRESSED) != 0;
        }
        /// Set whether the file or directory is compressed.
        @property void iscompressed(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_COMPRESSED;
            else this.attr |= FILE_ATTRIBUTE_COMPRESSED;
        }
        /// Reserved for system use, per Windows docs.
        @property bool isdevice() const{
            return (this.attr & FILE_ATTRIBUTE_DEVICE) != 0;
        }
        /// ditto
        @property void isdevice(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_DEVICE;
            else this.attr |= FILE_ATTRIBUTE_DEVICE;
        }
        /// Get whether the handle identifies a directory.
        @property bool isdir() const{
            return (this.attr & FILE_ATTRIBUTE_DIRECTORY) != 0;
        }
        /// Set whether the handle identifies a directory.
        @property void isdir(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_DIRECTORY;
            else this.attr |= FILE_ATTRIBUTE_DIRECTORY;
        }
        /// Get whether the handle identifies a file.
        /// Is the same as not(isdir).
        @property bool isfile() const{
            return (this.attr & FILE_ATTRIBUTE_DIRECTORY) == 0;
        }
        /// Set whether the handle identifies a file.
        /// Is the same as not(isdir).
        @property void isfile(in bool value){
            if(!value) this.attr |= FILE_ATTRIBUTE_DIRECTORY;
            else this.attr &= ~FILE_ATTRIBUTE_DIRECTORY;
        }
        /// Get whether the file or directory is encrypted.
        @property bool isencrypted() const{
            return (this.attr & FILE_ATTRIBUTE_ENCRYPTED) != 0;
        }
        /// Set whether the file or directory is encrypted.
        @property void isencrypted(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_ENCRYPTED;
            else this.attr |= FILE_ATTRIBUTE_ENCRYPTED;
        }
        /// Get whether the file or directory is hidden, meaning it is not included
        /// in an ordinary directory listing.
        @property bool ishidden() const{
            return (this.attr & FILE_ATTRIBUTE_HIDDEN) != 0;
        }
        /// Set whether the file or directory is hidden, meaning it is not included
        /// in an ordinary directory listing.
        @property void ishidden(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_HIDDEN;
            else this.attr |= FILE_ATTRIBUTE_HIDDEN;
        }
        /// Get whether the file does not have other attributes set.
        @property bool isnormal() const{
            return (this.attr & FILE_ATTRIBUTE_NORMAL) != 0;
        }
        /// Set whether the file does not have other attributes set.
        @property void isnormal(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_NORMAL;
            else this.attr |= FILE_ATTRIBUTE_NORMAL;
        }
        /// Get whether the file or directory is indexed by the content indexing
        /// service.
        @property bool isindexed() const{
            return (this.attr & FILE_ATTRIBUTE_NOT_CONTENT_INDEXED) == 0;
        }
        /// Set whether the file or directory is indexed by the content indexing
        /// service.
        @property void isindexed(in bool value){
            if(!value) this.attr &= ~FILE_ATTRIBUTE_NOT_CONTENT_INDEXED;
            else this.attr |= FILE_ATTRIBUTE_NOT_CONTENT_INDEXED;
        }
        /// Get whether data of the file is not available immediately because the
        /// data was physically moved to offline storage. The attribute is used by
        /// Remote Storage and applications should not arbitrarily change this
        /// attribute.
        @property bool isoffline() const{
            return (this.attr & FILE_ATTRIBUTE_OFFLINE) != 0;
        }
        /// Get whether data of the file is not available immediately because the
        /// data was physically moved to offline storage. The attribute is used by
        /// Remote Storage and applications should not arbitrarily change this
        /// attribute.
        @property void isoffline(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_OFFLINE;
            else this.attr |= FILE_ATTRIBUTE_OFFLINE;
        }
        /// Get whether the file is read-only. This attribute is not honored for
        /// directories.
        @property bool isreadonly() const{
            return (this.attr & FILE_ATTRIBUTE_READONLY) != 0;
        }
        /// Set whether the file is read-only. This attribute is not honored for
        /// directories.
        @property void isreadonly(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_READONLY;
            else this.attr |= FILE_ATTRIBUTE_READONLY;
        }
        /// Get whether the handle identifies a file or directory having an
        /// associated reparse point, or a file that is a symbolic link.
        @property bool islink() const{
            return (this.attr & FILE_ATTRIBUTE_REPARSE_POINT) != 0;
        }
        /// Set whether the handle identifies a file or directory having an
        /// associated reparse point, or a file that is a symbolic link.
        @property void islink(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_REPARSE_POINT;
            else this.attr |= FILE_ATTRIBUTE_REPARSE_POINT;
        }
        /// Get whether the file is a sparse file.
        @property bool issparse() const{
            return (this.attr & FILE_ATTRIBUTE_SPARSE_FILE) != 0;
        }
        /// Set whether the file is a sparse file.
        @property void issparse(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_SPARSE_FILE;
            else this.attr |= FILE_ATTRIBUTE_SPARSE_FILE;
        }
        /// Get whether the file or directory is used partially or exclusively by
        /// the operating system.
        @property bool issystem() const{
            return (this.attr & FILE_ATTRIBUTE_SYSTEM) != 0;
        }
        /// Set whether the file or directory is used partially or exclusively by
        /// the operating system.
        @property void issystem(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_SYSTEM;
            else this.attr |= FILE_ATTRIBUTE_SYSTEM;
        }
        /// Get whether the file is being used for temporary storage and is
        /// expected to not be persisted and to be imminently closed.
        @property bool istemporary() const{
            return (this.attr & FILE_ATTRIBUTE_TEMPORARY) != 0;
        }
        /// Set whether the file is being used for temporary storage and is
        /// expected to not be persisted and to be imminently closed.
        @property void istemporary(in bool value){
            if(value) this.attr &= ~FILE_ATTRIBUTE_TEMPORARY;
            else this.attr |= FILE_ATTRIBUTE_TEMPORARY;
        }
    }
}else{
    struct Attributes{
        this(Args...)(auto ref Args args){
            assert(false, "Operation only meaningful on Windows platforms.");
        }
        void opDispatch(string name)(){
            assert(false, "Operation only meaningful on Windows platforms.");
        }
    }
}
