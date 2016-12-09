module mach.text.str.settings;

private:

import mach.traits : Unqual, isRange;
import mach.text.parse.numeric : WriteFloatSettings;

public:



/// Determines which types to include type information for when stringifying.
/// For almost all cases, the default case of None will be preferable as it
/// shows values but never types. Higher levels like Some and All are mainly
/// present for debugging, in case it's important to know specifically what
/// type that values are.
struct StrSettings{
    alias Default = Concise;
    
    static enum TypeDetail: int{
        /// Strings describe value, but not type.
        None = 0,
        /// Strings describe value and type, but not qualifications e.g. `const`.
        Unqual = 1,
        /// Strings describe value and type, including qualifications.
        Full = 2,
    }
    
    string typestring(TypeDetail detail, T)() const{
        static if(detail is TypeDetail.Unqual) return Unqual!T.stringof;
        else static if(detail is TypeDetail.Full) return T.stringof;
        return "";
    }
    string typelabel(T, bool asrange = false)() const{
        string getlabel(){
            static if(is(T == struct)){
                return this.showstructlabel ? "struct:" : "";
            }else static if(is(T == class)){
                return this.showclasslabel ? "class:" : "";
            }else static if(is(T == union)){
                return this.showunionlabel ? "union:" : "";
            }else{
                return "";
            }
        }
        static if(isRange!T){
            return getlabel() ~ "range:";
        }else static if(asrange){
            return getlabel() ~ "asrange:";
        }else{
            return getlabel();
        }
    }
    string typeprefix(
        TypeDetail detail, T, bool label = true, bool asrange = false
    )() const{
        static if(label){
            return this.typelabel!(T, asrange) ~ this.typestring!(detail, T);
        }else{
            return this.typestring!(detail, T);
        }
    }
    
    /// Whether to show type info for enum members.
    TypeDetail showenumtype = TypeDetail.None;
    /// Whether to show type info for pointers.
    TypeDetail showpointertype = TypeDetail.None;
    /// Whether to show type info for integers.
    TypeDetail showintegertype = TypeDetail.None;
    /// Whether to show type info for floats.
    TypeDetail showfloattype = TypeDetail.None;
    /// Whether to show type info for imaginary numbers.
    TypeDetail showimaginarytype = TypeDetail.None;
    /// Whether to show type info for complex numbers.
    TypeDetail showcomplextype = TypeDetail.None;
    /// Whether to show type info for characters.
    TypeDetail showcharactertype = TypeDetail.None;
    /// Whether to show type info for strings.
    TypeDetail showstringtype = TypeDetail.None;
    /// Whether to show type info for string-like iterables.
    TypeDetail showstringliketype = TypeDetail.None;
    /// Whether to show type info for arrays.
    TypeDetail showarraytype = TypeDetail.None;
    /// Whether to show type info for associative arrays.
    TypeDetail showassociativearraytype = TypeDetail.None;
    /// Whether to show type info for iterables.
    TypeDetail showiterabletype = TypeDetail.None;
    /// Whether to show type info for classes.
    TypeDetail showclasstype = TypeDetail.None;
    /// Whether to show type info for structs.
    TypeDetail showstructtype = TypeDetail.None;
    /// Whether to show type info for unions.
    TypeDetail showuniontype = TypeDetail.None;
    
    /// Whether to label strings produced from structs with "struct:".
    bool showstructlabel = false;
    /// Whether to label strings produced from classes with "class:".
    bool showclasslabel = false;
    /// Whether to label strings produced from unions with "union:".
    bool showunionlabel = false;
    /// Whether to label strings produced from ranges with "range:".
    bool showrangelabel = false;
    
    /// Whether to omit surrounding single quotes when a character is passed
    /// directly to `str`.
    bool omitcharquotes = true;
    /// Whether to omit surrounding single quotes when a string is passed
    /// directly to `str`.
    bool omitstringquotes = true;
    
    /// Whether to ignore a `toString` method when it's the default and very
    /// uninformative Object.toString.
    bool ignoreobjecttostring = true;
    /// Whether to show type info when `toString` is used to produce a string.
    TypeDetail showtostringtype = TypeDetail.None;
    /// Whether to show struct, class, and union labels when `toString` is used.
    /// If true, the `showstructlabel`, `showclasslabel`, `showunionlabel`, and
    /// `showrangelabel` flags are used. If false, labels are not shown.
    bool showtostringlabels = false;
    
    /// Whether to stringify the result of `value.asrange` as available, when
    /// the value would otherwise be stringified in the form `{field: value}`.
    bool valueasrange = true;
    
    /// Settings for float stringification.
    WriteFloatSettings floatsettings = {
        PosNaNLiteral: "nan",
        NegNaNLiteral: "-nan",
        PosInfLiteral: "infinity",
        NegInfLiteral: "-infinity",
        trailingfraction: false,
    };
    
    /// Include a minimum of contextual information with stringified values.
    static enum StrSettings Concise = {};
    /// Provide some contextual information for stringified values.
    static enum StrSettings Medium = {
        showenumtype: TypeDetail.Unqual,
        showpointertype: TypeDetail.Unqual,
        showcharactertype: TypeDetail.Unqual,
        showstringtype: TypeDetail.Unqual,
        showstringliketype: TypeDetail.Full,
        showiterabletype: TypeDetail.Full,
        showclasstype: TypeDetail.Full,
        showstructtype: TypeDetail.Full,
        showuniontype: TypeDetail.Full,
        showstructlabel: false,
        showclasslabel: false,
        showunionlabel: true,
        showrangelabel: true,
    };
    /// Provide a lot of contextual information for stringified values.
    static enum StrSettings Verbose = {
        showenumtype: TypeDetail.Unqual,
        showpointertype: TypeDetail.Full,
        showintegertype: TypeDetail.Unqual,
        showfloattype: TypeDetail.Unqual,
        showimaginarytype: TypeDetail.Unqual,
        showcomplextype: TypeDetail.Unqual,
        showcharactertype: TypeDetail.Unqual,
        showstringtype: TypeDetail.Unqual,
        showstringliketype: TypeDetail.Full,
        showarraytype: TypeDetail.Full,
        showassociativearraytype: TypeDetail.Full,
        showiterabletype: TypeDetail.Full,
        showclasstype: TypeDetail.Full,
        showstructtype: TypeDetail.Full,
        showuniontype: TypeDetail.Full,
        showstructlabel: true,
        showclasslabel: true,
        showunionlabel: true,
        showrangelabel: true,
        omitcharquotes: false,
        omitstringquotes: false,
        showtostringtype: TypeDetail.Full,
        showtostringlabels: true,
    };
    /// Provide the maximum amount of contextual information for stringified
    /// values.
    static enum StrSettings Maximum = {
        showenumtype: TypeDetail.Full,
        showpointertype: TypeDetail.Full,
        showintegertype: TypeDetail.Full,
        showfloattype: TypeDetail.Full,
        showimaginarytype: TypeDetail.Full,
        showcomplextype: TypeDetail.Full,
        showcharactertype: TypeDetail.Full,
        showstringtype: TypeDetail.Full,
        showstringliketype: TypeDetail.Full,
        showarraytype: TypeDetail.Full,
        showassociativearraytype: TypeDetail.Full,
        showiterabletype: TypeDetail.Full,
        showclasstype: TypeDetail.Full,
        showstructtype: TypeDetail.Full,
        showuniontype: TypeDetail.Full,
        showstructlabel: true,
        showclasslabel: true,
        showunionlabel: true,
        showrangelabel: true,
        omitcharquotes: false,
        omitstringquotes: false,
        showtostringtype: TypeDetail.Full,
        showtostringlabels: true,
    };
}
