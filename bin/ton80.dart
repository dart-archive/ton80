// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:quiver/strings.dart' as strings;
import 'dart:io' as io;
import 'dart:math' as math;

const BENCHMARKS = const [ 'DeltaBlue', 'Richards', 'FluidMotion', 'Tracer' ];
const JS = const String.fromEnvironment('JS', defaultValue: 'd8');
final DART = io.Platform.executable;

void main() {
  for (String benchmark in BENCHMARKS) {
    print('Running $benchmark...');
    List<double> dart = runDart(benchmark);
    print('  - Dart    : ${format(dart)}');
    List<double> dart2js = runDart2JS(benchmark);
    print('  - Dart2JS : ${format(dart2js)}');
    List<double> js = runJS(benchmark);
    print('  - JS      : ${format(js)}');
  }
}

String format(List<double> scores) {
  double mean = computeMean(scores);
  double best = computeBest(scores);
  String score = strings.padLeft(best.toStringAsFixed(2), 8, ' ');
  if (scores.length == 1) {
    return "$score runs/sec";
  } else {
    final int n = scores.length;
    double standardDeviation = computeStandardDeviation(scores, mean);
    double standardError = standardDeviation / math.sqrt(n);
    double percent = (computeTDistribution(n) * standardError / mean) * 100;
    String error = percent.toStringAsFixed(1);
    return "$score runs/sec (${mean.toStringAsFixed(2)}±$error%)";
  }
}

double computeBest(List<double> scores) {
  double best = scores[0];
  for (int i = 1; i < scores.length; i++) {
    best = math.max(best, scores[i]);
  }
  return best;
}

double computeMean(List<double> scores) {
  double sum = 0.0;
  for (int i = 0; i < scores.length; i++) {
    sum += scores[i];
  }
  return sum / scores.length;
}

double computeStandardDeviation(List<double> scores, double mean) {
  double deltaSquaredSum = 0.0;
  for (int i = 0; i < scores.length; i++) {
    double delta = scores[i] - mean;
    deltaSquaredSum += delta * delta;
  }
  double variance = deltaSquaredSum / (scores.length - 1);
  return math.sqrt(variance);
}

double computeTDistribution(int n) {
  const List<double> TABLE = const [
      double.NAN, double.NAN, 12.71,
      4.30, 3.18, 2.78, 2.57, 2.45, 2.36, 2.31, 2.26, 2.23, 2.20, 2.18, 2.16,
      2.14, 2.13, 2.12, 2.11, 2.10, 2.09, 2.09, 2.08, 2.07, 2.07, 2.06, 2.06,
      2.06, 2.05, 2.05, 2.05, 2.04, 2.04, 2.04, 2.03, 2.03, 2.03, 2.03, 2.03,
      2.02, 2.02, 2.02, 2.02, 2.02, 2.02, 2.02, 2.01, 2.01, 2.01, 2.01, 2.01,
      2.01, 2.01, 2.01, 2.01, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00,
      2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 2.00, 1.99, 1.99, 1.99, 1.99, 1.99,
      1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99,
      1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99, 1.99 ];
  if (n >= 474) return 1.96;
  else if (n >= 160) return 1.97;
  else if (n >= TABLE.length) return 1.98;
  else return TABLE[n];
}

List<double> runDart(String benchmark) {
  return extractScores(() => io.Process.runSync(DART, [
      source(benchmark, 'dart', '$benchmark.dart'),
  ]));
}

List<double> runDart2JS(String benchmark) {
  return extractScores(() => io.Process.runSync(JS, [
      source(benchmark, 'dart', '$benchmark.dart.js'),
  ]));
}

List<double> runJS(String benchmark) {
  return extractScores(() => io.Process.runSync(JS, [
      '-f', source('common', 'javascript', 'bench.js'),
      '-f', source(benchmark, 'javascript', '$benchmark.js'),
  ]));
}

final RegExp EXTRACT = new RegExp(r"((\d)+(\.(\d)+)?) us");
List<double> extractScores(io.ProcessResult generator(), [int iterations = 10]) {
  List<double> scores = [];
  for (int i = 0; i < iterations; i++) {
    io.ProcessResult result = generator();
    String output = result.stdout;
    Match match = EXTRACT.firstMatch(output);
    scores.add(1000000 / double.parse(match.group(1)));
  }
  return scores;
}

String source(String benchmark, String kind, String file) {
  String base = path.dirname(io.Platform.script.path);
  return path.join(base, '..', 'lib', 'src', benchmark, kind, file);
}
