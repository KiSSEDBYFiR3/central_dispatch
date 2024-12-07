import 'dart:async';
import 'dart:io';
import 'package:central_dispatch/dispatcher/implementations/pool_implementation.dart';
import 'package:central_dispatch/dispatcher/entities/work.dart';

abstract interface class IsolatedWorkersPool {
  factory IsolatedWorkersPool({int? isolatesMaxCount}) {
    isolatesMaxCount ??= Platform.numberOfProcessors;

    return DefaultIsolatesPool(
      isolatesMaxCount: isolatesMaxCount,
    );
  }

  int get currentIsolatesCount;

  Stream<WorkResult> get resultsStream;

  void execute(WorkItem event);

  void init();

  void dispose();
}
