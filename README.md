Ton 80
======

Ton 80 is a benchmark suite for Dart. The Dart team continuously monitors
the performance of these benchmarks: http://dartlang.org/performance/.

In it's current setup, the Ton80 benchmark suite is easy to run and
profile from the command line. When adding new benchmarks to the suite, 
please use the existing harness and help us make sure we can continue to
easily run and profile from the command line.

You can run Ton80 using `bin/ton80.dart`. It has the following usage:<br>
```dart ton80.dart [OPTION]... [BENCHMARK]```

## Contributing

We're happy to review Pull Requests that fix bugs in benchmark implementations.

We're intentionally keeping the list of benchmarks small. We especially want
to avoid micro-benchmarks. If you have a good idea for a benchmark, please
open a new issue first. Our team will respond to discuss the benchmark.

Before contributed code can be merged, the author must first sign the
[Google CLA][https://cla.developers.google.com/about/google-individual].
