import 'dart:async';
import 'dart:isolate';

import 'package:central_dispatch/dispacther/concurrent_worker.dart';
import 'package:central_dispatch/dispacther/entities/work.dart';
import 'package:central_dispatch/dispacther/entities/worker_state.dart';

final class IsolatedWorker implements ConcurrentWorker {
  late final Isolate _isolate;

  final ReceivePort _receivePort;

  final StreamSink<WorkResult> _sink;

  final void Function() _onNext;

  WorkerState get state => _state;

  WorkerState _state = WorkerState.sleeping;

  SendPort? _sendPort;

  StreamSubscription? _streamSubscription;

  IsolatedWorker({
    required StreamSink<WorkResult> sink,
    required void Function() onNext,
  })  : _receivePort = ReceivePort(),
        _sink = sink,
        _onNext = onNext;

  @override
  bool get isFree => _state == WorkerState.free;

  @override
  Future<void> init() async {
    if (_state == WorkerState.sleeping) return;

    _isolate = await Isolate.spawn(
      _entry,
      _receivePort.sendPort,
    );

    _streamSubscription = _receivePort.listen(
      (data) {
        switch (data.runtimeType) {
          case const (SendPort):
            _sendPort = data;
          case const (WorkResult):
            _sink.add(data);
            _onNext();
        }
      },
    );

    _state = WorkerState.free;
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

void _entry(SendPort sendPort) {
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
