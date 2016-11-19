module mach.text.json.literals;

private:

//

public:



/// The json spec does not allow for numeric literals not representable
/// as a sequence of digits.
/// This is the default setting for dealing with those literals.
/// When false, NaN and +/- inf are encoded as null.
/// When true, they are encoded using NaN, Infinite, and -Infinite.
static enum bool FloatLiteralsDefault = true;

/// Representation of null value.
static enum string NullLiteral = "null";
/// Representation of true boolean value.
static enum string TrueLiteral = "true";
/// Representation of false boolean value.
static enum string FalseLiteral = "false";
/// Representation of NaN numeric literal,
/// if such divergence from the spec is allowed.
static enum string NaNLiteral = "NaN";
/// Representation of +inf numeric literal,
/// if such divergence from the spec is allowed.
static enum string PosInfLiteral = "Infinite";
/// Representation of -inf numeric literal,
/// if such divergence from the spec is allowed.
static enum string NegInfLiteral = "-Infinite";
