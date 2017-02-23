/// This program prints the names of all d files in mach's examples directory.

import mach.io : Path, stdio;

void main(){
    // Get the directory containing the one containing this file:
    // that's mach's examples directory.
    auto here = Path(__FILE_FULL_PATH__).directory.directory;
    // Enumerate all the files in directories and subdirectories...
    foreach(file; here.traversedir){
        if(file.path.extension == "d"){ // If it's a D source file, print it!
            stdio.writeln("Found an example: ", file.name);
        }
    }
}
