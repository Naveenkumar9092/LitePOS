import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/core/network/api_response.dart";

void main() {
  group("ApiResponse Tests", () {
    test("ApiResponse deserializes standard success json response correctly", () {
      final json = {
        "success": true,
        "message": "Operation completed successfully",
        "data": {"status": "Healthy", "version": "1.0.0"},
        "errors": null,
      };

      final response = ApiResponse.fromJson(json, (data) => data as Map<String, dynamic>);

      expect(response.success, true);
      expect(response.message, "Operation completed successfully");
      expect(response.data!["status"], "Healthy");
      expect(response.errors, isNull);
    });

    test("ApiResponse deserializes error json response correctly", () {
      final json = {
        "success": false,
        "message": "Validation failed",
        "data": null,
        "errors": ["Field 'CompanyName' is required."],
      };

      final response = ApiResponse.fromJson(json, null);

      expect(response.success, false);
      expect(response.message, "Validation failed");
      expect(response.data, isNull);
      expect(response.errors!.length, 1);
      expect(response.errors!.first, "Field 'CompanyName' is required.");
    });
  });
}

