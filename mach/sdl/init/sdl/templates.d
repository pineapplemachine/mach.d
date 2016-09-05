module mach.sdl.init.sdl.templates;

private:

//

public:



/// Used to construct bitmask wrapper types.
template InitOptionAggregate(size_t bits, Flags, Option){
    import mach.math.bits : hamming;
    static struct InitOptionAggregate{
        static enum All = typeof(this)(Option.All);
        static enum Default = typeof(this)(Option.Default);
        Flags flags;
        /// True when no flags are true.
        @property bool empty() const{
            return this.flags == 0;
        }
        /// Get the number of true flags.
        @property auto length() const{
            return this.flags.hamming;
        }
        /// Set a flag to true.
        void add(in const(Option)[] options...){
            foreach(option; options) this.flags |= option;
        }
        /// Set a flag to false.
        void remove(in const(Option)[] options...){
            foreach(option; options) this.flags &= ~option;
        }
        /// Get whether a flag is set.
        bool contains(in Option option) const{
            return (this.flags & option) != 0;
        }
        /// ditto
        bool opBinaryRight(string op: "in")(in Option option) const{
            return this.contains(option);
        }
    }
}
