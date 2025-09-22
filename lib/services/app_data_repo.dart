import 'dart:convert';
import 'dart:io';
import 'package:anibhaviadmin/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDataRepo {
  static final AppDataRepo _instance = AppDataRepo._internal();
  factory AppDataRepo() => _instance;
  AppDataRepo._internal();

  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> fetchProductDetailById(String productId) async {
    return await _api.fetchProductDetailById(productId);
  }

  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    final response = await _api.getAllProducts();
    if (response['success'] == true && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      return [];
    }
  }


  Future<Map<String, dynamic>> adminLogin(String email, String password) async {
  return await _api.adminLogin(email: email, password: password);
}


  Future<Map<String, dynamic>> createSubProduct({
    required List<File> images,
    required String productId,
    required String name,
    required String description,
    required String color,
    required List<String> selectedSizes,
    required String lotNumber,
    required int singlePicPrice,
    required String barcode,
    required int pcsInSet,
    required DateTime dateOfOpening,
    required bool status,
    required String stock,
    required int lotStock,
    required bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String filnalLotPrice,
  }) async {
    return await _api.createSubProduct(
      images: images,
      productId: productId,
      name: name,
      description: description,
      color: color,
      selectedSizes: selectedSizes,
      lotNumber: lotNumber,
      singlePicPrice: singlePicPrice,
      barcode: barcode,
      pcsInSet: pcsInSet,
      dateOfOpening: dateOfOpening,
      status: status,
      stock: stock,
      lotStock: lotStock,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      filnalLotPrice: filnalLotPrice,
    );
  }

  Future<List<Map<String, dynamic>>> fetchCatalogueProducts() async {
    final response = await _api.fetchCatalogueProducts();
    if (response['success'] == true && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> deleteOrderById(String orderId) async {
    return await _api.deleteOrderById(orderId);
  }

  Future<Map<String, dynamic>> deleteUserById(String userId) async {
    return await _api.deleteUserById(userId);
  }

  Future<Map<String, dynamic>> fetchOrdersByUserId(String userId) async {
    return await _api.getOrdersByUserId(userId);
  }

  Future<Map<String, dynamic>> fetchCartByUserId(String userId) async {
    return await _api.getCartByUserId(userId);
  }

  Future<Map<String, dynamic>> fetchAllOrders() async {
    return await _api.getAllOrders();
  }

  Future<Map<String, dynamic>> changeOrderStatus(String orderId, {String? orderStatus, String? paymentStatus}) async {
    return await _api.changeOrderStatus(orderId, orderStatus: orderStatus, paymentStatus: paymentStatus);
  }

  Future<Map<String, dynamic>> fetchOrderById(String orderId) async {
    return await _api.getOrderById(orderId);
  }

  Future<Map<String, dynamic>> fetchUserDetailsById(String userId) async {
    return await _api.getUserDetailsById(userId);
  }

  Future<Map<String, dynamic>> toggleUserStatus(String userId) async {
    return await _api.toggleUserStatus(userId);
  }

  // Store responses for UI access
  static List<Map<String, dynamic>> users = [];
  static Map<String, dynamic>? lastOtpResponse;
  static Map<String, dynamic>? lastVerifyOtpResponse;
  static Map<String, dynamic>? lastUpdateUserResponse;

  // Load all users and update static list
  Future<void> loadAllUsers() async {
    try {
      users = await _api.getAllUsers();
      print('Loaded users: ' + users.toString());
    } catch (e) {
      print('Error loading users: $e');
      users = [];
    }
  }

  // Send OTP for user signup and store response
  Future<Map<String, dynamic>> sendOtpForUserSignup(String email) async {
    final response = await _api.sendOtpForUserSignup(email);
    lastOtpResponse = response;
    return response;
  }

  // Verify OTP for user signup and store response
  Future<Map<String, dynamic>> verifyOtpForUserSignup({
    required String fullName,
    required String mobile,
    required String email,
    required String otp,
    required String password,
  }) async {
    final response = await _api.verifyOtpForUserSignup(
      fullName: fullName,
      mobile: mobile,
      email: email,
      otp: otp,
      password: password,
    );
    lastVerifyOtpResponse = response;
    return response;
  }

  // Update user with photo and store response
  Future<Map<String, dynamic>> updateUserWithPhoto({
    required String userId,
    required String name,
    required String email,
    required String street,
    required String city,
    required String state,
    required String zipCode,
    required String country,
    required String phone,
    required String shopname,
    required String photoPath,
  }) async {
    final response = await _api.updateUserWithPhoto(
      userId: userId,
      name: name,
      email: email,
      street: street,
      city: city,
      state: state,
      zipCode: zipCode,
      country: country,
      phone: phone,
      shopname: shopname,
      photoPath: photoPath,
    );
    lastUpdateUserResponse = response;
    return response;
  }

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'user_token';

  Future<void> saveUserData(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
    await prefs.setString(_tokenKey, token);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    final token = prefs.getString(_tokenKey);
    if (userStr != null && token != null) {
      return {
        'user': jsonDecode(userStr),
        'token': token,
      };
    }
    return null;
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }
}
