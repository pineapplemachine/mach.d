module mach.collect.hashmap.exceptions;

private:

//

public:



/// Error thrown when insertion into a map or set fails because it is full.
class DenseHashMapFullError: Error{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Cannot add value because the map is already full.", file, line, null);
    }
}

/// Error thrown when retrieval from a map fails because a key does not exist therein.
class DenseHashMapKeyError: Error{
    this(size_t line = __LINE__, string file = __FILE__){
        super("Key does not exist in map.", file, line, null);
    }
}
