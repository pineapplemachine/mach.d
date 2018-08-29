module mach.io.file.filesidentical;

private:

import mach.io.stream.filestream : FileStream;

public:

/// Data structure returned by a call to filesidentical
struct FilesIdenticalResult {
    /// Whether the files had any difference
    bool identical;
    /// The byte offset in the files where the first different byte was found
    size_t offset;
    
    alias identical this;
    
    bool opCast(T: bool)(){
        return this.identical;
    }
}

/// Returns a truthy value when the files at two paths both exist and have
/// identical byte content. Returns a falsey value if either file could not
/// be opened, or if any bytes differ.
/// Specifically, the function returns a FilesIdenticalResult.
FilesIdenticalResult filesidentical(in string path0, in string path1){
    FileStream file0 = FileStream(path0, "rb");
    FileStream file1 = FileStream(path1, "rb");
    return filesidentical(file0, file1);
}

/// Returns a truthy value when two file streams contain identical content.
/// Returns a falsey value when any content is different, or when either
/// file stream is not valid, e.g. due to a failure opening that file.
/// Specifically, the function returns a FilesIdenticalResult.
FilesIdenticalResult filesidentical(FileStream file0, FileStream file1){
    if(!file0.active || !file1.active){
        return FilesIdenticalResult(false, 0);
    }
    size_t offset = 0;
    ubyte[16] buffer0;
    ubyte[16] buffer1;
    while(true){
        const count0 = file0.readbufferv(buffer0.ptr, 1, buffer0.length);
        const count1 = file1.readbufferv(buffer1.ptr, 1, buffer1.length);
        if(count0 < count1){
            return FilesIdenticalResult(false, offset + count0);
        }
        else if(count0 > count1){
            return FilesIdenticalResult(false, offset + count1);
        }
        for(size_t i = 0; i < buffer0.length; i++){
            if(buffer0[i] != buffer1[i]){
                return FilesIdenticalResult(false, offset + i);
            }
        }
        if(count0 < buffer0.length){
            break;
        }
        offset += buffer0.length;
    }
    return FilesIdenticalResult(true, 0);
}

unittest {
    // TODO
}
