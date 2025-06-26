import 'package:dartz/dartz.dart';

typedef FutureEither<T> = Future<Either<dynamic, T>>;
typedef FutureVoid = Future<Either<dynamic, void>>;
