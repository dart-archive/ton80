// The ray tracer code in this file is written by Adam Burmister. It
// is available in its original form from:
//
//   http://labs.flog.co.nz/raytracer/
//
// Ported from the v8 benchmark suite by Google 2012.
part of ton80.tracer;

class Light {
  final position;
  final color;
  final intensity;

  const Light(this.position, this.color, [this.intensity = 10.0]);
}


// 'event' null means that we are benchmarking
void renderScene(event) {
  var scene = new Scene();
  scene.camera = new Camera(const Vector(0.0, 0.0, -15.0),
                            const Vector(-0.2, 0.0, 5.0),
                            const Vector(0.0, 1.0, 0.0));
  scene.background = const Background(const Color(0.5, 0.5, 0.5), 0.4);

  var sphere = const Sphere(
      const Vector(-1.5, 1.5, 2.0),
      1.5,
      const Solid(
          const Color(0.0, 0.5, 0.5),
          0.3,
          0.0,
          0.0,
          2.0
      )
  );

  var sphere1 = const Sphere(
      const Vector(1.0, 0.25, 1.0),
      0.5,
      const Solid(
          const Color(0.9,0.9,0.9),
          0.1,
          0.0,
          0.0,
          1.5
      )
  );

  var plane = new Plane(
      new Vector(0.1, 0.9, -0.5).normalize(),
      1.2,
      const Chessboard(
          const Color(1.0, 1.0, 1.0),
          const Color(0.0, 0.0, 0.0),
          0.2,
          0.0,
          1.0,
          0.7
      )
  );

  scene.shapes.add(plane);
  scene.shapes.add(sphere);
  scene.shapes.add(sphere1);

  var light = const Light(
      const Vector(5.0, 10.0, -1.0),
      const Color(0.8, 0.8, 0.8)
  );

  var light1 = const Light(
      const Vector(-3.0, 5.0, -15.0),
      const Color(0.8, 0.8, 0.8),
      100.0
  );

  scene.lights.add(light);
  scene.lights.add(light1);

  int imageWidth, imageHeight, pixelSize;
  bool renderDiffuse, renderShadows, renderHighlights, renderReflections;
  var canvas;
  if (event == null) {
    imageWidth = 100;
    imageHeight = 100;
    pixelSize = 5;
    renderDiffuse = true;
    renderShadows = true;
    renderHighlights = true;
    renderReflections = true;
    canvas = null;
  } else {
    imageWidth = int.parse(query('#imageWidth').value);
    imageHeight = int.parse(query('#imageHeight').value);
    pixelSize = int.parse(query('#pixelSize').value.split(',')[0]);
    renderDiffuse = query('#renderDiffuse').checked;
    renderShadows = query('#renderShadows').checked;
    renderHighlights = query('#renderHighlights').checked;
    renderReflections = query('#renderReflections').checked;
    canvas = query("#canvas");
  }
  int rayDepth = 2;

  var raytracer = new Engine(canvasWidth:imageWidth,
                             canvasHeight:imageHeight,
                             pixelWidth: pixelSize,
                             pixelHeight: pixelSize,
                             renderDiffuse: renderDiffuse,
                             renderShadows: renderShadows,
                             renderHighlights: renderHighlights,
                             renderReflections: renderReflections,
                             rayDepth: rayDepth
                             );

  raytracer.renderScene(scene, canvas);
}
