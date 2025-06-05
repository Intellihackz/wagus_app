import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pretty_string/pretty_string.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    log('Bloc ${bloc.runtimeType.toPrettier()} Change: ${change.toPrettier()}');
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    log('Bloc ${bloc.runtimeType.toPrettier()} Closed');
  }

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    log('Bloc ${bloc.runtimeType.toPrettier()} Created');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    log('Bloc ${bloc.runtimeType.toPrettier()} Error: ${error.toPrettier()}');
    log('StackTrace: $stackTrace');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    log('Bloc ${bloc.runtimeType.toPrettier()} Event: ${event?.toPrettier()}');
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    log('Bloc ${bloc.runtimeType.toPrettier()} Transition: ${transition.toPrettier()}');
  }
}
