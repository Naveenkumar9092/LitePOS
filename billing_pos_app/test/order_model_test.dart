import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/orders/models/order_model.dart";

void main() {
  group("OrderModel & Enums Tests", () {
    test("OrderStatusEnum correctly maps values and strings", () {
      expect(OrderStatusEnum.fromValue(1), OrderStatusEnum.newOrder);
      expect(OrderStatusEnum.fromValue("Confirmed"), OrderStatusEnum.confirmed);
      expect(OrderStatusEnum.fromValue("Preparing"), OrderStatusEnum.preparing);
      expect(OrderStatusEnum.fromValue("Ready"), OrderStatusEnum.ready);
      expect(OrderStatusEnum.fromValue("Completed"), OrderStatusEnum.completed);
      expect(OrderStatusEnum.fromValue("Cancelled"), OrderStatusEnum.cancelled);
      expect(OrderStatusEnum.fromValue(99), OrderStatusEnum.newOrder);
    });

    test("OrderTypeEnum correctly maps counterSale and takeaway", () {
      expect(OrderTypeEnum.fromValue(1), OrderTypeEnum.counterSale);
      expect(OrderTypeEnum.fromValue("CounterSale"), OrderTypeEnum.counterSale);
      expect(OrderTypeEnum.fromValue(2), OrderTypeEnum.takeaway);
      expect(OrderTypeEnum.fromValue("Takeaway"), OrderTypeEnum.takeaway);
    });

    test("OrderDetailModel correctly parses JSON and serializes to JSON", () {
      final json = {
        "id": 10,
        "orderId": 5,
        "productId": 101,
        "productNameSnapshot": "Cold Coffee",
        "unitPrice": 120.0,
        "quantity": 2,
        "discountAmount": 10.0,
        "taxPercentage": 5.0,
        "taxAmount": 11.5,
        "lineTotal": 241.5,
      };

      final detail = OrderDetailModel.fromJson(json);

      expect(detail.id, 10);
      expect(detail.orderId, 5);
      expect(detail.productId, 101);
      expect(detail.productName, "Cold Coffee");
      expect(detail.unitPrice, 120.0);
      expect(detail.quantity, 2);
      expect(detail.discountAmount, 10.0);
      expect(detail.taxPercentage, 5.0);
      expect(detail.taxAmount, 11.5);
      expect(detail.lineTotal, 241.5);

      final outJson = detail.toJson();
      expect(outJson["productId"], 101);
      expect(outJson["lineTotal"], 241.5);
    });

    test("OrderModel correctly parses full order JSON with nested details", () {
      final json = {
        "id": 1,
        "orderGuid": "a1b2c3d4",
        "orderNumber": "ORD-20261113-0001",
        "customerId": 3,
        "customerName": "Alice Smith",
        "customerMobile": "9876543210",
        "orderType": 2, // Takeaway
        "orderStatus": 2, // Confirmed
        "subTotal": 300.0,
        "discountAmount": 20.0,
        "taxAmount": 14.0,
        "grandTotal": 294.0,
        "cashierUsername": "cashier1",
        "createdAtUtc": "2026-11-13T10:00:00Z",
        "details": [
          {
            "id": 1,
            "orderId": 1,
            "productId": 2,
            "productNameSnapshot": "Carrot Cake",
            "unitPrice": 150.0,
            "quantity": 2,
            "discountAmount": 20.0,
            "taxPercentage": 5.0,
            "taxAmount": 14.0,
            "lineTotal": 294.0,
          }
        ],
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, 1);
      expect(order.orderNumber, "ORD-20261113-0001");
      expect(order.customerId, 3);
      expect(order.customerName, "Alice Smith");
      expect(order.orderType, OrderTypeEnum.takeaway);
      expect(order.orderStatus, OrderStatusEnum.confirmed);
      expect(order.subTotal, 300.0);
      expect(order.discountAmount, 20.0);
      expect(order.grandTotal, 294.0);
      expect(order.details.length, 1);
      expect(order.details.first.productName, "Carrot Cake");
    });

    test("OrderFilterParams generates correct query parameters", () {
      final filter = OrderFilterParams(
        status: OrderStatusEnum.confirmed,
        type: OrderTypeEnum.counterSale,
        searchTerm: "Alice",
        page: 2,
        pageSize: 15,
      );

      final params = filter.toQueryParams();
      expect(params["status"], OrderStatusEnum.confirmed.value);
      expect(params["type"], OrderTypeEnum.counterSale.value);
      expect(params["search"], "Alice");
      expect(params["page"], 2);
      expect(params["pageSize"], 15);
    });
  });
}

