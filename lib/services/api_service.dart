

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  Future<Map<String, dynamic>> deleteOrderById(String orderId) async {
    final response = await post('/order/order-delete/$orderId');
    print('Delete order by id response: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete order: ${response.statusCode}');
    }
  }
  Future<Map<String, dynamic>> deleteUserById(String userId) async {
    final response = await get('/user/delete-user/$userId');
    print('Delete user by id response: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete user: ${response.statusCode}');
    }
  }
  Future<Map<String, dynamic>> getOrdersByUserId(String userId) async {
    final response = await get('/order/get-all-orders-by-user/$userId');
    print('Get orders by user id response: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch orders: ${response.statusCode}');
    }
  }
  Future<Map<String, dynamic>> getCartByUserId(String userId) async {
    final response = await get('/card/get-card-by-user-id/$userId');
    print('Get cart by user id response: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch cart: {response.statusCode}');
    }
  }
  Future<Map<String, dynamic>> getAllOrders() async {
    final response = await get('/order/get-all-orders');
    print('Get all orders response: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch orders: ${response.statusCode}');
    }
  }


  Future<Map<String, dynamic>> changeOrderStatus(String orderId, {String? orderStatus, String? paymentStatus}) async {
    final body = <String, dynamic>{};
    if (orderStatus != null) body['orderStatus'] = orderStatus;
    if (paymentStatus != null) body['paymentStatus'] = paymentStatus;
    final url = '$baseUrl/order/order/change-status/$orderId';
    print('Change order status REQUEST URL: ' + url);
    print('Change order status REQUEST BODY: ' + jsonEncode(body));
    final response = await post('/order/change-status/$orderId',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    print('Change order status RESPONSE: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to change order status: ${response.statusCode}');
    }
  }



  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    final response = await get('/order/get-order-by-id/$orderId');
    print('Get order by id response: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch order details: ${response.statusCode}');
    }
  }
  Future<Map<String, dynamic>> sendOtpForUserSignup(String email) async {
    final body = jsonEncode({'email': email});
    print('Send OTP request body: ' + body);
    final response = await post('/user/send-otp-for-user-signup',
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('Send OTP response: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send OTP: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> verifyOtpForUserSignup({
    required String fullName,
    required String mobile,
    required String email,
    required String otp,
    required String password,
  }) async {
    final body = jsonEncode({
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      'otp': otp,
      'password': password,
    });
    print('Verify OTP request body: ' + body);
    final response = await post('/user/verify-otp-for-user-signup',
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('Verify OTP response: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to verify OTP: ${response.statusCode}');
    }
  }

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
    final url = Uri.parse('$baseUrl/user/update-user-with-photo/$userId');
    var request = http.MultipartRequest('POST', url);
    request.fields['name'] = name;
    request.fields['email'] = email;
    request.fields['street'] = street;
    request.fields['city'] = city;
    request.fields['state'] = state;
    request.fields['zipCode'] = zipCode;
    request.fields['country'] = country;
    request.fields['phone'] = phone;
    request.fields['shopname'] = shopname;
    if (photoPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('photo', photoPath));
    }
    print('Update user request fields: ' + request.fields.toString());
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('Update user response: ' + response.body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.statusCode}');
    }
  }
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await get('/user/get-all-user');
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['message'] ?? 'Failed to fetch users');
      }
    } else {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }
  }
  final String baseUrl = "https://api.sddipl.com/api";

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: headers);
  }

  Future<http.Response> post(String endpoint, {Map<String, String>? headers, Object? body}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, headers: headers, body: body);
  }

  Future<http.Response> multipart(String endpoint, Map<String, String> fields, List<http.MultipartFile> files, {Map<String, String>? headers}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var request = http.MultipartRequest('POST', url);
    request.fields.addAll(fields);
    request.files.addAll(files);
    if (headers != null) request.headers.addAll(headers);
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
  final response = await post('/admin-login',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == true && data['data'] != null) {
        return {
          'user': data['data']['user'],
          'token': data['data']['token'],
        };
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  // Example usage for products (can be removed if not needed)
  Future<List<Product>> fetchProducts() async {
    final response = await get('/products');
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Product.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }


  Future<Map<String, dynamic>> getUserDetailsById(String userId) async {
    final response = await get('/user/get-all-user-by-id/$userId');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user details: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> toggleUserStatus(String userId) async {
    final response = await get('/user/toggle-status/$userId');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to toggle user status: ${response.statusCode}');
    }
  }



}
