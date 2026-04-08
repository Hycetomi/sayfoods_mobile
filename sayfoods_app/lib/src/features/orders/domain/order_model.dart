import 'package:sayfoods_app/src/features/products/domain/product_model.dart';
import 'package:intl/intl.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double priceAtPurchase;
  final Product? product; // The joined product relation

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.priceAtPurchase,
    this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'].toString(),
      orderId: json['order_id'].toString(),
      productId: json['product_id'].toString(),
      quantity: json['quantity'] as int? ?? 1,
      priceAtPurchase: (json['price_at_purchase'] as num?)?.toDouble() ?? 0.0,
      product: json['products'] != null 
          ? Product.fromJson(json['products'] as Map<String, dynamic>) 
          : null,
    );
  }
}

class OrderModel {
  final String id;
  final String clientId;
  final String status;
  final String deliveryAddress;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String paymentStatus;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  OrderModel({
    required this.id,
    required this.clientId,
    required this.status,
    required this.deliveryAddress,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentStatus,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['order_items'] as List<dynamic>? ?? [];
    List<OrderItemModel> mappedItems = rawItems
        .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return OrderModel(
      id: json['id'].toString(),
      clientId: json['client_id'].toString(),
      status: json['status']?.toString() ?? 'pending',
      deliveryAddress: json['delivery_address']?.toString() ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now(),
      items: mappedItems,
    );
  }

  // Formatting helpers
  String get formattedTime => DateFormat('h:mm a').format(createdAt);
  
  String get displayTitle {
    if (items.isEmpty) return 'Empty Order';
    if (items.length == 1) {
      return items.first.product?.name ?? 'Unknown Product';
    } else if (items.length == 2) {
      final p1 = items[0].product?.name ?? 'Item';
      final p2 = items[1].product?.name ?? 'Item';
      return '$p1 and $p2';
    } else {
      final p1 = items.first.product?.name ?? 'Item';
      return '$p1 & ${items.length - 1} others';
    }
  }

  String get displayImage {
    if (items.isNotEmpty && items.first.product != null && items.first.product!.imageUrl.isNotEmpty) {
      return items.first.product!.imageUrl;
    }
    return 'assets/images/meat.png'; // Fallback
  }
}
