module mach.math.constants;

private:

/++ Docs

This module defines some mathematical constants, including `e`, `pi`, `tau`,
`sqrt2`, and `GoldenRatio`.

+/

public:



/// Euler's number, approximately 2.71828.
/// https://en.wikipedia.org/wiki/E_(mathematical_constant)
enum real e = 2.718281828459045235360287471352662497757247093699959574966L;

/// Pi, approximately 3.14159.
enum real pi = 0x1.921fb54442d1846ap+1L;
/// ditto
alias π = pi;

/// Pi/2, approximately 1.57079.
enum real halfpi = 0x1.921fb54442d1846ap0L;

/// Pi/4, approximately 0.78539.
enum real quarterpi = 0x1.921fb54442d1846ap-1L;

/// Tau, or 2π, approximately 6.28315.
/// https://en.wikipedia.org/wiki/Turn_(geometry)#Tau_proposal
enum real tau = 6.283185307179586476925286766559005768394338798750211641949L;
/// ditto
alias τ = tau;

/// Pythagoras' constant, or the square root of two, approximately 1.41421.
/// https://en.wikipedia.org/wiki/Square_root_of_2
enum real sqrt2 = 1.414213562373095048801688724209698078569671875376948073176L;

/// The golden ratio, approximately 1.61803.
/// https://en.wikipedia.org/wiki/Golden_ratio
enum real GoldenRatio = 1.618033988749894848204586834365638117720309179805762862135L;
/// ditto
alias φ = GoldenRatio;
