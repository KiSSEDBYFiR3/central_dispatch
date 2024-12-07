import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:central_dispatch/dispacther/workers_pool.dart';
import 'package:central_dispatch/dispacther/concurrent_worker.dart';
import 'package:central_dispatch/dispacther/implementations/worker_factory.dart';
import 'package:central_dispatch/dispacther/entities/work.dart';
import 'package:collection/collection.dart';

final class DefaultIsolatesPool implements IsolatedWorkersPool {
  final int _isolatesMaxCount;
  final Duration? _pauseAfter;

  late final StreamController<WorkResult> _responseController =
      StreamController.broadcast();

  @override
  Stream<WorkResult> get resultsStream => _responseController.stream;

  final Queue<WorkItem> _eventQueue = Queue();

  @override
  int get currentIsolatesCount => _pool.length;

  final List<ConcurrentWorker> _pool = [];

  DefaultIsolatesPool({
    required int isolatesMaxCount,
    Duration? pauseAfter,
  })  : _isolatesMaxCount = isolatesMaxCount,
        _pauseAfter = pauseAfter;

  @override
  FutureOr<void> execute(WorkItem event) async {
    var freeIsolate = _pool.firstWhereOrNull((e) => e.isFree);

    if (freeIsolate == null && _pool.length < _isolatesMaxCount) {
      freeIsolate = WorkerFactory.newWorker(
        sink: _responseController.sink,
        onNext: _onNext,
        pauseAfter: _pauseAfter,
      );

      await freeIsolate.init();
      _pool.add(freeIsolate);
    }

    if (freeIsolate == null && _pool.length == _isolatesMaxCount) {
      _addEventToQueue(event);
      return;
    }
  }

  @override
  Future<void> init() async {
    for (var i = 0; i < max(Platform.numberOfProcessors - 2, 2); i++) {
      final worker = WorkerFactory.newWorker(
        sink: _responseController.sink,
        onNext: _onNext,
        pauseAfter: _pauseAfter,
      );

      await worker.init();
      _pool.add(worker);
    }
  }

  void _onNext() {
    if (_eventQueue.isEmpty) return;

    final event = _eventQueue.removeFirst();

    execute(event);
  }

  void _addEventToQueue(WorkItem event) => _eventQueue.add(event);

  @override
  void dispose() {
    _eventQueue.clear();

    for (var i = 0; i < _pool.length; i++) {
      _pool[i].dispose();
    }
  }
}
