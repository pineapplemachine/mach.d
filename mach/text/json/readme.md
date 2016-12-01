# mach.text.json

This package provides functionality for serializing and deserializing values as json.

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
