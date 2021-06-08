import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/foundation.dart';

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavouraite;

  Product({
    @required this.id,
    @required this.title,
    @required this.description,
    @required this.price,
    @required this.imageUrl,
    this.isFavouraite = false,
  });

  Future<void> toggleFavouriteStatus(String token,String userId) async {
    var oldValue = isFavouraite;
    isFavouraite = !isFavouraite;
    notifyListeners();
    final url = "https://my-shop-9ef09.firebaseio.com/userFavourite/$userId/$id.json?auth=$token";
    try {
      var response = await http.put(url,
          body: json.encode(
            isFavouraite,
          ));
      if (response.statusCode >= 400) {
        print(json.decode(response.body));
        isFavouraite = oldValue;
        notifyListeners();
      }
    } catch (err) {
      isFavouraite = oldValue;
      notifyListeners();
    }
  }
}
