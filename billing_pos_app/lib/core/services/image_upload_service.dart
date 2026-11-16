import "dart:typed_data";
import "package:dio/dio.dart";
import "package:file_picker/file_picker.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "../constants/api_endpoints.dart";

final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  return ImageUploadService();
});

class ImageUploadResult {
  final bool success;
  final String? imageUrl;
  final String? errorMessage;

  const ImageUploadResult({
    required this.success,
    this.imageUrl,
    this.errorMessage,
  });

  factory ImageUploadResult.successful(String url) {
    return ImageUploadResult(success: true, imageUrl: url);
  }

  factory ImageUploadResult.failure(String message) {
    return ImageUploadResult(success: false, errorMessage: message);
  }
}

class ImageUploadService {
  final Dio _dio;

  ImageUploadService({Dio? dio}) : _dio = dio ?? Dio();

  /// Opens file picker to select an image, uploads it, and returns the uploaded image URL.
  Future<ImageUploadResult> pickAndUploadImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["jpg", "jpeg", "png", "webp"],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return ImageUploadResult.failure("No file selected.");
      }

      final file = result.files.first;
      Uint8List? fileBytes = file.bytes;

      if (fileBytes == null) {
        try {
          fileBytes = await file.xFile.readAsBytes();
        } catch (_) {
          fileBytes = null;
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        return ImageUploadResult.failure("Failed to read image data.");
      }

      // Check max size: 10MB
      if (fileBytes.lengthInBytes > 10 * 1024 * 1024) {
        return ImageUploadResult.failure("Image size exceeds 10MB limit.");
      }

      final fileName = file.name.isNotEmpty ? file.name : "upload.png";
      return await uploadBytes(fileBytes, fileName: fileName);
    } catch (e) {
      return ImageUploadResult.failure("Error selecting image: $e");
    }
  }

  /// Uploads binary image bytes directly to the POZO image upload endpoint.
  Future<ImageUploadResult> uploadBytes(
    Uint8List bytes, {
    String fileName = "image.png",
  }) async {
    try {
      final formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiEndpoints.commonImageUploadUrl,
        data: formData,
        options: Options(
          headers: {
            "Accept": "application/json",
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        if (data is Map) {
          final isSuccess = data["status"] == true;
          final imageUrl = data["image"]?.toString();
          if (isSuccess && imageUrl != null && imageUrl.isNotEmpty) {
            return ImageUploadResult.successful(imageUrl);
          }
        }
      }

      return ImageUploadResult.failure(
        "Failed to upload image. Server returned: ${response.statusCode}",
      );
    } on DioException catch (dioErr) {
      final msg = dioErr.response?.data?.toString() ?? dioErr.message ?? "Network error";
      return ImageUploadResult.failure("Upload error: $msg");
    } catch (e) {
      return ImageUploadResult.failure("Upload failed: $e");
    }
  }
}
