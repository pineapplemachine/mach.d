module mach.sdl.input.event.controller;

private:

import derelict.sdl2.types;
import mach.sdl.input.event.mixins;
import mach.sdl.input.event.type : EventType;
import mach.sdl.input.controller : Controller;

public:



/// https://wiki.libsdl.org/SDL_ControllerAxisEvent
struct ControllerAxisEvent{
    mixin EventMixin!SDL_ControllerAxisEvent;
    mixin ControllerEventMixin;
    mixin JoyAxisEventMixin!(Controller.Axis);
}

/// https://wiki.libsdl.org/SDL_ControllerButtonEvent
struct ControllerButtonEvent{
    mixin EventMixin!SDL_ControllerButtonEvent;
    mixin ControllerEventMixin;
    mixin ButtonEventMixin!(Controller.Button);
}

/// https://wiki.libsdl.org/SDL_ControllerDeviceEvent
struct ControllerDeviceEvent{
    mixin EventMixin!SDL_ControllerDeviceEvent;
    /// Assuming this is a device added event, get the device index of the
    /// added controller.
    @property Controller.DeviceIndex added() const{
        return cast(Controller.DeviceIndex) this.eventdata.which;
    }
    /// Set the device index of the added controller.
    @property void added(Controller.DeviceIndex index){
        this.eventdata.type = EventType.ControllerDeviceAdded;
        this.eventdata.which = index;
    }
    /// Assuming this is a device removed event, get a Controller object
    /// representing the removed controller.
    @property Controller removed() const{
        return Controller.byid(this.removedid);
    }
    /// Set the Controller object representing the removed controller.
    @property void removed(Controller controller){
        this.removedid = controller.id;
    }
    /// Assuming this is a device remapped event, get a Controller object
    /// representing the remapped controller.
    @property Controller remapped() const{
        return Controller.byid(this.remappedid);
    }
    /// Set the Controller object representing the remapped controller.
    @property void remapped(Controller controller){
        this.remappedid = controller.id;
    }
    /// Assuming this is a device removed event, get the instance id of the
    /// removed controller.
    @property Controller.ID removedid() const{
        return cast(Controller.ID) this.eventdata.which;
    }
    /// Set the instance id of the removed controller.
    @property void removedid(Controller.ID controllerid){
        this.eventdata.type = EventType.ControllerDeviceRemoved;
        this.eventdata.which = controllerid;
    }
    /// Assuming this is a device remapped event, get the instance id of the
    /// remapped controller.
    @property Controller.ID remappedid() const{
        return cast(Controller.ID) this.eventdata.which;
    }
    /// Set the instance id of the remapped controller.
    @property void remappedid(Controller.ID controllerid){
        this.eventdata.type = EventType.ControllerDeviceRemapped;
        this.eventdata.which = controllerid;
    }
}
