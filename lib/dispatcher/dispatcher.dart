import 'dart:async';

import 'package:central_dispatch/dispatcher/entities/work.dart';

abstract interface class Dispatcher {
  FutureOr<T> dispatchEvent<T>(DispatchWork<T> work);

  void dispose();
}
