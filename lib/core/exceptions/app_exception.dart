abstract class AppException implements Exception {
  final String message;
  final Object? origin;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.origin,
    this.stackTrace,
  });

  String get userMessage => message;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException({
    required super.message,
    this.statusCode,
    super.origin,
    super.stackTrace,
  });

  @override
  String get userMessage {
    if (statusCode != null) return 'Server xatosi ($statusCode)';
    return 'Internet aloqasi yo\'q yoki server javob bermayapti';
  }
}

class UnauthorizedException extends AppException {
  const UnauthorizedException({
    super.message = 'Autentifikatsiya talab qilinadi',
    super.origin,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Iltimos, qayta kiring';
}

class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'Ruxsat yo\'q',
    super.origin,
    super.stackTrace,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Ma\'lumot topilmadi',
    super.origin,
    super.stackTrace,
  });
}

class ConflictException extends AppException {
  const ConflictException({
    required super.message,
    super.origin,
    super.stackTrace,
  });
}

class ValidationException extends AppException {
  final Map<String, List<String>>? fields;

  const ValidationException({
    required super.message,
    this.fields,
    super.origin,
    super.stackTrace,
  });
}

class VideoExtractionException extends AppException {
  const VideoExtractionException({
    required super.message,
    super.origin,
    super.stackTrace,
  });

  @override
  String get userMessage =>
      'Video yuklab bo\'lmadi. Boshqa URL kiriting yoki keyinroq urinib ko\'ring.';
}

class ServerException extends AppException {
  const ServerException({
    super.message = 'Server ichki xatosi',
    super.origin,
    super.stackTrace,
  });

  @override
  String get userMessage => 'Server xatosi yuz berdi. Keyinroq urinib ko\'ring.';
}
