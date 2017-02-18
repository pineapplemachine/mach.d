module mach.math.trig.rotdirection;

private:

/++ Docs

This module defines a `RotationDirection` enum with `Clockwise`,
`Counterclockwise`, and `None` members.

+/

public:



enum RotationDirection: int{
    Clockwise = 1,
    Counterclockwise = -1,
    None = 0
}
