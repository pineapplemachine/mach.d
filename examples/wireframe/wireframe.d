// This program uses some of mach's sleeker math functionality to perform
// very simple software 3D rendering. The camera can be moved with the WASD
// keys and rotated by moving the mouse.

import mach.sdl;
import mach.math;
import mach.range;

// Many thanks to http://www.songho.ca/opengl/gl_transform.html
class Wireframe: Application{
    // Information about the window that will be created and rendered to
    enum int windowwidth = 640;
    enum int windowheight = 480;
    enum windowcenter = Vector2i(windowwidth, windowheight) / 2;
    
    // The points to render lines for. Try modifying this and see what happens!
    static immutable points = [
        Vector3f(+1, +1, +1),
        Vector3f(+1, +1, -1),
        Vector3f(+1, -1, -1),
        Vector3f(+1, -1, +1),
        Vector3f(-1, -1, +1),
        Vector3f(-1, -1, -1),
        Vector3f(-1, +1, -1),
        Vector3f(-1, +1, +1),
    ];
    
    // Points above transformed to screen coordinates will be stored here.
    Vector2i[points.length] screenpoints;
    
    // World coordinates for background particles will go here.
    Vector3f[] particles;
    
    // The initial position and orientation of the camera.
    // It starts out looking at the object in the center of the scene.
    Vector3f camerapos = Vector3f(0, 0, 6);
    Rotation!ulong camerayaw = Rotation!ulong.Degrees(180);
    Rotation!ulong camerapitch = Rotation!ulong.Degrees(0);
    
    // Transformation matrix for converting from world coordinates to eye coordinates.
    Matrix4f projection = Matrix4f.glperspective(
        Angle!ulong.Degrees(45), cast(double) windowwidth / windowheight, -0.15, -20
    );
    
    // Helper method to transform world coordinates to screen coordinates.
    auto transform(in Matrix4f view, in Vector3f point){
        struct Result{
            bool front = false;
            double w = 0;
            Vector2i vector = Vector2i.zero;
        }
        auto transformed = projection * view * Vector4f(camerapos - point);
        return Result(transformed.w > 0, transformed.w, Vector2i(
            (1 + transformed.x / transformed.w) * windowwidth / 2,
            (1 - transformed.y / transformed.w) * windowheight / 2
        ));
    }
    
    // This method is run when the application is first started.
    override void initialize(){
        // Initialize the window and the mouse state.
        window = new Window("Wireframe", windowwidth, windowheight);
        Mouse.warpwindow(window, windowcenter);
        Mouse.hide;
        // Randomly generate some particles to place in the scene.
        auto rng = xorshift();
        foreach(i; 0 .. 20){
            particles ~= Vector3f.unit(
                Angle!ulong.Revolutions(rng.random!float),
                Angle!ulong.Revolutions(rng.random!float),
            ) * rng.random!double(30, 80);
        }
    }
    
    // This method is run when the application exits.
    override void conclude(){
        // Nothing that needs to be done here!
    }
    
    // This is the main application loop.
    override void main(){
        // Clear the screen to almost-black.
        enum background = 0.06;
        clear(background, background, background);
        
        // Get transformation matrixes.
        auto yaw = Matrix3f.yawrotation(
            camerayaw.angle
        );
        auto view = cast(Matrix4f)(Matrix3f.pitchrotation(
            camerapitch.angle
        ) * yaw);
        
        // Draw background particles.
        foreach(particle; particles){
            auto screen = this.transform(view, particle);
            if(screen.front){
                Render.color = Color.White / (particle.distance(camerapos) * 0.03);
                if(Render.color.r > background) Render.point(screen.vector);
            }
        }
        
        // Draw lines.
        size_t i = 0;
        Render.color = Color.Cyan;
        foreach(point; points){
            auto screen = this.transform(view, point);
            if(screen.front) screenpoints[i++] = screen.vector;
        }
        if(i > 1){
            Render.lineloop(screenpoints[0..i]);
        }
        
        // Display changes on the render target.
        swap();
        
        // Handle player movement keys
        auto forward = keys.down(KeyCode.W);
        auto back = keys.down(KeyCode.S);
        auto left = keys.down(KeyCode.A);
        auto right = keys.down(KeyCode.D);
        if((forward ^ back) || (left ^ right)){
            double speed = keys.down(KeyCode.LeftShift) ? 0.35 : 0.15;
            auto dir = Vector4f(left - right, 0, forward - back, 0).normalize * speed;
            camerapos += ((cast(Matrix4f) yaw).transpose * dir).xyz;
        }
        
        // Handle mouselook.
        camerayaw += Rotation!ulong.Degrees((mouse.position.x - windowwidth / 2) * 0.2);
        camerapitch -= Rotation!ulong.Degrees((mouse.position.y - windowheight / 2) * 0.2);
        Mouse.warpwindow(window, Vector2i(windowcenter));
        
        // Clamp camera pitch.
        if(camerapitch.degrees < -45) camerapitch.degrees = -45;
        else if(camerapitch.degrees > +45) camerapitch.degrees = +45;
        
        // Quit on escape.
        if(keys.down(KeyCode.Escape)) quit();
    }
}

// Actually run the program!
void main(){
    new Wireframe().begin;
}
