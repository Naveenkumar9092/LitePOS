import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/company/models/company_model.dart";

void main() {
  group("Company & Shop Model Tests", () {
    test("BusinessCategory enum mappings are correct", () {
      expect(BusinessCategory.fromId(1), BusinessCategory.cafe);
      expect(BusinessCategory.fromId(2), BusinessCategory.foodCourt);
      expect(BusinessCategory.fromId(3), BusinessCategory.iceCreamAndDesserts);
      expect(BusinessCategory.fromId(99), BusinessCategory.cafe); // Fallback
    });

    test("CompanyProfileModel deserializes and serializes properly", () {
      final json = {
        "companyId": 10,
        "companyName": "Gelato Haven",
        "legalName": "Gelato Haven LLP",
        "businessType": 3,
        "gstin": "33AAAAA0000A1Z5",
        "pan": "AAAAA0000A",
        "email": "owner@gelatohaven.com",
        "mobileNumber": "9876543210",
        "website": "https://gelatohaven.com",
        "isActive": true,
        "shop": {
          "shopId": 20,
          "companyId": 10,
          "shopName": "Gelato Scoop Counter",
          "addressLine1": "Express Mall, Ground Floor",
          "city": "Chennai",
          "state": "Tamil Nadu",
          "pincode": "600002",
          "country": "India",
          "contactNumber": "9876543210",
          "email": "scoop@gelatohaven.com",
          "timeZone": "India Standard Time",
          "currencyCode": "INR",
          "isActive": true,
        }
      };

      final profile = CompanyProfileModel.fromJson(json);

      expect(profile.companyId, 10);
      expect(profile.companyName, "Gelato Haven");
      expect(profile.businessCategory, BusinessCategory.iceCreamAndDesserts);
      expect(profile.shop, isNotNull);
      expect(profile.shop!.shopName, "Gelato Scoop Counter");
      expect(profile.shop!.currencyCode, "INR");

      final serialized = profile.toJson();
      expect(serialized["companyName"], "Gelato Haven");
      expect(serialized["businessType"], 3);
    });
  });
}

