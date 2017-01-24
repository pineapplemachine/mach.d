/// This program prints the lyrics of "99 Bottles of Beer" to the console.

import mach.io : stdio;

void main(){
    uint bottles = 99;
    while(bottles > 0){
        stdio.writeln(bottles, " bottles of beer on the wall, ", bottles, " bottles of beer!");
        bottles--;
        if(bottles > 0){
            stdio.writeln("Take one down, pass it around, ", bottles, " bottles of beer on the wall!");
        }else{
            stdio.writeln("Take one down, pass it around, no more bottles of beer on the wall!");
        }
    }
    stdio.writeln("No more bottles of beer on the wall, no more bottles of beer!");
    stdio.writeln("Go to the store and buy some more, 99 bottles of beer on the wall!");
}
