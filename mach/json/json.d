module mach.json.json;

private:

import mach.traits : isString, Unqual;
import mach.text.numeric : WriteFloatSettings;
import mach.io.file.path : Path;
import mach.io.file.exceptions : FileException;
import mach.io.stream.exceptions : StreamException;
import mach.json.exceptions;
import mach.json.attributes;
import mach.json.parse;
import mach.json.serialize;
import mach.json.value;

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
    /// Given a `Json.Value` object, deserialze to an object of an arbitrary type.
    static alias deserialize = jsondeserialize;
    
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
        return typeof(this).parse!floatsettings(json).jsondeserialize!T;
    }
    
    /// Given a value of an arbitrary type, serialize to compact json.
    static auto encode(
        WriteFloatSettings floatsettings = FloatSettings.Default, T
    )(auto ref T value){
        static if(is(Unqual!T == JsonValue)){
            return value.encode!floatsettings;
        }else{
            return value.jsonserialize.encode!floatsettings;
        }
    }
    /// Given a value of an arbitrary type, serialize to human-readable
    /// formatted json.
    static auto pretty(
        string indent = "  ", WriteFloatSettings floatsettings = FloatSettings.Default, T
    )(auto ref T value){
        static if(is(Unqual!T == JsonValue)){
            return value.pretty!(indent, floatsettings);
        }else{
            return value.jsonserialize.pretty!(indent, floatsettings);
        }
    }
    
    /// Write json to a file path. Overwrites any existing file at that path.
    static auto writefile(
        WriteFloatSettings floatsettings = FloatSettings.Default, S, T
    )(in S path, auto ref T value) if(isString!S){
        try{
            Path(path).writeto(typeof(this).encode!floatsettings(value));
        }catch(FileException e){
            throw new JsonException(e);
        }catch(StreamException e){
            throw new JsonException(e);
        }
    }
    /// Write pretty json to a file path. Overwrites any existing file at that path.
    static auto prettyfile(
        WriteFloatSettings floatsettings = FloatSettings.Default, S, T
    )(in S path, auto ref T value) if(isString!S){
        try{
            Path(path).writeto(typeof(this).pretty!floatsettings(value));
        }catch(FileException e){
            throw new JsonException(e);
        }catch(StreamException e){
            throw new JsonException(e);
        }
    }
    /// Read json from a file path.
    static auto parsefile(
        WriteFloatSettings floatsettings = FloatSettings.Default, S
    )(in S path) if(isString!S){
        try{
            auto content = cast(string) Path(path).readall();
            return typeof(this).parse!floatsettings(content);
        }catch(FileException e){
            throw new JsonException(e);
        }catch(StreamException e){
            throw new JsonException(e);
        }
    }
    /// Read json from a file path, deserializing to a value of the given type.
    static auto parsefile(
        T, WriteFloatSettings floatsettings = FloatSettings.Default, S
    )(in S path) if(isString!S){
        return typeof(this).parsefile!floatsettings(path).jsondeserialize!T;
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
