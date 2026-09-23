import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryConfig {
  static const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const uploadPreset =
      String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  static bool get isConfigured =>
      cloudName.isNotEmpty && uploadPreset.isNotEmpty;
}

class CloudinaryService {
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String? folder,
  }) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const CloudinaryException(
        'Cloudinary не настроен. Запусти приложение с CLOUDINARY_CLOUD_NAME и CLOUDINARY_UPLOAD_PRESET.',
      );
    }
    if (bytes.isEmpty) {
      throw const CloudinaryException('Выбранный файл пустой.');
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = CloudinaryConfig.uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );
    if (folder != null && folder.isNotEmpty) {
      request.fields['folder'] = folder;
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      // Keep the HTTP status in the error below when Cloudinary returns HTML.
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data['error'] is Map
          ? (data['error']['message'] ?? 'Неизвестная ошибка Cloudinary')
          : 'Cloudinary вернул HTTP ${response.statusCode}';
      throw CloudinaryException(message.toString());
    }

    final url = data['secure_url'];
    if (url is! String || url.isEmpty) {
      throw const CloudinaryException(
          'Cloudinary не вернул ссылку на изображение.');
    }
    return url;
  }
}

class CloudinaryException implements Exception {
  final String message;
  const CloudinaryException(this.message);

  @override
  String toString() => message;
}
