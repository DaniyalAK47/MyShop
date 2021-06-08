import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class CardItem {
  final String id;
  final String title;
  final int quantity;
  final double price;

  CardItem({
    @required this.id,
    @required this.title,
    @required this.quantity,
    @required this.price,
  });
}

class Cart with ChangeNotifier {
  Map<String, CardItem> _items = {};

  Map<String, CardItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void addItem(String productId,
      double price,
      String title,) {
    if (_items.containsKey(productId)) {
      //change the quantity
      _items.update(
          productId,
              (existingCartItem) =>
              CardItem(
                id: existingCartItem.id,
                title: existingCartItem.title,
                quantity: existingCartItem.quantity + 1,
                price: existingCartItem.price,
              ));
    } else {
      _items.putIfAbsent(
        productId,
            () =>
            CardItem(
              id: DateTime.now().toString(),
              title: title,
              price: price,
              quantity: 1,
            ),
      );
    }
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId].quantity > 1) {
      _items.update(productId, (existingCartItem) =>
          CardItem(id: existingCartItem.id,
            title: existingCartItem.title,
            quantity: (existingCartItem.quantity-1),
            price: existingCartItem.price,));
    }else{
      _items.remove(productId);
    }
    notifyListeners();
  }
}
