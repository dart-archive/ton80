// Copyright 2014 the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import 'dart:io';
import 'dart:convert';

Future<String> runProcess(String process, List<String> args) {
  return Process.run(process, args)
    .then((output) {
      if (output.exitCode != 0) {
        throw 'Failed to run process $process.\n'
              '${output.stdout}\n'
              '${output.stderr}';
      }
      return output.stdout;
    });
}

String runWrk(String wrk, int port, String path,
              {int duration: 5, int concurrency: 128, int threads: 2}) {
  return runProcess(
      wrk,
      ['-d', duration.toString(),
       '-c', concurrency.toString(),
       '-t', threads.toString(),
       '-H', 'Host: localhost',
       '-H', 'Connection: keep-alive',
       '-H', 'Accept: */*',
       '-H', 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
             ' (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36',
       'http://localhost:$port$path']);
}

void printResults(String output) {
  // Example output:
  //
  // Running 1s test @ http://localhost:43969/ping
  //   2 threads and 128 connections
  //   Thread Stats   Avg      Stdev     Max   +/- Stdev
  //     Latency     9.60ms    2.02ms  17.13ms   89.42%
  //     Req/Sec     4.67k     2.19k    7.31k    60.71%
  //   8368 requests in 999.38ms, 0.92MB read
  // Requests/sec:   8373.21
  // Transfer/sec:      0.92MB
  //
  // We then look for these two lines, and find both req/sec and avg/max
  // latency.
  if (output.contains("Non-2xx")) throw "Bad request path";
  var lines = output.split('\n');
  for (var line in lines) {
    const REQ_SEC_STR = 'Requests/sec:';
    if (line.startsWith(REQ_SEC_STR)) {
      print(line.substring(REQ_SEC_STR.length).trim());
      break;
    }
  }
  for (var line in lines) {
    const LAT_STR = '    Latency';
    if (line.startsWith(LAT_STR)) {
      var latency = line.substring(LAT_STR.length).trim();
      var latencies = latency.split(' ')
          .where((s) => !s.trim().isEmpty)
          .toList();
      print(latencies[0].substring(0, latencies[0].length - 2));
      print(latencies[2].substring(0, latencies[2].length - 2));
    }
  }
}

void main(args) {
  const int WARMUP_TIME = 1;
  const int BENCHMARK_TIME = 5;

  String wrk = args[0];
  String path = args[1];
  Process.start(Platform.executable,
                [Platform.script.resolve('server.dart').toFilePath()])
    .then((process) {
      process.stdout
          .transform(UTF8.decoder)
          .transform(const LineSplitter())
          .first.then((line) {
            // First line is the port.
            int port = int.parse(line);
            runWrk(wrk, port, path, duration: WARMUP_TIME).then((_) {
              runWrk(wrk, port, path, duration: BENCHMARK_TIME)
                .then((output) {
                  printResults(output);
                  process.kill();
                });
            });
          });
    });
}
