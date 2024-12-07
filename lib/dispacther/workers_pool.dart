import 'dart:async';
import 'dart:io';
import 'package:central_dispatch/dispacther/implementations/pool_implementation.dart';
import 'package:central_dispatch/dispacther/entities/work.dart';

abstract interface class IsolatedWorkersPool {
  factory IsolatedWorkersPool({
    int isolatesMaxCount = 10,
  }) =>
      DefaultIsolatesPool(
        isolatesMaxCount: Platform.numberOfProcessors,
      );

  int get currentIsolatesCount;

  Stream<WorkResult> get resultsStream;

  void execute(WorkItem event);

  void init();

  void dispose();
}
