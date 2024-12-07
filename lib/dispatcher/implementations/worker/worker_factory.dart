import 'dart:async';

import 'package:central_dispatch/dispatcher/entities/work.dart';

import 'isolated_worker_stub.dart'
    if (dart.library.io) 'isolated_worker_io.dart'
    if (dart.library.html) 'isolated_worker_web.dart';

abstract final class WorkerFactory {
  static IsolatedWorker newWorker({
    required StreamSink<WorkResult> sink,
    required void Function() onNext,
    Duration? pauseAfter,
  }) =>
      createWorker(
        sink: sink,
        onNext: onNext,
        pauseAfter: pauseAfter,
      );
}
