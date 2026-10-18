/// Exception thrown when image processing fails (decode error, corrupt input, etc.).
class ImageProcessingException implements Exception {
  final String message;

  const ImageProcessingException(this.message);

  @override
  String toString() => 'ImageProcessingException: $message';
}
