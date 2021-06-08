import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myshops/models/http_exception.dart';

import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  final String authToken;
  final String authUserId;
  Products(this.authToken, this.authUserId, this._items);
//    Product(
//      id: 'p1',
//      title: 'Red Shirt',
//      description: 'A red shirt - it is pretty red!',
//      price: 29.99,
//      imageUrl:
//      'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
//    ),
//    Product(
//      id: 'p2',
//      title: 'Trousers',
//      description: 'A nice pair of trousers.',
//      price: 59.99,
//      imageUrl:
//      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
//    ),
//    Product(
//      id: 'p3',
//      title: 'Yellow Scarf',
//      description: 'Warm and cozy - exactly what you need for the winter.',
//      price: 19.99,
//      imageUrl:
//      'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
//    ),
//    Product(
//      id: 'p4',
//      title: 'A Pan',
//      description: 'Prepare any meal you want.',
//      price: 49.99,
//      imageUrl:
//      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
//    ),

  //var _showFavouriteOnly = false;

  List<Product> get items {
//    if(_showFavouriteOnly){
//      return _items.where((prodItem)=>prodItem.isFavouraite).toList();
//    }
    //return [..._items];
    return _items;
  }

  List<Product> get favouriteItems {
    return _items.where((item) => item.isFavouraite).toList();
  }

//  void showFavouritesOnly(){
//    _showFavouriteOnly = true;
//    notifyListeners();
//
//  }
//
//  void showAll(){
//    _showFavouriteOnly = false;
//    notifyListeners();
//  }

//  Future<void> getAndSetProduct() async {
//    const url = "https://my-shop-9ef09.firebaseio.com/products.json";
//    try {
//      final response = await http.get(url);
//      //print(json.decode(response.body));
//      final loadedProduct = json.decode(response.body) as Map<String, dynamic>;
//      final List<Product> extractedProduct = [];
//      loadedProduct.forEach((prodId, prodData) {
//        extractedProduct.add(Product(
//          id: prodId,
//          title: prodData['title'],
//          description: prodData['descriptiion'],
//          price: prodData['price'],
//          imageUrl: prodData['imageUrl'],
//          isFavouraite: prodData['isFavourite'],
//        ));
//      });
//      _items = extractedProduct;
//      print(_items);
//      notifyListeners();
//    } catch (error) {
//      print(error);
//      throw error;
//    }
//  }

  Future<void> fetchAndSetProducts([bool filter = false]) async {
    var filterLogic = filter ? 'orderBy="creatorId"&equalTo="$authUserId"' : "";
    var url =
        'https://my-shop-9ef09.firebaseio.com/products.json?auth=$authToken&$filterLogic';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      print(extractedData);
      if (extractedData == null) {
        return;
      }
      url =
          "https://my-shop-9ef09.firebaseio.com/userFavourite/$authUserId.json?auth=$authToken";
      final favouriteResponse = await http.get(url);
      final favouriteData = json.decode(favouriteResponse.body);
      final List<Product> loadedProducts = [];
      extractedData.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['descriptiion'],
          price: prodData['price'],
          isFavouraite:
              favouriteData == null ? false : favouriteData[prodId] ?? false,
          imageUrl: prodData['imageUrl'],
        ));
      });
      _items = List.from(loadedProducts);
      print(_items);
      notifyListeners();
    } catch (error) {
      throw (error);
    }
  }

  Future<void> addProducts(Product product) async {
    final url =
        "https://my-shop-9ef09.firebaseio.com/products.json?auth=$authToken";
    try {
      var response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'descriptiion': product.description,
          'imageUrl': product.imageUrl,
          'price': product.price,
          'creatorId': authUserId,
//          'isFavourite': product.isFavouraite,
        }),
      );
      final newProduct = Product(
        id: json.decode(response.body)["name"],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
      );
      _items.add(newProduct);
      //_items.insert(0, newProduct);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);

    if (prodIndex >= 0) {
      final url =
          "https://my-shop-9ef09.firebaseio.com/products/$id.json?auth=$authToken";
      http.patch(
        url,
        body: json.encode({
          'title': newProduct.title,
          'price': newProduct.price,
          'descriptiion': newProduct.description,
          'imageUrl': newProduct.imageUrl,
          'isFavourite': newProduct.isFavouraite,
        }),
      );
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print("...");
    }
  }

  void deleteProduct(String id) async {
    final url =
        "https://my-shop-9ef09.firebaseio.com/products/$id.json?auth=$authToken";
    var existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeWhere((prod) => prod.id == id);
    notifyListeners();
    var response = await http.delete(url);
    print(response.statusCode);
    if (response.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException("Could not delete product");
    }

    existingProduct = null;
  }
}
