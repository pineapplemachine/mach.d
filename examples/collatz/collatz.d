/// This program asks the user to input a number, and then prints the
/// Collatz sequence of that number.

import mach.io : stdio;
import mach.text : parsenumber;

void main(){
    // Get user input, and keep retrying until the user inputs something valid.
    stdio.writeln("Print the collatz sequence of what number?");
    uint number = 0;
    bool success = false;
    while(!success){
        bool exception = false;
        auto input = stdio.readln();
        try{
            number = input.parsenumber!uint;
        }catch(Exception e){
            stdio.writeln("I'm sorry, I couldn't understand your input. Try again?");
            exception = true;
        }
        if(!exception && number != 0){
            success = true;
        }else{
            stdio.writeln("Please input an integer greater than zero.");
        }
    }
    // Compute and output the Collatz sequence.
    stdio.write("Collatz sequence: ", number);
    while(number != 1){
        if(number % 2 == 0){
            number /= 2;
        }else{
            number = number * 3 + 1;
        }
        stdio.write(", ", number);
    }
    stdio.writeln();
}
