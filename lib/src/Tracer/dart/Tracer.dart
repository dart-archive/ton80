// The ray tracer code in this file is written by Adam Burmister. It
// is available in its original form from:
//
//   http://labs.flog.co.nz/raytracer/
//
// Ported from the v8 benchmark suite by Google 2012.

import '../../common/dart/BenchmarkBase.dart';

import 'default/renderscene.dart' as default_raytrace;
import 'simd/renderscene.dart' as simd_raytrace;

const bool useSIMD = const bool.fromEnvironment(
    'dart.isVM',
    defaultValue: !identical(1, 1.0));

class TracerBenchmark extends BenchmarkBase {
  const TracerBenchmark() : super("Tracer");

  void warmup() {    
    if (useSIMD) {
      simd_raytrace.renderScene(null);
    } else {
      default_raytrace.renderScene(null);
    }
  }

  void exercise() {
    if (useSIMD) {
      simd_raytrace.renderScene(null);
    } else {
      default_raytrace.renderScene(null);
    }
  }
}

void main() {
  new TracerBenchmark().report();
}
