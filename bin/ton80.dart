// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:quiver/strings.dart' as strings;
import 'dart:io' as io;
import 'dart:math' as math;

const JS = const String.fromEnvironment('JS', defaultValue: 'd8');
const WRK = const String.fromEnvironment('WRK', defaultValue: 'wrk');
final DART = io.Platform.executable;

const DART_RUNNER = const DartRunner();
const DART2JS_RUNNER = const Dart2JSRunner();
const JS_RUNNER = const JSRunner();
const DARTIO_RUNNER = const DartIORunner();

const CATEGORIES = const {
  'BASE' : const {
    'RUNNERS': const [ DART_RUNNER, DART2JS_RUNNER, JS_RUNNER ],
    'BENCHMARKS': const [ 'DeltaBlue', 'Richards', 'FluidMotion', 'Tracer' ],
  },
  'IO' : const {
    'RUNNERS' : const [ DARTIO_RUNNER ],
    'BENCHMARKS': const [ 'Hello', 'File', 'JSON' ]
  }
};

void main() {
  for (Map category in CATEGORIES.values) {
    for (String benchmark in category['BENCHMARKS']) {
      print('Running $benchmark...');
      for (Runner runner in category['RUNNERS']) {
        runner.run(benchmark);
      }
    }
  }
}

class Runner {
  const Runner();
  void run(String benchmark);
}

class DartRunner implements Runner {
  const DartRunner();
  void run(String benchmark) {
    List<double> dart = extractScores(() => io.Process.runSync(DART, [
        source(benchmark, 'dart', '$benchmark.dart'),
    ]));
    print('  - Dart    : ${format(dart)}');
  }
}

class Dart2JSRunner implements Runner {
  const Dart2JSRunner();
  void run(String benchmark) {
    List<double> dart2js = extractScores(() => io.Process.runSync(JS, [
        source(benchmark, 'dart', '$benchmark.dart.js'),
    ]));
    print('  - Dart2JS : ${format(dart2js)}');
  }
}

class JSRunner implements Runner {
  const JSRunner();
  void run(String benchmark) {
    List<double> js = extractScores(() => io.Process.runSync(JS, [
        '-f', source('common', 'javascript', 'bench.js'),
        '-f', source(benchmark, 'javascript', '$benchmark.js'),
    ]));
    print('  - JS      : ${format(js)}');
  }
}

class DartIORunner implements Runner {
  const DartIORunner();
  void run(String benchmark) {
    List<List<double>> results = extractIOScores(() => io.Process.runSync(DART, [
        source('Serve', 'dart', 'Serve.dart'),
        WRK,
        '/${benchmark.toLowerCase()}'
    ]));
    print('  - Dart    : ${format(results[0], "requests/sec")}');
    print('  - Dart    : ${format(results[1], "ms mean latency")}');
    print('  - Dart    : ${format(results[2], "ms worst latency")}');
  }
}

String format(List<double> scores, [String metric = 'runs/sec']) {
  double mean = computeMean(scores);
  double best = computeBest(scores);
  String score = strings.padLeft(best.toStringAsFixed(2), 8, ' ');
  if (scores.length == 1) {
    return "$score $metric";
  } else {
    final int n = scores.length;
    double standardDeviation = computeStandardDeviation(scores, mean);
    double standardError = standardDeviation / math.sqrt(n);
    double percent = (computeTDistribution(n) * standardError / mean) * 100;
    String error = percent.toStringAsFixed(1);
    return "$score $metric (${mean.toStringAsFixed(2)}±$error%)";
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

final RegExp EXTRACT = new RegExp(r"((\d)+(\.(\d)+)?) us");
List<double> extractScores(io.ProcessResult generator(),
                           [int iterations = 10]) {
  List<double> scores = [];
  for (int i = 0; i < iterations; i++) {
    io.ProcessResult result = generator();
    String output = result.stdout;
    Match match = EXTRACT.firstMatch(output);
    scores.add(1000000 / double.parse(match.group(1)));
  }
  return scores;
}

List<List<double>> extractIOScores(io.ProcessResult generator(),
                                   [int iterations = 3]) {
  List<double> requestsPerSecond = [];
  List<double> latency = [];
  List<double> latencyMax = [];
  for (int i = 0; i < iterations; i++) {
    io.ProcessResult result = generator();
    String output = result.stdout;
    var data = output.split('\n').take(3).map(double.parse).toList();
    requestsPerSecond.add(data[0]);
    latency.add(data[1]);
    latencyMax.add(data[2]);
  }
  return [requestsPerSecond, latency, latencyMax];
}

String source(String benchmark, String kind, String file) {
  String base = path.dirname(io.Platform.script.path);
  return path.join(base, '..', 'lib', 'src', benchmark, kind, file);
}
