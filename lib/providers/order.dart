import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';

import './cart.dart';

class OrderItem {
  final String id;
  final double amount;
  final List<CardItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Order with ChangeNotifier {
  List<OrderItem> _orders = [];
  final String authToken;
  final String authUserId;

  Order(this.authToken, this.authUserId, this._orders);

  List<OrderItem> get orders {
    return [..._orders];
  }

  Future<void> fetchAndSetOrders() async {
    final url =
        "https://my-shop-9ef09.firebaseio.com/orders/$authUserId.json?auth=$authToken";
    var response = await http.get(url);
    print(response.body);
    final List<OrderItem> loadedOrders = [];
    var extractedOrders = json.decode(response.body) as Map<String, dynamic>;
    if (extractedOrders == null) {
      return;
    }
    extractedOrders.forEach((orderId, orderData) {
      loadedOrders.add(
        OrderItem(
          id: orderId,
          amount: orderData["amount"],
          products: (orderData['products'] as List<dynamic>)
              .map(
                (item) => CardItem(
                  id: item['id'],
                  title: item['title'],
                  quantity: item['quantity'],
                  price: item['price'],
                ),
              )
              .toList(),
          dateTime: DateTime.parse(orderData['dateTime']),
        ),
      );
    });
    _orders = loadedOrders.reversed.toList();
    notifyListeners();
  }

  Future<void> addOrder(List<CardItem> cartProducts, double total) async {
    final time = DateTime.now();
    final url =
        "https://my-shop-9ef09.firebaseio.com/orders/$authUserId.json?auth=$authToken";
    var response = await http.post(url,
        body: json.encode({
          "amount": total,
          'dateTime': time.toIso8601String(),
          'products': cartProducts
              .map((e) => {
                    'id': e.id,
                    'title': e.title,
                    'quantity': e.quantity,
                    'price': e.price,
                  })
              .toList(),
        }));

    _orders.insert(
      0,
      OrderItem(
        id: json.decode(response.body)["name"],
        amount: total,
        products: cartProducts,
        dateTime: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
