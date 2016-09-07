module mach.sdl.haptic.direction;

private:

import derelict.sdl2.sdl;
import mach.sdl.haptic.hdegrees;

public:



/// https://wiki.libsdl.org/SDL_HapticDirection
static struct HapticDirection{
    /// Different ways that feedback direction can be represented.
    /// What specifically the values in the coords array represent is dependent
    /// upon which type the direction is.
    static enum Type: ubyte{
        Polar = SDL_HAPTIC_POLAR,
        Cartesian = SDL_HAPTIC_CARTESIAN,
        Spherical = SDL_HAPTIC_SPHERICAL,
    }
    alias Coord = int;
    alias Coords = Coord[3];
    
    SDL_HapticDirection dir;
    
    /// Get the direction type.
    @property Type type() const{
        return cast(Type) this.dir.type;
    }
    /// Set the direction type.
    @property void type(Type type){
        this.dir.type = cast(ubyte) type;
    }
    /// Get the direction's array of coordinates.
    /// Specifically what these coordinates represent and which values in the
    /// array are significant depend both on the direction type and on whether
    /// the joystick allows haptic feedback on two or three axes.
    @property Coords coords() const{
        return this.dir.dir;
    }
    /// Set the direction's array of coordinates.
    @property void coords(Coords coords){
        this.dir.dir = coords;
    }
    
    Coord getcoord(size_t index) const{
        return this.dir.dir[index];
    }
    void setcoord(size_t index, Coord coord){
        this.dir.dir[index] = coord;
    }
    @property Coord coord0() const{return this.getcoord(0);}
    @property Coord coord1() const{return this.getcoord(1);}
    @property Coord coord2() const{return this.getcoord(2);}
    @property void coord0(Coord coord){this.setcoord(0, coord);}
    @property void coord1(Coord coord){this.setcoord(1, coord);}
    @property void coord2(Coord coord){this.setcoord(2, coord);}
    
    @property real getcoorddeg(size_t index) const{
        return this.getcoord(index).hdegtodeg;
    }
    @property void setcoorddeg(size_t index, real degrees){
        this.setcoord(index, degrees.degtohdeg);
    }
    @property real getcoordrad(size_t index) const{
        return this.getcoord(index).hdegtorad;
    }
    @property void setcoordrad(size_t index, real radians){
        this.setcoord(index, radians.radtohdeg);
    }
    @property real coord0deg() const{return this.getcoorddeg(0);}
    @property real coord1deg() const{return this.getcoorddeg(1);}
    @property void coord0deg(real degrees){this.setcoorddeg(0, degrees);}
    @property void coord1deg(real degrees){this.setcoorddeg(1, degrees);}
    @property real coord0rad() const{return this.getcoordrad(0);}
    @property real coord1rad() const{return this.getcoordrad(1);}
    @property void coord0rad(real radians){this.setcoordrad(0, radians);}
    @property void coord1rad(real radians){this.setcoordrad(1, radians);}
    
    /// Assuming this is a polar direction, get/set the direction of feedback
    /// measured in hundredths of degrees, starting north (away from the user)
    /// and turning clockwise.
    alias polarraw = coord0;
    /// Assuming this is a polar direction, get/set the direction of feedback
    /// in degrees.
    alias polardeg = coord0deg;
    /// Assuming this is a polar direction, get/set the direction of feedback
    /// in radians.
    alias polarrad = coord0rad;
    
    /// Assuming this is a cartesian direction, get/set the x axis of the
    /// feedback direction.
    alias cartx = coord0;
    /// Assuming this is a cartesian direction, get/set the y axis of the
    /// feedback direction.
    alias carty = coord0;
    /// Assuming this is a cartesian direction, get/set the z axis of the
    /// feedback direction. Represents the height of the effect if the joystick
    /// supports it, otherwise the axis is unused.
    alias cartz = coord0;
    
    /// Assuming this is a spherical direction, get/set the direction of
    /// feedback in degrees.
    alias spherepolardeg = coord0deg;
    /// Assuming this is a spherical direction, get/set the direction of
    /// feedback in radians.
    alias spherepolarrad = coord0rad;
    /// Assuming this is a spherical direction, get/set the direction of
    /// feedback in degrees.
    alias spherethetadeg = coord1deg;
    /// Assuming this is a spherical direction, get/set the direction of
    /// feedback in radians.
    alias spherethetarad = coord1rad;
}
