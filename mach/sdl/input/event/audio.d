module mach.sdl.input.event.audio;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;
import mach.sdl.input.event.type : EventType;

public:



/// https://wiki.libsdl.org/SDL_AudioDeviceEvent
struct AudioDeviceEvent{
    mixin EventMixin!SDL_AudioDeviceEvent;
    // TODO: There's probably a better place to put these definitions
    alias DeviceID = SDL_AudioDeviceID;
    alias DeviceIndex = int;
    /// Get whether the device is an audio capture device.
    @property bool iscapture() const{
        return this.eventdata.iscapture != 0;
    }
    /// Set whether the device is an audio capture device.
    @property void iscapture(bool capture){
        this.eventdata.iscapture = capture;
    }
    /// Assuming this is a device added event, get the device index of the
    /// added audio device.
    @property DeviceIndex added() const{
        return cast(DeviceIndex) this.eventdata.which;
    }
    /// Set the device index of the added audio device.
    @property void added(DeviceIndex index){
        this.eventdata.type = EventType.AudioDeviceAdded;
        this.eventdata.which = index;
    }
    /// Assuming this is a device removed event, get the instance id of the
    /// removed audio device.
    @property DeviceID removedid() const{
        return cast(DeviceID) this.eventdata.which;
    }
    /// Set the instance id of the removed audio device.
    @property void removedid(DeviceID audioid){
        this.eventdata.type = EventType.AudioDeviceRemoved;
        this.eventdata.which = audioid;
    }
}
