/// Evaluate the json parser's behavior for the inputs graciously provided
/// by Nicolas Seriot here: https://github.com/nst/JSONTestSuite
/// A perfectly behaving parser should accept all input files beginning with
/// 'y', should gracefully reject all input files beginning with 'n', 
/// and is permitted to either accept or reject input files beginning with 'i',
/// but should at the very least not crash while trying to parse them.

import mach.json : Json;
import mach.text : text;
import mach.io.stream : asarray, StdOutStream, write;
import mach.io.file.path : Path;
import mach.io.file.traverse : listdir;

void log(Args...)(Args args){
    StdOutStream().write(text(args, "\n"));
}

void main(){
    size_t total = 0;
    size_t success = 0;
    size_t failure_on_valid = 0;
    size_t accepted_invalid = 0;
    foreach(file; listdir("inputs")){
        auto json = cast(string) Path(file.path).readall();
        Throwable exception = null;
        Json.ParseException jsonexception = null;
        log("Testing: ", file.name);
        try{
            Json.parse!(Json.FloatSettings.Standard)(json);
        }catch(Json.ParseException e){
            jsonexception = e;
        }catch(Throwable e){
            exception = e;
        }
        if(exception){
            log("Unhandled error evaluating ", file.name, ": ", exception);
            break;
        }
        if(file.name[0] == 'y'){
            if(jsonexception is null){
                log("SUCCESS: ", file.name);
                success++;
            }else{
                log("REJECTED VALID: ", file.name);
                failure_on_valid++;
            }
        }else if(file.name[0] == 'n'){
            if(jsonexception !is null){
                log("SUCCESS: ", file.name);
                success++;
            }else{
                log("ACCEPTED INVALID: ", file.name);
                accepted_invalid++;
            }
        }else{
            success++;
        }
        total++;
    }
    log("Results (Total ", total, " tests):");
    log("Successes: ", success);
    log("Rejected valid: ", failure_on_valid);
    log("Accepted invalid: ", accepted_invalid);
}
