import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import './../models/http_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Auth with ChangeNotifier {
  String _token;
  DateTime _expiryDate;
  String _userId;
  Timer _authTimer;

  bool get isAuth {
    if(token != null){
      return true;
    }else{
      return false;
    }
  }

  String get token {
    if (_token != null &&
        _expiryDate != null &&
        _expiryDate.isAfter(DateTime.now())) {
      return _token;
    }
    return null;
  }

  String get userId {
    if (_userId != null &&
        _expiryDate != null &&
        _expiryDate.isAfter(DateTime.now())) {
      return _userId;
    }
    return null;
  }

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url =
        "https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=AIzaSyD5IALVvq2gTDashMBr227tEJiQoqiHAOo";
    try {
      final response = await http.post(url,
          body: json.encode(
            {
              'email': email,
              'password': password,
              'returnSecureToken': true,
            },
          ));
      final responseData = json.decode(response.body);
      print(responseData);
      if (responseData['error'] != null) {
        print("http exception caught");
        throw HttpException(responseData["error"]["message"]);
      }
      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(
            responseData['expiresIn'],
          ),
        ),
      );
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode({'token':_token,'userId':_userId,'expireDate':_expiryDate.toIso8601String()});
      prefs.setString('userData', userData);
    } catch (error) {
      throw error;
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs =await SharedPreferences.getInstance();
    if(!prefs.containsKey('userId')){
     return false;
    }
    final extractedUserData = json.decode(prefs.getString('userData')) as Map<String,Object>;
    final expiryDate = DateTime.parse(extractedUserData['expireDate']);
    if(expiryDate.isBefore(DateTime.now())){
      return false;
    }
    _token = extractedUserData['token'];
    _userId = extractedUserData['userId'];
    _expiryDate = extractedUserData['expireDate'];
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> signUp(String email, String password) async {
    return _authenticate(email, password, 'signUp');
//    final url =
//        "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyD5IALVvq2gTDashMBr227tEJiQoqiHAOo";
//    final response = await http.post(url,
//        body: json.encode(
//          {
//            'email': email,
//            'password': password,
//            'returnSecureToken': true,
//          },
//        ));
//    print(json.decode(response.body));
  }

  void logIn(String email, String password) async {
    return _authenticate(email, password, 'signInWithPassword');
//    final url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=AIzaSyD5IALVvq2gTDashMBr227tEJiQoqiHAOo";
//    final response = await http.post(url,body: json.encode({
//      'email': email,
//      'password': password,
//      'returnSecureToken': true,
//    }));
//    print(json.decode(response.body));
  }

  Future<void> logout() async{
    _token = null;
    _userId = null;
    _expiryDate =null;
    if(_authTimer != null){
      _authTimer.cancel();
      _authTimer = null;
    }

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
//    prefs.remove('userId');
    prefs.clear();
  }

  void _autoLogout(){
    if(_authTimer != null){
      _authTimer.cancel();
    }
    final timeToExpiry = _expiryDate.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry),logout);
  }
}
