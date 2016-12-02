module mach.text.str.settings;

private:

//

public:



/// Determines which types to include type information for when stringifying.
/// For almost all cases, the default case of None will be preferable as it
/// shows values but never types. Higher levels like Some and All are mainly
/// present for debugging, in case it's important to know specifically what
/// type that values are.
struct StrSettings{
    alias Default = Concise;
    
    /// Whether to show type info for enum members.
    bool enums = false;
    /// Whether to show type info for pointers.
    bool pointers = false;
    /// Whether to show type info for integers.
    bool integers = false;
    /// Whether to show type info for floats.
    bool floats = false;
    /// Whether to show type info for imaginary numbers.
    bool imaginary = false;
    /// Whether to show type info for complex numbers.
    bool complex = false;
    /// Whether to show type info for characters.
    bool characters = false;
    /// Whether to show type info for strings.
    bool strings = false;
    /// Whether to show type info for arrays.
    bool arrays = false;
    /// Whether to show type info for associative arrays.
    bool associativearrays = false;
    /// Whether to show type info for iterables.
    bool iterables = false;
    /// Whether to show type info for classes.
    bool classes = false;
    /// Whether to show type info for structs.
    bool structs = false;
    /// Whether to show type info for unions.
    bool unions = false;
    
    /// Include type info for no values.
    static enum StrSettings Concise = {};
    /// Include type info for a few values, where type might otherwise be
    /// especially ambiguous.
    static enum StrSettings Medium = {
        enums: true,
        pointers: true,
        characters: true,
        strings: true,
        iterables: true,
        classes: true,
        structs: true,
        unions: true,
    };
    /// Include type info for all values where it is meaningful.
    static enum StrSettings Verbose = {
        enums: true,
        pointers: true,
        integers: true,
        floats: true,
        imaginary: true,
        complex: true,
        characters: true,
        strings: true,
        arrays: true,
        associativearrays: true,
        iterables: true,
        classes: true,
        structs: true,
        unions: true,
    };
}
