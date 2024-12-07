import 'dart:async';

import 'package:central_dispatch/dispacther/concurrent_worker.dart';
import 'package:central_dispatch/dispacther/entities/work.dart';

final class IsolatedWorker implements ConcurrentWorker {
  IsolatedWorker({
    required StreamSink<WorkResult> sink,
    required void Function() onNext,
    Duration? pauseAfter,
  });

  @override
  void dispose() {}

  @override
  void execute(DispatchWork event) {}

  @override
  Future<void> init() async {}

  @override
  bool get isFree => false;
}

IsolatedWorker createWorker({
  required StreamSink<WorkResult> sink,
  required void Function() onNext,
  Duration? pauseAfter,
}) =>
    IsolatedWorker(
      sink: sink,
      onNext: onNext,
      pauseAfter: pauseAfter,
    );
