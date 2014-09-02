// The ray tracer code in this file is written by Adam Burmister. It
// is available in its original form from:
//
//   http://labs.flog.co.nz/raytracer/
//
// Ported from the v8 benchmark suite by Google 2012.
part of ray_trace;

abstract class Materials {
  final double gloss;             // [0...infinity] 0 = matt
  final double transparency;      // 0=opaque
  final double reflection;        // [0...infinity] 0 = no reflection
  final double refraction;
  final bool hasTexture;

  const Materials(this.reflection,
                  this.transparency,
                  this.gloss,
                  this.refraction,
                  this.hasTexture);

  Color getColor(num u, num v);

  wrapUp(t) {
    t = t % 2.0;
    if(t < -1) t += 2.0;
    if(t >= 1) t -= 2.0;
    return t;
  }
}


class Chessboard extends Materials {
  final Color colorEven, colorOdd;
  final double density;

  const Chessboard(this.colorEven,
                   this.colorOdd,
                   reflection,
                   transparency,
                   gloss,
                   this.density)
      : super(reflection, transparency, gloss, 0.5, true);

  Color getColor(num u, num v) {
    var t = wrapUp(u * density) * wrapUp(v * density);

    if (t < 0.0) {
      return colorEven;
    } else {
      return colorOdd;
    }
  }
}


class Solid extends Materials {
  final Color color;

  const Solid(this.color, reflection, refraction, transparency, gloss)
      : super(reflection, transparency, gloss, refraction, false);

  Color getColor(num u, num v) {
    return color;
  }
}
