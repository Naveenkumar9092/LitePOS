import "package:flutter_test/flutter_test.dart";
import "package:billing_pos_app/features/orders/models/order_model.dart";
import "package:billing_pos_app/features/orders/presentation/order_state.dart";

void main() {
  group("OrderState Filtering Tests", () {
    final order1 = OrderModel(
      id: 1,
      orderGuid: "g1",
      orderNumber: "ORD-20261113-0001",
      customerName: "Rahul Sharma",
      customerMobile: "9876543210",
      orderType: OrderTypeEnum.counterSale,
      orderStatus: OrderStatusEnum.newOrder,
      subTotal: 200.0,
      grandTotal: 210.0,
      createdAt: DateTime.now(),
    );

    final order2 = OrderModel(
      id: 2,
      orderGuid: "g2",
      orderNumber: "ORD-20261113-0002",
      customerName: "Priya Patel",
      customerMobile: "9123456780",
      orderType: OrderTypeEnum.takeaway,
      orderStatus: OrderStatusEnum.confirmed,
      subTotal: 350.0,
      grandTotal: 367.5,
      createdAt: DateTime.now(),
    );

    final order3 = OrderModel(
      id: 3,
      orderGuid: "g3",
      orderNumber: "ORD-20261113-0003",
      orderType: OrderTypeEnum.counterSale,
      orderStatus: OrderStatusEnum.ready,
      subTotal: 100.0,
      grandTotal: 105.0,
      createdAt: DateTime.now(),
    );

    final historyOrder = OrderModel(
      id: 4,
      orderGuid: "g4",
      orderNumber: "ORD-20261112-0050",
      orderType: OrderTypeEnum.counterSale,
      orderStatus: OrderStatusEnum.completed,
      subTotal: 500.0,
      grandTotal: 525.0,
      createdAt: DateTime.now(),
    );

    test("displayedOrders returns all active orders when no filters set", () {
      final state = OrderState(orders: [order1, order2, order3]);
      expect(state.displayedOrders.length, 3);
    });

    test("displayedOrders filters by status correctly", () {
      final state = OrderState(
        orders: [order1, order2, order3],
        filterStatus: OrderStatusEnum.confirmed,
      );
      expect(state.displayedOrders.length, 1);
      expect(state.displayedOrders.first.id, 2);
    });

    test("displayedOrders filters by type correctly", () {
      final state = OrderState(
        orders: [order1, order2, order3],
        filterType: OrderTypeEnum.takeaway,
      );
      expect(state.displayedOrders.length, 1);
      expect(state.displayedOrders.first.id, 2);
    });

    test("displayedOrders searches by customer name, mobile, or order number", () {
      final stateNum = OrderState(orders: [order1, order2, order3], searchQuery: "0003");
      expect(stateNum.displayedOrders.length, 1);
      expect(stateNum.displayedOrders.first.id, 3);

      final stateCust = OrderState(orders: [order1, order2, order3], searchQuery: "Rahul");
      expect(stateCust.displayedOrders.length, 1);
      expect(stateCust.displayedOrders.first.id, 1);

      final statePhone = OrderState(orders: [order1, order2, order3], searchQuery: "91234");
      expect(statePhone.displayedOrders.length, 1);
      expect(statePhone.displayedOrders.first.id, 2);
    });

    test("displayedOrders displays history orders when isHistoryMode is true", () {
      final state = OrderState(
        orders: [order1, order2, order3],
        historyOrders: [historyOrder],
        isHistoryMode: true,
      );
      expect(state.displayedOrders.length, 1);
      expect(state.displayedOrders.first.orderStatus, OrderStatusEnum.completed);
    });
  });
}

