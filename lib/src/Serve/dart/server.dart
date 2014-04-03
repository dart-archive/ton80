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
import 'dart:async';

final List<Map> resources = [
  {
    "id": 0,
    "name": "bacon",
    "content": "The quick brown fox jumps over the lazy dog"
  },
  {
    "id": 1,
    "name": "pony",
    "content": "\u0011qÌì7zçÖ¡da¥@qc+RÞ9ªê»õ÷¬tÖ×è\"ÿ\u0004µx±~\u0003Ñë"
  },
  {
    "id": 2,
    "name": "mountain",
    "content": null
  },
  {
    "id": 3,
    "name": "locomotive",
    "content": ""
  },
  {
    "id": 4,
    "name": "grass",
    "content": "{ \"version\": 2.1 }"
  }
];

class Serve {
  static Future<Serve> start() {
    return HttpServer.bind('localhost', 0).then((server) {
      return new Serve._(server);
    });
  }

  static const _HANDLERS = const {
    '/hello' : _hello,
    '/file'  : _file,
    '/json'  : _json,
  };

  final HttpServer _server;

  Serve._(this._server) {
    _server.listen((request) {
      final path = request.uri.path;

      // Select handler by path.
      Function handler = _HANDLERS[path];

      if (handler == null) handler = _error;
      handler(request);
    });
  }

  static void _hello(HttpRequest request) {
    request.response
        ..headers.contentType = new ContentType('text', 'plain')
        ..write('world')
        ..close();
  }

  static void _file(HttpRequest request) {
    var file = new File(Platform.script.resolve('file.dat').toFilePath());
    request.response.headers.contentType =
        new ContentType('application', 'octet-stream');
    file.openRead().pipe(request.response);
  }

  static void _json(HttpRequest request) {
    request.response
        ..headers.contentType =
            new ContentType('text', 'plain', charset: 'utf-8')
        ..write(JSON.encode(resources))
        ..close();
  }

  static void _error(HttpRequest request,
                     [int statusCode = HttpStatus.NOT_FOUND]) {
    request.response
        ..statusCode = statusCode
        ..close();
  }

  int get port => _server.port;
}


void main() {
  Serve.start().then((Serve serve) {
    print(serve.port);
  });
}
