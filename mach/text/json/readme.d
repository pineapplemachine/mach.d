module mach.text.json.readme;

private:

import mach.text.json;

/++ md

# mach.text.json

This package provides functionality for serializing and deserializing values
as json.

The `Json` namespace provides several methods for achieving the most common functions.

## `Json.parse`

This method can be used to parse a Json.Value object, or to deserialize another
object of a given type.

A `Json.ParseException` is thrown when the inputted json is invalid.

+/

unittest{
    Json.Value value = Json.parse(`{"hello": "world"}`);
    assert(value.length == 1);
    assert(value["hello"] == "world");
}

unittest{
    string[string] array = Json.parse!(string[string])(`{"hello": "world"}`);
    assert(array.length == 1);
    assert(array["hello"] == "world");
}

unittest{
    bool caught = false;
    try{
        Json.parse(`{"Invalid": "json",,,}`);
    }catch(Json.ParseException){
        caught = true;
    }
    assert(caught);
}

/++ md

## `Json.encode`

This method can be used to serialize a value as json.
The output is as concise as possible.

+/

unittest{
    assert(Json.encode(100) == `100`);
    assert(Json.encode([1, 2, 3]) == `[1,2,3]`);
    assert(Json.encode(["hello": "world"]) == `{"hello":"world"}`);
}

/++ md

## `Json.pretty`

This method can be used to serialize a value as human-readable json,
similar to `Json.encode`.

+/

unittest{
    assert(Json.pretty([1, 2, 3]) == `[1, 2, 3]`);
}

/++ md

## All together now

``` D
// Type to be serialized and deserialized
struct Test{
    string hello;
    string how;
    int number;
}
Test test = {
    hello: "world",
    how: "are you",
    number: 10
};
// Get a human-readable json string
string json = Json.pretty(test);
assert(json == `{
  "hello": "world",
  "how": "are you",
  "number": 10
}`);
// Parse a Test object back from the string
auto parsed = Json.parse!Test(json);
assert(parsed == test);
```

+/

// Json string comparison forces this weird formatting, and I would like to
// formally apologize to my readme-making tool
 unittest{
// Type to be serialized and deserialized
struct Test{
    string hello;
    string how;
    int number;
}
Test test = {
    hello: "world",
    how: "are you",
    number: 10
};
// Get a human-readable json string
string json = Json.pretty(test);
assert(json == `{
  "hello": "world",
  "how": "are you",
  "number": 10
}`);
// Parse a Test object back from the string
auto parsed = Json.parse!Test(json);
assert(parsed == test);
}
