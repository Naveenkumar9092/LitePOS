import "dart:convert";
import "dart:typed_data";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/core/services/image_upload_service.dart";
import "package:billing_pos_app/shared/widgets/app_image_upload_picker.dart";

class MockAdapterSuccess implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final responsePayload = jsonEncode({
      "status": true,
      "image": "https://api.pozo.dev/pozo-common-image-api/upload?fileId=6af89b345077411ce166ff7f.png",
    });
    return ResponseBody.fromString(
      responsePayload,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class MockAdapterFailure implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      "Internal Server Error",
      500,
      headers: {
        Headers.contentTypeHeader: ["text/plain"],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group("ImageUploadService Tests", () {
    test("ImageUploadResult models success and failure results correctly", () {
      final success = ImageUploadResult.successful("https://api.pozo.dev/pozo-common-image-api/upload?fileId=test.png");
      expect(success.success, isTrue);
      expect(success.imageUrl, "https://api.pozo.dev/pozo-common-image-api/upload?fileId=test.png");
      expect(success.errorMessage, isNull);

      final failure = ImageUploadResult.failure("Upload error");
      expect(failure.success, isFalse);
      expect(failure.imageUrl, isNull);
      expect(failure.errorMessage, "Upload error");
    });

    test("uploadBytes successfully uploads and extracts image URL", () async {
      final dio = Dio();
      dio.httpClientAdapter = MockAdapterSuccess();
      final service = ImageUploadService(dio: dio);

      final dummyBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      final result = await service.uploadBytes(dummyBytes, fileName: "sample.png");

      expect(result.success, isTrue);
      expect(result.imageUrl, "https://api.pozo.dev/pozo-common-image-api/upload?fileId=6af89b345077411ce166ff7f.png");
    });

    test("uploadBytes handles server error gracefully", () async {
      final dio = Dio();
      dio.httpClientAdapter = MockAdapterFailure();
      final service = ImageUploadService(dio: dio);

      final dummyBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      final result = await service.uploadBytes(dummyBytes, fileName: "error.png");

      expect(result.success, isFalse);
      expect(result.imageUrl, isNull);
      expect(result.errorMessage, isNotNull);
    });
  });

  group("AppImageUploadPicker Widget Tests", () {
    testWidgets("renders empty upload state properly", (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppImageUploadPicker(
              label: "Product Image",
              onImageUploaded: (_) {},
            ),
          ),
        ),
      );

      expect(find.text("Product Image"), findsOneWidget);
      expect(find.text("No image selected"), findsOneWidget);
      expect(find.text("Upload Image"), findsOneWidget);
      expect(find.text("Edit URL Directly"), findsOneWidget);
    });

    testWidgets("renders preloaded image with Change and Remove buttons", (tester) async {
      bool removed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppImageUploadPicker(
              label: "Product Image",
              initialImageUrl: "https://api.pozo.dev/pozo-common-image-api/upload?fileId=sample.png",
              onImageUploaded: (_) {},
              onImageRemoved: () => removed = true,
            ),
          ),
        ),
      );

      expect(find.text("Product Image"), findsOneWidget);
      expect(find.text("Image Loaded"), findsOneWidget);
      expect(find.text("Change Image"), findsOneWidget);
      expect(find.text("Remove"), findsOneWidget);

      await tester.tap(find.text("Remove"));
      await tester.pump();

      expect(removed, isTrue);
      expect(find.text("No image selected"), findsOneWidget);
    });

    testWidgets("toggling manual URL editor allows custom URL entry", (tester) async {
      String? enteredUrl;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppImageUploadPicker(
              label: "Category Image",
              onImageUploaded: (url) => enteredUrl = url,
            ),
          ),
        ),
      );

      // Tap Edit URL Directly
      await tester.tap(find.text("Edit URL Directly"));
      await tester.pump();

      expect(find.text("Hide URL"), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), "https://api.pozo.dev/pozo-common-image-api/upload?fileId=123.png");
      await tester.pump();

      expect(enteredUrl, "https://api.pozo.dev/pozo-common-image-api/upload?fileId=123.png");
    });
  });
}
