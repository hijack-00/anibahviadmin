import 'dart:convert';
import 'dart:io';
import 'package:anibhaviadmin/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppDataRepo {
  Future<Map<String, dynamic>> fetchChallansWithPagination({
    int page = 1,
    int limit = 10,
  }) async {
    return await _api.fetchChallansWithPagination(page: page, limit: limit);
  }

  Future<Map<String, dynamic>> fetchReturnsWithPagination({
    int page = 1,
    int limit = 10,
  }) async {
    return await _api.fetchReturnsWithPagination(page: page, limit: limit);
  }

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

  Future<Map<String, dynamic>> fetchAllOrdersByAdminWithPagination() async {
    return await _api.fetchAllOrdersByAdminWithPagination();
  }

  Future<Map<String, dynamic>> updateOrderNoteByAdmin(
    String orderId,
    String orderNote,
  ) async {
    return await _api.updateOrderNoteByAdmin(orderId, orderNote);
  }

  Future<Map<String, dynamic>> changeOrderStatusByAdmin({
    required String orderId,
    required String newStatus,
    String trackingId = '',
    String deliveryVendor = '',
  }) async {
    return await _api.changeOrderStatusByAdmin(
      orderId: orderId,
      newStatus: newStatus,
      trackingId: trackingId,
      deliveryVendor: deliveryVendor,
    );
  }

  Future<Map<String, dynamic>> updateOrderPaymentByAdmin({
    required String orderId,
    required double additionalPayment,
    required String paymentMethod,
    String notes = '',
  }) async {
    return await _api.updateOrderPaymentByAdmin(
      orderId: orderId,
      additionalPayment: additionalPayment,
      paymentMethod: paymentMethod,
      notes: notes,
    );
  }

  Future<Map<String, dynamic>> createOrderByAdmin(
    Map<String, dynamic> orderData,
  ) async {
    final response = await _api.createOrderByAdmin(orderData);
    return {
      "success":
          response['success'] == true ||
          response['status'] == 201 ||
          response['status'] == 200,
      "data": response,
      "status": response['status'] ?? 200,
      "message": response['message'] ?? '',
    };
  }

  Future<List<Map<String, dynamic>>> fetchAllOrders() async {
    // Fetch all orders using the new endpoint, but ignore pagination for now
    final response = await fetchAllOrdersByAdminWithPagination();
    if (response['success'] == true && response['orders'] is List) {
      return List<Map<String, dynamic>>.from(response['orders']);
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

  Future<Map<String, dynamic>> getReturnsByCustomerAndOrder({
    required String customerId,
    required String orderId,
  }) => _api.getReturnsByCustomerAndOrder(
    customerId: customerId,
    orderId: orderId,
  );

  Future<Map<String, dynamic>> createReturn({
    required Map<String, dynamic> data,
  }) => _api.createReturn(data: data);

  Future<Map<String, dynamic>> fetchOrdersByUser(String userId) async {
    return await _api.getOrdersByUserId(userId);
  }

  Future<Map<String, dynamic>> getChallansByCustomerAndOrder({
    required String customerId,
    required String orderId,
  }) async {
    return await _api.getChallansByCustomerAndOrder(
      customerId: customerId,
      orderId: orderId,
    );
  }

  Future<Map<String, dynamic>> createChallan(
    Map<String, dynamic> challanBody,
  ) async {
    return await _api.createChallan(challanBody);
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

  Future<Map<String, dynamic>> getJeansShirtRevenueAndOrder() async {
    return await _api.fetchJeansShirtRevenueAndOrder();
  }

  Future<Map<String, dynamic>> getSalesData() async {
    return await _api.fetchSalesData();
  }

  Future<int> fetchUserRewardPoints(String userId) async {
    final data = await ApiService.getUserRewardPoints(userId);
    if (data != null &&
        data['data'] != null &&
        data['data']['points'] != null) {
      return data['data']['points'] is int
          ? data['data']['points']
          : int.tryParse(data['data']['points'].toString()) ?? 0;
    }
    return 0;
  }

  Future<Map<String, dynamic>> getTopProducts() async {
    return await _api.fetchTopProducts();
  }

  // Future<Map<String, dynamic>> fetchAllOrders() async {
  //   return await _api.getAllOrders();
  // }

  Future<Map<String, dynamic>> changeOrderStatus(
    String orderId, {
    String? orderStatus,
    String? paymentStatus,
  }) async {
    return await _api.changeOrderStatus(
      orderId,
      orderStatus: orderStatus,
      paymentStatus: paymentStatus,
    );
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

  Future<Map<String, dynamic>> updateSubProduct(
    String id,
    Map<String, dynamic> updatedFields,
  ) async {
    return await _api.updateSubProduct(id, updatedFields);
  }

  static const String _userKey = 'user_data';
  static const String _tokenKey = 'user_token';

  Future<void> saveUserData(Map<String, dynamic> user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
    await prefs.setString(_tokenKey, token);
  }

  Future<List<Map<String, dynamic>>> fetchAllSizes() async {
    return await _api.fetchAllSizes();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    final token = prefs.getString(_tokenKey);
    if (userStr != null && token != null) {
      return {'user': jsonDecode(userStr), 'token': token};
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
