import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:privy_flutter/privy_flutter.dart';

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get success {
    if (this is Success<T>) return (this as Success<T>).value;
    throw StateError('Result is not Success');
  }

  Exception get failure {
    if (this is Failure<T>) return (this as Failure<T>).error;
    throw StateError('Result is not Failure');
  }
}

Future<void> emitFromAsyncStream<T, S>({
  required Stream<T> stream,
  required Future<S> Function(T data) onData,
  required Emitter<S> emit,
}) async {
  await for (final data in stream) {
    if (emit.isDone) break;
    final newState = await onData(data);
    if (!emit.isDone) emit(newState);
  }
}
