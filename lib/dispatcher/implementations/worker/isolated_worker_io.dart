import 'dart:async';
import 'dart:isolate';

import 'package:central_dispatch/dispatcher/concurrent_worker.dart';
import 'package:central_dispatch/dispatcher/entities/work.dart';
import 'package:central_dispatch/dispatcher/entities/worker_state.dart';

final class IsolatedWorker implements ConcurrentWorker {
  late final Isolate _isolate;

  final ReceivePort _receivePort;

  final Duration _pauseAfter;

  final StreamSink<WorkResult> _sink;

  final void Function() _onNext;

  WorkerState get state => _state;

  WorkerState _state = WorkerState.sleeping;

  SendPort? _sendPort;

  StreamSubscription? _streamSubscription;

  Capability? resumeCapability;

  Timer? _timer;

  IsolatedWorker({
    required StreamSink<WorkResult> sink,
    required void Function() onNext,
    Duration pauseAfter = const Duration(seconds: 3),
  })  : _receivePort = ReceivePort(),
        _sink = sink,
        _onNext = onNext,
        _pauseAfter = pauseAfter;

  @override
  bool get isFree => _state == WorkerState.free;

  @override
  Future<void> init() async {
    if (_state == WorkerState.sleeping) return;

    _isolate = await Isolate.spawn(
      _entryPoint,
      _receivePort.sendPort,
    );

    _streamSubscription = _receivePort.listen(
      (data) {
        switch (data.runtimeType) {
          case const (SendPort):
            _sendPort = data;
          case const (WorkResult):
            _state = WorkerState.free;
            _sink.add(data);
            _onNext();
            _schedulePause();
        }
      },
    );

    _state = WorkerState.free;
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _schedulePause() {
    _timer = Timer(
      _pauseAfter,
      () {
        resumeCapability = _isolate.pause();
        _streamSubscription?.pause();
      },
    );
  }

  @override
  void execute(DispatchWork event) {
    assert(
      _sendPort != null,
      'IsolateWrapper-$hashCode, _sendPort has not been initialized yet',
    );

    assert(
      _state == WorkerState.free,
      'Isolate must be free to execute request. State was $_state',
    );
    _cancelTimer();

    if (resumeCapability != null) {
      _isolate.resume(resumeCapability!);
      resumeCapability = null;

      _streamSubscription?.resume();
    }
    _sendPort?.send(event);
    _state = WorkerState.running;
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _receivePort.close();
    _isolate.kill();
  }
}

@pragma("vm:entry-point")
void _entryPoint(SendPort sendPort) {
  final recievePort = ReceivePort();

  sendPort.send(recievePort.sendPort);

  StreamSubscription? messagesSubscription;

  void messagesListener(dynamic message) async {
    if (message == 'finish') {
      messagesSubscription?.cancel();
      messagesSubscription = null;
      return;
    }

    if (message is! WorkItem) {
      return;
    }

    final workResult = message.work();

    final resultType = workResult.runtimeType;

    if (resultType is Future) {
      final res = await workResult;
      sendPort.send(res);
    } else {
      sendPort.send(workResult);
    }
  }

  messagesSubscription = recievePort.listen(messagesListener);
}

IsolatedWorker createWorker({
  required StreamSink<WorkResult> sink,
  required void Function() onNext,
}) =>
    IsolatedWorker(
      sink: sink,
      onNext: onNext,
    );
