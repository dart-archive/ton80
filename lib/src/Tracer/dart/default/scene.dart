// The ray tracer code in this file is written by Adam Burmister. It
// is available in its original form from:
//
//   http://labs.flog.co.nz/raytracer/
//
// Ported from the v8 benchmark suite by Google 2012.
part of ray_trace;

class Ray {
  final position;
  final direction;

  Ray(this.position, this.direction);
  String toString() {
    return 'Ray [$position, $direction]';
  }
}


class Camera {
  final position;
  final lookAt;
  final up;
  var equator, screen;

  Camera(this.position, this.lookAt, this.up) {
    equator = lookAt.normalize().cross(up);
    screen = position + lookAt;
  }

  Ray getRay(double vx, double vy) {
    var pos = screen - (equator.multiplyScalar(vx) - up.multiplyScalar(vy));
    pos = pos.negateY();
    var dir = pos - position;
    var ray = new Ray(pos, dir.normalize());
    return ray;
  }

  toString() {
    return 'Camera []';
  }
}


class Background {
  final Color color;
  final double ambience;

  const Background(this.color, this.ambience);
}


class Scene {
  var camera;
  var shapes;
  var lights;
  var background;
  Scene() {
    camera = new Camera(const Vector(0.0, 0.0, -0.5),
                        const Vector(0.0, 0.0, 1.0),
                        const Vector(0.0, 1.0, 0.0));
    shapes = new List();
    lights = new List();
    background = const Background(const Color(0.0, 0.0, 0.5), 0.2);
  }
}
