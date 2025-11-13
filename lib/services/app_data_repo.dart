import 'dart:convert';
import 'dart:io';
import 'package:anibhaviadmin/services/api_service.dart';
import 'package:flutter/material.dart';
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

  // roles cache + mapping
  static List<Map<String, dynamic>> roles = [];
  static const String _currentRoleKey = 'current_role_id';

  static const Map<String, String> routeToPermissionKey = {
    '/dashboard': 'dashboard',
    '/catalogue': 'catalogueUpload',
    '/products': 'products',
    '/product-detail': 'products',
    '/orders': 'orders',
    '/order_detail': 'orders',
    '/sales': 'sales',
    '/returns': 'returns',
    '/catalogue-upload': 'catalogueUpload',
    '/users': 'userManagement',
    '/admin-users': 'admins',
    '/notifications': 'notifications',
    '/challan': 'returns', // adjust if your API uses a different key
  };

  Future<void> loadRolesFromApi() async {
    try {
      final resp = await _api.fetchAllRoles();
      final d = resp['data'];
      if (d is List)
        roles = List<Map<String, dynamic>>.from(d);
      else
        roles = [];
      debugPrint('Roles loaded: ${roles.length}');
    } catch (e) {
      roles = [];
      debugPrint('loadRolesFromApi error: $e');
    }
  }

  Future<void> saveCurrentRoleId(String roleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentRoleKey, roleId);
    debugPrint('Saved current role id: $roleId');
  }

  Future<String?> getCurrentRoleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentRoleKey);
  }

  Map<String, dynamic>? getRoleByIdCached(String id) {
    final sid = id?.toString() ?? '';
    for (final r in roles) {
      // match by common id fields and name fields (case-insensitive)
      final rid = r['_id']?.toString() ?? r['id']?.toString() ?? '';
      final rname = (r['name'] ?? r['role'] ?? r['roleName'])?.toString() ?? '';
      if (rid == sid) return r;
      if (rname.toLowerCase() == sid.toLowerCase()) return r;
    }
    return null;
  }

  bool _hasPermissionInRoleMap(
    Map<String, dynamic> role,
    String permissionKey,
    String action,
  ) {
    if (role == null) return false;
    final perms = role['permissions'];
    if (perms is Map && perms[permissionKey] is Map) {
      final p = perms[permissionKey];
      return p[action] == true;
    }
    return false;
  }

  Future<bool> currentUserHasPermission(
    String permissionOrRoute,
    String action, {
    bool forceReload = false,
  }) async {
    final permissionKey =
        routeToPermissionKey[permissionOrRoute] ?? permissionOrRoute;
    debugPrint(
      'Checking permission for key="$permissionKey" action="$action" forceReload=$forceReload',
    );

    // Always reload roles when forceReload requested
    if (forceReload || roles.isEmpty) {
      await loadRolesFromApi();
    }

    final roleId = await getCurrentRoleId();
    debugPrint(
      'currentUserHasPermission: roleId="$roleId" roles=${roles.length}',
    );

    if (roleId == null || roleId.isEmpty) {
      debugPrint('No saved role id -> deny');
      return false;
    }

    final role = getRoleByIdCached(roleId);
    if (role != null) {
      final ok = _hasPermissionInRoleMap(role, permissionKey, action);
      debugPrint('perm result (cached) for $permissionKey/$action -> $ok');
      return ok;
    }

    // fallback: try to find role in freshly loaded list (already tried), or query API for single role
    try {
      final remote = await _api.getRoleById(roleId);
      if (remote != null) {
        final ok = _hasPermissionInRoleMap(remote, permissionKey, action);
        debugPrint('perm result (remote) for $permissionKey/$action -> $ok');
        return ok;
      }
    } catch (e) {
      debugPrint('perm check error: $e');
    }

    return false;
  }
  // ----------------- end helpers -----------------

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

  Future<List<Map<String, dynamic>>> fetchAllMainCategories() async {
    final response = await _api.getAllMainCategories();
    if (response['success'] == true && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> deleteChallan({required String id}) async {
    return await _api.deleteChallan(id: id);
  }

  Future<Map<String, dynamic>> updateReturn({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    return await _api.updateReturn(id: id, data: data);
  }

  Future<List<Map<String, dynamic>>> fetchAllProductsCatalog() async {
    try {
      final resp = await _api.fetchAllProductsEndpoint();
      if (resp['success'] == true && resp['data'] is List) {
        return List<Map<String, dynamic>>.from(resp['data']);
      }
      return [];
    } catch (e) {
      debugPrint('fetchAllProductsCatalog error: $e');
      print('fetchAllProductsCatalog error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> deleteReturn({required String id}) async {
    return await _api.deleteReturn(id: id);
  }

  /// Update challan by id. Pass the full challan object under `data`.
  Future<Map<String, dynamic>> updateChallan({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    return await _api.updateChallan(id: id, data: data);
  }

  /// Wrapper: remove challan bilti slip
  Future<Map<String, dynamic>> removeChallanSlip({
    required String challanId,
  }) async {
    return await _api.removeChallanSlip(challanId: challanId);
  }

  Future<Map<String, dynamic>> uploadChallanSlip({
    required File file,
    required String challanId,
  }) async {
    return await _api.uploadChallanSlip(file: file, challanId: challanId);
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

  Future<Map<String, dynamic>> fetchAnyProductById(String id) async {
    try {
      final subResp = await _api.fetchProductDetailById(id);
      // If subResp.data is list and empty -> try product endpoint
      final subData = subResp['data'];
      if (subData is List) {
        if (subData.isNotEmpty) return subResp;
        // fallback to product endpoint
        final prodResp = await _api.fetchProductByProductId(id);
        return prodResp;
      } else if (subData is Map<String, dynamic>) {
        return subResp;
      } else {
        // fallback
        final prodResp = await _api.fetchProductByProductId(id);
        return prodResp;
      }
    } catch (e) {
      debugPrint('fetchAnyProductById error: $e');
      // try product endpoint as last effort
      try {
        return await _api.fetchProductByProductId(id);
      } catch (e2) {
        return {'status': false, 'message': e.toString(), 'data': null};
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllCategories({
    int page = 1,
    int limit = 1000,
  }) async {
    try {
      final resp = await _api.fetchAllCategoriesEndpoint(
        page: page,
        limit: limit,
      );
      if (resp['success'] == true && resp['data'] is List) {
        return List<Map<String, dynamic>>.from(resp['data']);
      }
      return [];
    } catch (e) {
      debugPrint('fetchAllCategories error: $e');
      return [];
    }
  }

  /// Create product wrapper
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String type,
    required String categoryId,
    required String subcategoryId,
    required String price,
    required String sku,
    required List<File> images,
  }) async {
    try {
      final resp = await _api.createProductMultipart(
        name: name,
        type: type,
        categoryId: categoryId,
        subcategoryId: subcategoryId,
        price: price,
        sku: sku,
        files: images,
      );
      return resp;
    } catch (e) {
      debugPrint('createProduct error: $e');
      return {'success': false, 'message': e.toString()};
    }
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

  Future<Map<String, dynamic>> updateAdminUserByAdmin({
    required String userId,
    required Map<String, dynamic> userForm,
  }) async {
    final response = await _api.updateAdminUserByAdmin(
      userId: userId,
      userForm: userForm,
    );

    print('Update Admin User Response: $response'); // Log the response

    return response;
  }

  /// Create admin/staff user (wrapper)
  Future<Map<String, dynamic>> createAdminUser({
    required Map<String, dynamic> userForm,
  }) async {
    try {
      final resp = await _api.createAdminByAdmin(userForm: userForm);
      debugPrint('createAdminUser response: $resp');
      return resp;
    } catch (e) {
      debugPrint('createAdminUser error: $e');
      return {'status': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAdminUserByAdmin(String userId) async {
    try {
      final resp = await _api.deleteAdminUserByAdmin(userId: userId);
      return resp;
    } catch (e) {
      debugPrint('deleteAdminUserByAdmin error: $e');
      return {'status': false, 'message': e.toString()};
    }
  }

  /// Fetch admin/staff users (wrapper for admin/getAdminUsersByAdminwithPagination)
  Future<List<Map<String, dynamic>>> fetchAdminUsers({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final resp = await _api.getAdminUsersByAdminWithPagination(
        page: page,
        limit: limit,
      );
      // API returns { status: true, message: ..., data: [ ... ], pagination: {...} }
      if ((resp['status'] == true || resp['success'] == true) &&
          resp['data'] is List) {
        return List<Map<String, dynamic>>.from(resp['data']);
      }
      return [];
    } catch (e) {
      debugPrint('fetchAdminUsers error: $e');
      return [];
    }
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
    // return await _api.fetchJeansShirtRevenueAndOrder();
    try {
      return await _api.fetchJeansShirtRevenueAndOrder();
    } catch (e) {
      print('AppDataRepo.getJeansShirtRevenueAndOrder ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSalesData() async {
    // return await _api.fetchSalesData();
    try {
      return await _api.fetchSalesData();
    } catch (e) {
      print('AppDataRepo.getSalesData ERROR: $e');
      rethrow;
    }
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

    // if user object contains role id (field names may vary), persist it
    try {
      String? roleId;
      if (user.containsKey('role') && user['role'] is String) {
        roleId = user['role'] as String;
      } else if (user.containsKey('roleId') && user['roleId'] is String) {
        roleId = user['roleId'] as String;
      } else if (user['role'] is Map && user['role']['_id'] != null) {
        roleId = user['role']['_id'] as String?;
      }
      if (roleId != null && roleId.isNotEmpty) {
        await prefs.setString(_currentRoleKey, roleId);
      }
    } catch (_) {}
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

  // Cached roles fetched from API
  // static List<Map<String, dynamic>> roles = [];
  // static const String _currentRoleKey = 'current_role_id';

  // /// Map routes or logical page keys to permission keys used by the API.
  // /// Extend as needed.
  // static const Map<String, String> routeToPermissionKey = {
  //   '/dashboard': 'dashboard',
  //   '/catalogue': 'catalogueUpload',
  //   '/catalogue-upload': 'catalogueUpload',
  //   '/products': 'products',
  //   '/product-detail': 'products',
  //   '/orders': 'orders',
  //   '/order_detail': 'orders',
  //   '/sales': 'sales',
  //   '/sales-return': 'returns',
  //   '/returns': 'returns',
  //   '/users': 'userManagement',
  //   '/admin-users': 'admins',
  //   '/notifications': 'notifications',
  //   '/stock-management': 'stock', // example - adjust if API uses different key
  //   '/customer-ledger': 'sales',
  // };

  /// Fetch roles from API and cache locally
  // Future<void> loadRolesFromApi() async {
  //   try {
  //     final resp = await _api.fetchAllRoles();
  //     if ((resp['status'] == true || resp['success'] == true) &&
  //         resp['data'] is List) {
  //       roles = List<Map<String, dynamic>>.from(resp['data']);
  //     } else {
  //       roles = [];
  //     }
  //   } catch (e) {
  //     debugPrint('loadRolesFromApi error: $e');
  //     roles = [];
  //   }
  // }

  List<Map<String, dynamic>> getRoles() => roles;

  Map<String, dynamic>? getRoleById(String id) {
    try {
      final sid = id?.toString() ?? '';
      for (var r in roles) {
        final rid = r['_id']?.toString() ?? r['id']?.toString() ?? '';
        final rname =
            (r['name'] ?? r['role'] ?? r['roleName'])?.toString() ?? '';
        if (rid == sid) return r;
        if (rname.toLowerCase() == sid.toLowerCase()) return r;
      }
    } catch (_) {}
    return null;
  }

  // Future<void> saveCurrentRoleId(String roleId) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(_currentRoleKey, roleId);
  // }

  // Future<String?> getCurrentRoleId() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getString(_currentRoleKey);
  // }

  /// Check permission by role id (action: 'read' | 'write' | 'update' | 'delete')
  bool hasPermissionForRole(
    Map<String, dynamic> role,
    String permissionKey,
    String action,
  ) {
    if (role == null) return false;
    final perms = role['permissions'];
    if (perms is Map && perms[permissionKey] is Map) {
      final p = perms[permissionKey];
      final v = p[action];
      return v == true;
    }
    return false;
  }

  /// Checks current user's saved role for permission. If permissionKey is a route,
  /// it will map it to the API permission key via routeToPermissionKey.
  // Future<bool> currentUserHasPermission(
  //   String permissionOrRoute,
  //   String action,
  // ) async {
  //   final roleId = await getCurrentRoleId();
  //   if (roleId == null) return false;
  //   final role = getRoleById(roleId);
  //   final permissionKey =
  //       routeToPermissionKey[permissionOrRoute] ?? permissionOrRoute;
  //   if (role != null) {
  //     return hasPermissionForRole(role, permissionKey, action);
  //   }
  //   // As fallback attempt to fetch role from API
  //   try {
  //     final remote = await _api.getRoleById(roleId);
  //     if (remote != null) {
  //       return hasPermissionForRole(remote, permissionKey, action);
  //     }
  //   } catch (_) {}
  //   return false;
  // }
}
