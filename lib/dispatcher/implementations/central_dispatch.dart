import 'dart:async';
import 'dart:collection';
import 'package:central_dispatch/dispatcher/dispatcher.dart';
import 'package:central_dispatch/dispatcher/entities/work.dart';
import 'package:central_dispatch/dispatcher/workers_pool.dart';
import 'package:uuid/uuid.dart';

final class CentralDispatch implements Dispatcher {
  final IsolatedWorkersPool _pool;

  StreamSubscription<WorkResult>? _resultsSub;

  final HashMap<String, Completer> _dispatchTable = HashMap(
    equals: (p0, p1) => p0 == p1,
    hashCode: (p0) =>
        (p0.hashCode & p0.length) *
        p0.codeUnits.fold(0, (prev, curr) => prev + curr).hashCode,
  );

  CentralDispatch({
    IsolatedWorkersPool? pool,
  }) : _pool = pool ?? IsolatedWorkersPool() {
    _pool.init();
    _resultsSub = _pool.resultsStream.listen(_resultsListener);
  }

  void _resultsListener(WorkResult workResult) {
    final resultHook = _dispatchTable[workResult.id];

    if (resultHook == null) return;

    resultHook.complete(workResult.result);
  }

  @override
  void dispose() {
    _resultsSub?.cancel();
    _resultsSub = null;
    _pool.dispose();
  }

  @override
  FutureOr<T> dispatchEvent<T>(DispatchWork<T> work) {
    final id = const Uuid().v4();

    final workItem = WorkItem(
      id: id,
      work: work,
    );

    _pool.execute(workItem);

    final resultHook = Completer<T>();

    _dispatchTable[id] = resultHook;

    return resultHook.future;
  }
}
