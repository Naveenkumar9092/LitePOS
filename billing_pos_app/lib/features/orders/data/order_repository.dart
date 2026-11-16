import "package:sqflite/sqflite.dart";
import "package:billing_pos_app/core/constants/api_endpoints.dart";
import "package:billing_pos_app/core/database/app_database.dart";
import "package:billing_pos_app/core/database/database_tables.dart";
import "package:billing_pos_app/core/network/api_response.dart";
import "package:billing_pos_app/core/network/dio_client.dart";
import "../models/order_model.dart";

class OrderRepository {
  final DioClient _dioClient;
  final AppDatabase _db;

  OrderRepository(this._dioClient, this._db);

  /// Fetch orders with optional status, type, and search filters
  Future<ApiResponse<PagedOrdersResponse>> getOrders(OrderFilterParams filter) async {
    try {
      final response = await _dioClient.get(
        ApiEndpoints.orders,
        queryParameters: filter.toQueryParams(),
      );

      if (response.success && response.data != null) {
        final pagedResult = PagedOrdersResponse.fromJson(response.data as Map<String, dynamic>);
        // Cache to SQLite
        for (final order in pagedResult.items) {
          await _cacheOrderLocally(order);
        }
        return ApiResponse<PagedOrdersResponse>(
          success: true,
          message: response.message,
          data: pagedResult,
        );
      }
    } catch (_) {
      // Offline fallback
    }

    return await _getOfflineOrders(filter);
  }

  /// Get order details by ID
  Future<ApiResponse<OrderModel>> getOrderById(int id) async {
    try {
      final response = await _dioClient.get("${ApiEndpoints.orders}/$id");
      if (response.success && response.data != null) {
        final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheOrderLocally(order);
        return ApiResponse<OrderModel>(
          success: true,
          message: response.message,
          data: order,
        );
      }
    } catch (_) {
      // Offline fallback
    }

    return await _getOfflineOrderById(id);
  }

  /// Create a new order (Counter Sale or Takeaway)
  Future<ApiResponse<OrderModel>> createOrder(CreateOrderRequest request) async {
    try {
      final response = await _dioClient.post(
        ApiEndpoints.orders,
        data: request.toJson(),
      );

      if (response.success && response.data != null) {
        final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheOrderLocally(order);
        return ApiResponse<OrderModel>(
          success: true,
          message: response.message,
          data: order,
        );
      }
      return ApiResponse<OrderModel>(
        success: false,
        message: response.message,
      );
    } catch (_) {
      // Create offline order
      return await _createOfflineOrder(request);
    }
  }

  /// Update order status
  Future<ApiResponse<OrderModel>> updateOrderStatus(int id, OrderStatusEnum status, {String? notes}) async {
    try {
      final response = await _dioClient.put(
        "${ApiEndpoints.orders}/$id/status",
        data: {
          "newStatus": status.value,
          if (notes != null && notes.isNotEmpty) "notes": notes,
        },
      );

      if (response.success && response.data != null) {
        final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheOrderLocally(order);
        return ApiResponse<OrderModel>(
          success: true,
          message: response.message,
          data: order,
        );
      }
      return ApiResponse<OrderModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      // Offline fallback: update local record
      await _updateOfflineOrderStatus(id, status.value);
      final offlineOrder = await _getOfflineOrderById(id);
      return offlineOrder;
    }
  }

  /// Cancel an order with a reason
  Future<ApiResponse<OrderModel>> cancelOrder(int id, String reason) async {
    try {
      final response = await _dioClient.post(
        "${ApiEndpoints.orders}/$id/cancel",
        data: {
          "reason": reason,
        },
      );

      if (response.success && response.data != null) {
        final order = OrderModel.fromJson(response.data as Map<String, dynamic>);
        await _cacheOrderLocally(order);
        return ApiResponse<OrderModel>(
          success: true,
          message: response.message,
          data: order,
        );
      }
      return ApiResponse<OrderModel>(
        success: false,
        message: response.message,
      );
    } catch (e) {
      // Offline fallback: cancel local record
      await _updateOfflineOrderStatus(id, OrderStatusEnum.cancelled.value, updatedBy: reason);
      final offlineOrder = await _getOfflineOrderById(id);
      return offlineOrder;
    }
  }

  /// Get completed and cancelled order history
  Future<ApiResponse<PagedOrdersResponse>> getOrderHistory(OrderFilterParams filter) async {
    try {
      final response = await _dioClient.get(
        "${ApiEndpoints.orders}/history",
        queryParameters: filter.toQueryParams(),
      );

      if (response.success && response.data != null) {
        final pagedResult = PagedOrdersResponse.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse<PagedOrdersResponse>(
          success: true,
          message: response.message,
          data: pagedResult,
        );
      }
    } catch (_) {
      // Offline fallback
    }

    return await _getOfflineOrderHistory(filter);
  }

  // --- SQLite Offline Cache & Persistence ---

  Future<void> _cacheOrderLocally(OrderModel order) async {
    try {
      final db = await _db.database;
      final orderMap = {
        "OrderId": order.id,
        "OrderGuid": order.orderGuid,
        "OrderNumber": order.orderNumber,
        "CustomerId": order.customerId,
        "OrderType": order.orderType.value,
        "OrderStatus": order.orderStatus.value,
        "SubTotal": order.subTotal,
        "DiscountAmount": order.discountAmount,
        "TaxAmount": order.taxAmount,
        "GrandTotal": order.grandTotal,
        "CreatedBy": order.cashierUsername.isNotEmpty ? order.cashierUsername : (order.createdBy ?? "Cashier"),
        "CreatedAtUTC": order.createdAt.toUtc().toIso8601String(),
        "UpdatedAtUTC": order.updatedAt?.toUtc().toIso8601String(),
      };

      await db.insert(
        DatabaseTables.localOrder,
        orderMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Cache details
      await db.delete(
        DatabaseTables.localOrderDetail,
        where: "OrderId = ?",
        whereArgs: [order.id],
      );

      for (final detail in order.details) {
        final detailMap = {
          "OrderId": order.id,
          "ProductId": detail.productId,
          "ProductNameSnapshot": detail.productName,
          "UnitPrice": detail.unitPrice,
          "Quantity": detail.quantity,
          "DiscountAmount": detail.discountAmount,
          "TaxPercentage": detail.taxPercentage,
          "TaxAmount": detail.taxAmount,
          "LineTotal": detail.lineTotal,
        };
        await db.insert(DatabaseTables.localOrderDetail, detailMap);
      }
    } catch (_) {
      // Ignore cache write errors
    }
  }

  Future<ApiResponse<PagedOrdersResponse>> _getOfflineOrders(OrderFilterParams filter) async {
    try {
      final db = await _db.database;
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      if (filter.status != null) {
        whereClauses.add("OrderStatus = ?");
        whereArgs.add(filter.status!.value);
      }

      if (filter.type != null) {
        whereClauses.add("OrderType = ?");
        whereArgs.add(filter.type!.value);
      }

      final whereString = whereClauses.isNotEmpty ? whereClauses.join(" AND ") : null;

      final countResult = await db.rawQuery(
        "SELECT COUNT(*) FROM ${DatabaseTables.localOrder}${whereString != null ? ' WHERE $whereString' : ''}",
        whereArgs,
      );
      final totalCount = Sqflite.firstIntValue(countResult) ?? 0;

      final offset = (filter.page - 1) * filter.pageSize;
      final rows = await db.query(
        DatabaseTables.localOrder,
        where: whereString,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: "CreatedAtUTC DESC",
        limit: filter.pageSize,
        offset: offset,
      );

      final items = <OrderModel>[];
      for (final row in rows) {
        final orderId = row["OrderId"] as int;
        final detailRows = await db.query(
          DatabaseTables.localOrderDetail,
          where: "OrderId = ?",
          whereArgs: [orderId],
        );

        final details = detailRows.map((d) => OrderDetailModel.fromJson(d)).toList();

        items.add(OrderModel(
          id: orderId,
          orderGuid: row["OrderGuid"] as String? ?? "",
          orderNumber: row["OrderNumber"] as String? ?? "",
          customerId: row["CustomerId"] as int?,
          orderType: OrderTypeEnum.fromValue(row["OrderType"]),
          orderStatus: OrderStatusEnum.fromValue(row["OrderStatus"]),
          subTotal: (row["SubTotal"] as num?)?.toDouble() ?? 0.0,
          discountAmount: (row["DiscountAmount"] as num?)?.toDouble() ?? 0.0,
          taxAmount: (row["TaxAmount"] as num?)?.toDouble() ?? 0.0,
          grandTotal: (row["GrandTotal"] as num?)?.toDouble() ?? 0.0,
          cashierUsername: row["CreatedBy"] as String? ?? "",
          createdAt: DateTime.tryParse(row["CreatedAtUTC"] as String? ?? "") ?? DateTime.now(),
          updatedAt: row["UpdatedAtUTC"] != null ? DateTime.tryParse(row["UpdatedAtUTC"] as String) : null,
          details: details,
        ));
      }

      final totalPages = filter.pageSize > 0 ? (totalCount / filter.pageSize).ceil() : 0;
      return ApiResponse<PagedOrdersResponse>(
        success: true,
        message: "Offline orders loaded",
        data: PagedOrdersResponse(
          items: items,
          totalCount: totalCount,
          pageNumber: filter.page,
          pageSize: filter.pageSize,
          totalPages: totalPages,
        ),
      );
    } catch (e) {
      return ApiResponse<PagedOrdersResponse>(
        success: false,
        message: "Failed to load local orders: $e",
      );
    }
  }

  Future<ApiResponse<OrderModel>> _getOfflineOrderById(int id) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        DatabaseTables.localOrder,
        where: "OrderId = ?",
        whereArgs: [id],
      );

      if (rows.isEmpty) {
        return ApiResponse<OrderModel>(
          success: false,
          message: "Order not found locally.",
        );
      }

      final row = rows.first;
      final detailRows = await db.query(
        DatabaseTables.localOrderDetail,
        where: "OrderId = ?",
        whereArgs: [id],
      );
      final details = detailRows.map((d) => OrderDetailModel.fromJson(d)).toList();

      final order = OrderModel(
        id: id,
        orderGuid: row["OrderGuid"] as String? ?? "",
        orderNumber: row["OrderNumber"] as String? ?? "",
        customerId: row["CustomerId"] as int?,
        orderType: OrderTypeEnum.fromValue(row["OrderType"]),
        orderStatus: OrderStatusEnum.fromValue(row["OrderStatus"]),
        subTotal: (row["SubTotal"] as num?)?.toDouble() ?? 0.0,
        discountAmount: (row["DiscountAmount"] as num?)?.toDouble() ?? 0.0,
        taxAmount: (row["TaxAmount"] as num?)?.toDouble() ?? 0.0,
        grandTotal: (row["GrandTotal"] as num?)?.toDouble() ?? 0.0,
        cashierUsername: row["CreatedBy"] as String? ?? "",
        createdAt: DateTime.tryParse(row["CreatedAtUTC"] as String? ?? "") ?? DateTime.now(),
        updatedAt: row["UpdatedAtUTC"] != null ? DateTime.tryParse(row["UpdatedAtUTC"] as String) : null,
        details: details,
      );

      return ApiResponse<OrderModel>(
        success: true,
        message: "Order loaded locally",
        data: order,
      );
    } catch (e) {
      return ApiResponse<OrderModel>(
        success: false,
        message: "Failed to load local order: $e",
      );
    }
  }

  Future<ApiResponse<OrderModel>> _createOfflineOrder(CreateOrderRequest request) async {
    try {
      final db = await _db.database;
      final now = DateTime.now().toUtc();
      final count = Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM ${DatabaseTables.localOrder}")) ?? 0;
      final orderNumber = "ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(count + 1).toString().padLeft(4, '0')}";

      double subTotal = 0.0;
      double totalTax = 0.0;
      for (final item in request.items) {
        final itemSub = item.quantity * item.unitPrice;
        final itemTaxable = (itemSub - item.discountAmount) > 0 ? (itemSub - item.discountAmount) : 0.0;
        final itemTax = itemTaxable * (item.taxPercentage / 100);
        subTotal += itemSub;
        totalTax += itemTax;
      }
      final taxable = (subTotal - request.discountAmount) > 0 ? (subTotal - request.discountAmount) : 0.0;
      final grandTotal = taxable + totalTax;

      final orderMap = {
        "OrderGuid": "${DateTime.now().millisecondsSinceEpoch}",
        "OrderNumber": orderNumber,
        "CustomerId": request.customerId,
        "OrderType": request.orderType.value,
        "OrderStatus": OrderStatusEnum.newOrder.value,
        "SubTotal": subTotal,
        "DiscountAmount": request.discountAmount,
        "TaxAmount": totalTax,
        "GrandTotal": grandTotal,
        "CreatedBy": "Cashier",
        "CreatedAtUTC": now.toIso8601String(),
      };

      final orderId = await db.insert(DatabaseTables.localOrder, orderMap);

      final details = <OrderDetailModel>[];
      for (final item in request.items) {
        final itemSub = item.quantity * item.unitPrice;
        final itemTaxable = (itemSub - item.discountAmount) > 0 ? (itemSub - item.discountAmount) : 0.0;
        final itemTax = itemTaxable * (item.taxPercentage / 100);
        final lineTotal = itemTaxable + itemTax;

        final detailMap = {
          "OrderId": orderId,
          "ProductId": item.productId,
          "ProductNameSnapshot": item.productNameSnapshot ?? "Product ${item.productId}",
          "UnitPrice": item.unitPrice,
          "Quantity": item.quantity,
          "DiscountAmount": item.discountAmount,
          "TaxPercentage": item.taxPercentage,
          "TaxAmount": itemTax,
          "LineTotal": lineTotal,
        };
        final detailId = await db.insert(DatabaseTables.localOrderDetail, detailMap);
        details.add(OrderDetailModel(
          id: detailId,
          orderId: orderId,
          productId: item.productId,
          productName: item.productNameSnapshot ?? "Product ${item.productId}",
          unitPrice: item.unitPrice,
          quantity: item.quantity,
          discountAmount: item.discountAmount,
          taxPercentage: item.taxPercentage,
          taxAmount: itemTax,
          lineTotal: lineTotal,
        ));
      }

      final createdOrder = OrderModel(
        id: orderId,
        orderGuid: orderMap["OrderGuid"] as String,
        orderNumber: orderNumber,
        customerId: request.customerId,
        orderType: request.orderType,
        orderStatus: OrderStatusEnum.newOrder,
        subTotal: subTotal,
        discountAmount: request.discountAmount,
        taxAmount: totalTax,
        grandTotal: grandTotal,
        cashierUsername: "Cashier",
        createdAt: now,
        details: details,
      );

      return ApiResponse<OrderModel>(
        success: true,
        message: "Order created offline.",
        data: createdOrder,
      );
    } catch (e) {
      return ApiResponse<OrderModel>(
        success: false,
        message: "Failed to create offline order: $e",
      );
    }
  }

  Future<void> _updateOfflineOrderStatus(int id, int statusValue, {String? updatedBy}) async {
    try {
      final db = await _db.database;
      final updateMap = <String, dynamic>{
        "OrderStatus": statusValue,
        "UpdatedAtUTC": DateTime.now().toUtc().toIso8601String(),
      };
      if (updatedBy != null) {
        updateMap["CreatedBy"] = updatedBy;
      }
      await db.update(
        DatabaseTables.localOrder,
        updateMap,
        where: "OrderId = ?",
        whereArgs: [id],
      );
    } catch (_) {}
  }

  Future<ApiResponse<PagedOrdersResponse>> _getOfflineOrderHistory(OrderFilterParams filter) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        DatabaseTables.localOrder,
        where: "OrderStatus IN (?, ?)",
        whereArgs: [OrderStatusEnum.completed.value, OrderStatusEnum.cancelled.value],
        orderBy: "CreatedAtUTC DESC",
      );

      final items = <OrderModel>[];
      for (final row in rows) {
        final orderId = row["OrderId"] as int;
        final detailRows = await db.query(
          DatabaseTables.localOrderDetail,
          where: "OrderId = ?",
          whereArgs: [orderId],
        );
        final details = detailRows.map((d) => OrderDetailModel.fromJson(d)).toList();

        items.add(OrderModel(
          id: orderId,
          orderGuid: row["OrderGuid"] as String? ?? "",
          orderNumber: row["OrderNumber"] as String? ?? "",
          customerId: row["CustomerId"] as int?,
          orderType: OrderTypeEnum.fromValue(row["OrderType"]),
          orderStatus: OrderStatusEnum.fromValue(row["OrderStatus"]),
          subTotal: (row["SubTotal"] as num?)?.toDouble() ?? 0.0,
          discountAmount: (row["DiscountAmount"] as num?)?.toDouble() ?? 0.0,
          taxAmount: (row["TaxAmount"] as num?)?.toDouble() ?? 0.0,
          grandTotal: (row["GrandTotal"] as num?)?.toDouble() ?? 0.0,
          cashierUsername: row["CreatedBy"] as String? ?? "",
          createdAt: DateTime.tryParse(row["CreatedAtUTC"] as String? ?? "") ?? DateTime.now(),
          updatedAt: row["UpdatedAtUTC"] != null ? DateTime.tryParse(row["UpdatedAtUTC"] as String) : null,
          details: details,
        ));
      }

      return ApiResponse<PagedOrdersResponse>(
        success: true,
        message: "Offline order history loaded",
        data: PagedOrdersResponse(
          items: items,
          totalCount: items.length,
          pageNumber: 1,
          pageSize: items.isNotEmpty ? items.length : 20,
          totalPages: 1,
        ),
      );
    } catch (e) {
      return ApiResponse<PagedOrdersResponse>(
        success: false,
        message: "Failed to load local order history: $e",
      );
    }
  }
}
