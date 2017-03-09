// This script reads a json file, modifies it, and writes the modified json
// to another file path.

import mach.json : Json;
import mach.io.file : Path;
import mach.io.stdio : stdio;

void main(){
    // First, read and parse json content.
    // Though the mach.json package is able to serialize and deserialize values,
    // this program uses an unstructured representation via the Json.Value type.
    auto input = Json.parsefile("input.json");
    stdio.writeln("Read json from input file: ", input.encode);
    
    // Now modify the parsed json.
    input["hello"] = "WORLD"; // Make "world" upper case.
    input["I am"] = "FINE"; // Change from number to string.
    input["another"] = ["k", "e", "y"]; // Add a new key to the output,
    input.remove("how"); // And remove a key as well.
    
    // Then write the modified content to a file.
    stdio.writeln("Writing json to output file...");
    Json.writefile("output.json", input);
    
    // Finally, read and print the content of that file.
    stdio.writeln("Content of written file: ", Path("output.json").readall());
}
