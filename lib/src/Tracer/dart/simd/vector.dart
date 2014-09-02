// The ray tracer code in this file is written by Adam Burmister. It
// is available in its original form from:
//
//   http://labs.flog.co.nz/raytracer/
//
// Ported from the v8 benchmark suite by Google 2012.
part of ray_trace_simd;

class Vector {
  final Float32x4 _xyz;

  double get x => _xyz.x;
  double get y => _xyz.y;
  double get z => _xyz.z;

  factory Vector(double x, double y, double z) {
    return new Vector._create(new Float32x4(x, y, z, 0.0));
  }

  Vector._create(this._xyz);

  Vector normalize() {
    var m = magnitude();
    return new Vector._create(_xyz.scale(1.0 / m));
  }

  Vector negateY() {
    return new Vector._create(_xyz.withY(-_xyz.y));
  }

  double magnitude() {
    var prod = _xyz * _xyz;
    return sqrt(prod.x + prod.y + prod.z);
  }

  Vector cross(Vector w) {
    var v = _xyz;
    var x = -v.z * w.y + v.y * w.z;
    var y = v.z * w.x - v.x * w.z;
    var z = -v.y * w.x + v.x * w.y;
    return new Vector._create(new Float32x4(x, y, z, 0.0));
  }

  double dot(Vector w) {
    var prod = _xyz * w._xyz;
    return prod.x + prod.y + prod.z;
  }

  Vector operator +(Vector w) {
    return new Vector._create(_xyz + w._xyz);
  }

  Vector operator -(Vector w) {
    return new Vector._create(_xyz - w._xyz);
  }

  Vector operator *(Vector w) {
    return new Vector._create(_xyz * w._xyz);
  }

  Vector multiplyScalar(double w) {
    return new Vector._create(_xyz.scale(w));
  }

  String toString() {
    return 'Vector [$x, $y ,$z ]';
  }
}
