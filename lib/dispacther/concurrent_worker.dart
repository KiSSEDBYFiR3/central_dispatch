import 'package:central_dispatch/dispacther/entities/work.dart';

abstract interface class ConcurrentWorker {
  Future<void> init();

  void dispose();

  void execute(DispatchWork event);

  bool get isFree;
}
