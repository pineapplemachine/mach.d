# mach.io.file


This package provides functionality for dealing with the file system.


## mach.io.file.file


This module is deprecated. Please use `mach.io.file.path` instead.


## mach.io.file.path


The `Path` type may be used to perform actions and manipulations with file paths.
An instance should be created simply by calling the constructor with some string
representing a file path.

``` D
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
```


Also supported are `copy`, `rename`, and `remove` methods.

``` D
auto path = Path(__FILE_FULL_PATH__); // .../mach/io/file/path.d
auto copy = path.copy(path ~ ".unittest.copied");
auto renamed = copy.rename(path ~ ".unittest.renamed");
renamed.remove();
assert(!renamed.exists);
```


