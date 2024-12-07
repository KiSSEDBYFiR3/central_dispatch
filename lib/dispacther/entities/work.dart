import 'dart:async';

typedef DispatchWork<T> = FutureOr<T> Function();

final class WorkItem {
  final String id;
  final DispatchWork work;

  const WorkItem({required this.id, required this.work});
}

final class WorkResult<T> {
  final String id;
  final T result;

  const WorkResult({required this.id, required this.result});
}
