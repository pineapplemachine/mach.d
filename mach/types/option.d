module mach.types.option;

private:

/++ Docs

This module implements an Option type, sometimes called an Optional or Maybe type.
The implemented `Option` type contains either no value or one value.

+/

unittest{ /// Example
    auto option = Option!int(123);
    assert(option.ok);
    assert(!option.empty);
    assert(option.value == 123);
}

unittest{ /// Example
    // Accessing `option.value` would produce an assertion error
    auto option = Option!int.None;
    assert(!option.ok);
    assert(option.empty);
    // Get value with fallback
    assert(option.get(900) == 900);
}

/++ Docs

The module additionally provides the `None` and `Some` helpers, which
allow for more concise expressions related to creating `Option` objects.

+/

unittest { /// Example
    auto option = Some("Hello world!");
    assert(option.value == "Hello world!");
}

unittest { /// Example
    auto option = None!string;
    assert(option.empty);
}

/++ Docs

`Option` objects are valid as ranges, which means that you can use them
easily in combination with mach's range-related functions such as `filter`
or `map`.

+/

unittest { /// Example
    auto range = Some(500).asrange;
    foreach(i; range) {
        assert(i == 500);
    }
}

unittest { /// Example
    auto range = None!int.asrange;
    foreach(i; range) {
        assert(false); // Range is empty
    }
}

public:

/// Get an Option of the given type, containing no value.
/// TODO: Would be nice if the type didn't have to be explicitly given
enum None(T) = Option!T.None;

/// Return an Option containing the given value.
auto Some(T)(auto ref T value) {
    return Option!T(value);
}

/// Represents an optional value.
struct Option(T) {
    /// Reference to the empty Option.
    static enum None = typeof(this).init;
    static assert(typeof(this).None.empty); // Sanity check
    
    /// Expose reference to template parameter
    alias Value = value;
    
    /// The value contained by the Option, if the Option isn't empty.
    T content;
    /// Indicate whether the Option has a value or not.
    bool empty = true;
    
    /// Create an Option containing a given value.
    this(T content, in bool empty = false) {
        this.content = content;
        this.empty = empty;
    }
    
    /// Return true when the Option contains a value and false otherwise.
    @property bool ok() const {
        return !this.empty;
    }
    
    /// Get an OptionRange for enumerating the option's content.
    @property auto asrange() inout {
        return OptionRange!T(this.content, this.empty);
    }
    
    /// Get the value of the option.
    /// Produces an assertion error if the option had no value.
    @property ref inout(T) value() inout {
        assert(!this.empty);
        return this.content;
    }
    
    /// Get the value of the option if it has one, otherwise get the fallback.
    inout(T) get(inout(T) fallback) inout {
        return this.empty ? fallback : this.content;
    }
    /// Ditto
    ref inout(T) get(ref inout(T) fallback) inout {
        return this.empty ? fallback : this.content;
    }
    
    /// Cast to boolean. Returns true if not empty and false otherwise.
    bool opCast(To: bool)() const {
        return !this.empty;
    }
}

/// Range for enumerating the zero or one element in an Option object.
struct OptionRange(T) {
    /// Content of the basis Option for this range, i.e. the contained value
    T content;
    /// Basis Option for this range was empty?
    bool optionEmpty = true;
    /// Whether this range has been popped yet
    bool popped = false;
    
    /// Make a range based on the properties of an Option
    this(T content, in bool optionEmpty = false, in bool popped = false) {
        this.content = content;
        this.popped = popped;
        this.optionEmpty = optionEmpty;
    }
    
    /// Get an Option containing the same information as whatever Option
    /// used to construct the range.
    auto option() inout {
        return Option!T(this.content, this.optionEmpty);
    }
    
    /// Returns 1 when the Option was not empty. Returns 0 otherwise.
    alias opDollar = this.length;
    
    /// Ditto
    size_t length() const {
        return this.optionEmpty ? 0 : 1;
    }
    
    size_t remaining() const {
        return this.popped || this.optionEmpty ? 0 : 1;
    }
    
    bool empty() const {
        return this.popped || this.optionEmpty;
    }
    
    ref inout(T) front() inout {
        assert(!this.optionEmpty && !this.popped);
        return this.content;
    }
    
    ref inout(T) back() inout {
        assert(!this.optionEmpty && !this.popped);
        return this.content;
    }
    
    void popFront() {
        assert(!this.optionEmpty && !this.popped);
        this.popped = true;
    }
    
    void popBack() {
        assert(!this.optionEmpty && !this.popped);
        this.popped = true;
    }
    
    auto save() {
        if(this.optionEmpty) return typeof(this).init;
        else return typeof(this)(this.content, false, this.popped);
    }
}



version(unittest) Option!int syntaxExample(in bool ok) {
    if(ok) {
        return Some(1);
    }else {
        return None!int;
    }
}

unittest { /// Basic syntax example
    assert(syntaxExample(true).value == 1);
    assert(syntaxExample(false).empty);
}

unittest { /// Properties of empty Option
    auto option = Option!double.None;
    assert(option.empty);
    assert(!option.ok);
    assert(!cast(bool) option);
    assert(option.get(20) == 20);
}

unittest { /// Properties of non-empty Option
    auto option = Option!double(10);
    assert(!option.empty);
    assert(option.ok);
    assert(cast(bool) option);
    assert(option.get(20) == 10);
}

unittest { /// Empty Option as range
    auto range = Option!int.None.asrange;
    assert(range.empty);
    assert(range.length == 0);
    assert(range.remaining == 0);
}

unittest { /// Non-empty Option as range
    auto range = Option!int(500).asrange;
    assert(!range.empty);
    assert(range.length == 1);
    assert(range.remaining == 1);
    assert(range.front == 500);
    assert(range.back == 500);
    range.popFront();
    assert(range.empty);
    assert(range.length == 1);
    assert(range.remaining == 0);
}
