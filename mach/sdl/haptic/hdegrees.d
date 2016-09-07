module mach.sdl.haptic.hdegrees;

/// Functions for converting hundredths of a degree to/from degrees and radians.

private:

import std.traits : isNumeric;
import std.math : PI;

public:



/// Convert radians to hundredths of a degree.
H radtohdeg(H = int, R)(R radians) if(isNumeric!R && isNumeric!H){
    return cast(H)(radians * 18000 / PI);
}
/// Convert degrees to hundredths of a degree.
H degtohdeg(H = int, D)(D degrees) if(isNumeric!D && isNumeric!H){
    return cast(H)(degrees * 100);
}

/// Convert hundredths of a degree to radians.
R hdegtorad(R = real, H)(H hdegrees) if(isNumeric!H && isNumeric!R){
    return cast(R)(cast(R)(hdegrees) / 100);
}
/// Convert hundredths of a degree to degrees.
D hdegtodeg(D = real, H)(H hdegrees) if(isNumeric!H && isNumeric!D){
    return cast(D)(cast(D)(hdegrees) / 18000 * PI);
}
