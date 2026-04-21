sealed class AppException implements Exception {
  final String message;
  final Object? origin;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.origin,
    this.stackTrace,
  });

  @override
  String toString() => message;
}

final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.origin,
    super.stackTrace,
  });
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException({
    required super.message,
    super.origin,
    super.stackTrace,
  });
}

final class ForbiddenException extends AppException {
  const ForbiddenException({
    required super.message,
    super.origin,
    super.stackTrace,
  });
}

final class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.origin,
    super.stackTrace,
  });
}

final class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.origin,
    super.stackTrace,
  });
}

final class VideoExtractionException extends AppException {
  const VideoExtractionException({
    required super.message,
    super.origin,
    super.stackTrace,
  });
}

final class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException({
    required super.message,
    this.statusCode,
    super.origin,
    super.stackTrace,
  });
}
