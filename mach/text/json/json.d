module mach.text.json.json;

private:

import mach.text.parse.numeric : WriteFloatSettings;
import mach.text.json.exceptions;
import mach.text.json.attributes;
import mach.text.json.parse;
import mach.text.json.serialize;
import mach.text.json.value;

public:



struct Json{
    /// Type which stores information for a json value.
    static alias Value = JsonValue;
    
    static enum FloatSettings{
        Default = JsonValue.EncodeFloatSettingsDefault,
        Extended = JsonValue.EncodeFloatSettingsExtended,
        Standard = JsonValue.EncodeFloatSettingsStandard
    }
    
    /// Given a value of an arbitrary type, generate a `Json.Value` object.
    static alias serialize = jsonserialize;
    
    /// Given a json string, parse json values.
    static auto parse(
        WriteFloatSettings floatsettings = FloatSettings.Default
    )(in string json){
        return json.parsejson!floatsettings;
    }
    /// Given a json string, parse a value of the given type.
    static auto parse(
        T, WriteFloatSettings floatsettings = FloatSettings.Default
    )(in string json){
        return json.parsejson!floatsettings.jsondeserialize!T;
    }
    
    /// Given a value of an arbitrary type, serialize to compact json.
    static auto encode(
        WriteFloatSettings floatsettings = FloatSettings.Default, T
    )(auto ref T value){
        return value.jsonserialize.encode!floatsettings;
    }
    /// Given a value of an arbitrary type, serialize to pretty-printable json.
    static auto pretty(
        string indent = "  ", WriteFloatSettings floatsettings = FloatSettings.Default, T
    )(auto ref T value){
        return value.jsonserialize.pretty!(indent, floatsettings);
    }
    
    /// UDA which indicates a field should be ignored when serializing json
    /// for a type.
    static alias Skip = JsonSerializeSkip;
    
    // Aliases to common exception classes follow:
    
    /// Base class for json exceptions.
    static alias Exception = JsonException;
    /// Exception thrown when attempting to perform an unsupported operation
    /// on a `Json.Value` object.
    static alias InvalidOperationException = JsonInvalidOperationException;
    /// Exception thrown when failing to parse a json string.
    static alias ParseException = JsonParseException;
    /// Exception thrown when failing to serialize an object to json.
    static alias SerializationException = JsonSerializationException;
    /// Exception thrown when failing to deserialize an object from json.
    static alias DeserializationException = JsonDeserializationException;
}
