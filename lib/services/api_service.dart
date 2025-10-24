import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ApiService {
  Future<Map<String, dynamic>> fetchChallansWithPagination({
    int page = 1,
    int limit = 10,
  }) async {
    final url =
        "$baseUrl/challan/get-all-challans-with-pagination?page=$page&limit=$limit";
    final response = await http.get(Uri.parse(url), headers: defaultHeaders);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> fetchReturnsWithPagination({
    int page = 1,
    int limit = 10,
  }) async {
    final url =
        "$baseUrl/return/get-all-return-with-pagination?page=$page&limit=$limit";
    final response = await http.get(Uri.parse(url), headers: defaultHeaders);
    return jsonDecode(response.body);
  }

  static const String baseUrl = "https://api.sddipl.com/api";
  static Map<String, String> defaultHeaders = {
    "Content-Type": "application/json",
  };

  Future<Map<String, dynamic>> adminLogin({
    required String email,
    required String password,
  }) async {
    final url = "$baseUrl/admin/admin-login";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getAllProducts() async {
    final url = "$baseUrl/product/get-all-products";
    final response = await http.get(Uri.parse(url), headers: defaultHeaders);
    return jsonDecode(response.body);
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
    required String filnalLotPrice, // <-- changed here
  }) async {
    final url = "$baseUrl/subProduct/create-sub-product";
    final fields = <String, String>{
      "productId": productId,
      "name": name,
      "description": description,
      "color": color,
      "selectedSizes": jsonEncode(selectedSizes),
      "lotNumber": lotNumber,
      "singlePicPrice": singlePicPrice.toString(),
      "barcode": barcode,
      "pcsInSet": pcsInSet.toString(),
      "dateOfOpening": dateOfOpening.toIso8601String(),
      "status": status.toString(),
      "stock": stock,
      "lotStock": lotStock.toString(),
      "isActive": isActive.toString(),
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
      "filnalLotPrice": filnalLotPrice, // <-- changed here
    };
    final files = <String, File>{};
    List<File> imageList = images; // or whatever your images list is called
    final multipleFiles = <String, List<File>>{'subProductImages': imageList};
    return await postMultipart(url, fields, {}, multipleFiles);
    // You must have a postMultipart helper defined in this file:
    return await postMultipart(url, fields, files, {});
  }

  // Add your postMultipart helper here if not present
  Future<Map<String, dynamic>> postMultipart(
    String url,
    Map<String, String> fields,
    Map<String, File> singleFiles,
    Map<String, List<File>> multipleFiles,
  ) async {
    print('--- Multipart Request ---');
    print('URL: $url');
    print('Fields: $fields');
    print(
      'Single Files: ${singleFiles.keys.map((k) => '$k: ${singleFiles[k]?.path}').toList()}',
    );
    print(
      'Multiple Files: ${multipleFiles.keys.map((k) => '$k: ${multipleFiles[k]?.map((f) => f.path).toList()}').toList()}',
    );

    var request = http.MultipartRequest("POST", Uri.parse(url));
    request.fields.addAll(fields);

    for (var entry in singleFiles.entries) {
      if (await entry.value.exists()) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }
    }

    for (var entry in multipleFiles.entries) {
      for (var file in entry.value) {
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, file.path),
          );
        }
      }
    }
    print('Sending multipart request...');

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    print('--- End Multipart Request ---');

    if (!response.headers['content-type']!.contains('application/json')) {
      throw Exception('Server did not return JSON. Response: ${response.body}');
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateSubProduct(
    String id,
    Map<String, dynamic> updatedFields,
  ) async {
    final url = "$baseUrl/subProduct/update-sub-product/$id";
    print('Update Product API URL: $url');
    print('Update Product Request Body: $updatedFields');

    final request = http.MultipartRequest("POST", Uri.parse(url));
    updatedFields.forEach((key, value) async {
      if (key == 'subProductImages' && value is List<File>) {
        for (var file in value) {
          if (await file.exists()) {
            request.files.add(
              await http.MultipartFile.fromPath('subProductImages', file.path),
            );
          }
        }
      } else {
        request.fields[key] = value.toString();
      }
    });
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    print('Update Product Response Body: ${response.body}');

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>?> getUserRewardPoints(
    String userId,
  ) async {
    final url = Uri.parse('$baseUrl/reward/get-all-rewards-by-id/$userId');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchAllSizes() async {
    final url = "$baseUrl/size/get-all-size-with-pagination";
    final response = await http.get(Uri.parse(url), headers: defaultHeaders);
    final decoded = jsonDecode(response.body);
    if (decoded['success'] == true && decoded['data'] is List) {
      return List<Map<String, dynamic>>.from(decoded['data']);
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchProductDetailById(String productId) async {
    final url = '$baseUrl/subProduct/get_product_by_id/$productId';
    print('Product Details API URL: $url');

    final response = await get('/subProduct/get_product_by_id/$productId');

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to fetch product details: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> fetchCatalogueProducts() async {
    final response = await get('/subProduct/get-all-sub-products');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Failed to fetch catalogue products: {response.statusCode}',
      );
    }
  }

  // Add: fetch challans by customer+order, create challan
  Future<Map<String, dynamic>> getChallansByCustomerAndOrder({
    required String customerId,
    required String orderId,
  }) async {
    final endpoint = '/challan/get-all-challans-by-customer-and-order';
    final url = '$baseUrl$endpoint';
    final body = jsonEncode({'customerId': customerId, 'orderId': orderId});
    print('API: POST $url');
    print('Request body: $body');
    final response = await post(
      endpoint,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> createChallan(
    Map<String, dynamic> challanBody,
  ) async {
    final endpoint = '/challan/create-challan';
    final url = '$baseUrl$endpoint';
    final body = jsonEncode(challanBody);
    print('API: POST $url');
    print('Request body: $body');
    final response = await post(
      endpoint,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> fetchJeansShirtRevenueAndOrder() async {
    final url = "$baseUrl/salesAndReports/get-jeans-shirt-revenue-and-order";
    final response = await get(
      '/salesAndReports/get-jeans-shirt-revenue-and-order',
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch jeans/shirt revenue and order');
    }
  }

  // Add: fetch returns by customer + order, create return

  Future<Map<String, dynamic>> getReturnsByCustomerAndOrder({
    required String customerId,
    required String orderId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/return/get-all-returns-by-customer-and-order',
    );
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId, 'orderId': orderId}),
    );
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createReturn({
    required Map<String, dynamic> data,
  }) async {
    // final url = Uri.parse('$baseUrl/return/create-return');
    // final resp = await http.post(
    //   url,
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode({'data': data}),
    // );
    // return jsonDecode(resp.body) as Map<String, dynamic>;
    final endpoint = '/return/create-return';
    final url = Uri.parse('$baseUrl$endpoint');
    // Wrap payload under "data" because API expects {"data": {...}}
    final wrapped = {'data': data};
    final body = jsonEncode(wrapped);
    print('API: POST $url');
    print('API: Request body: $body');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('API: Response status: ${resp.statusCode}');
    print('API: Response body: ${resp.body}');
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      print('API: Failed to decode createReturn response JSON: $e');
      return {
        'success': false,
        'status': resp.statusCode,
        'rawBody': resp.body,
      };
    }
  }

  Future<Map<String, dynamic>> createOrderByAdmin(
    Map<String, dynamic> orderData,
  ) async {
    final endpoint = '/order/create-order-by-admin';
    final url = "$baseUrl$endpoint";
    final body = jsonEncode(orderData);

    // Request logging
    print('--- CREATE ORDER REQUEST ---');
    print('URL: $url');
    print('Endpoint: $endpoint');
    print('Headers: {"Content-Type": "application/json"}');
    print('Request body: $body');

    final response = await post(
      endpoint,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    // Response logging
    print('--- CREATE ORDER RESPONSE ---');
    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    // Try to decode JSON, return a safe map on failure
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': true, 'data': decoded, 'status': response.statusCode};
    } catch (e) {
      print('Failed to decode response JSON: $e');
      return {
        'success': false,
        'status': response.statusCode,
        'rawBody': response.body,
      };
    }
  }

  // Future<Map<String, dynamic>> createOrderByAdmin(
  //   Map<String, dynamic> orderData,
  // ) async {
  //   final url = "$baseUrl/order/create-order-by-admin";
  //   final response = await post(
  //     '/order/create-order-by-admin',
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(orderData),
  //   );

  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception('Failed to create order: ${response.statusCode}');
  //   }
  // }

  Future<Map<String, dynamic>> fetchSalesData() async {
    final url = "$baseUrl/salesAndReports/get-SalesData";
    final response = await get('/salesAndReports/get-SalesData');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch sales data');
    }
  }

  Future<Map<String, dynamic>> fetchTopProducts() async {
    final url = "$baseUrl/salesAndReports/get-top-products";
    final response = await get('/salesAndReports/get-top-products');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch top products');
    }
  }

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

  Future<Map<String, dynamic>> fetchAllOrdersByAdminWithPagination({
    int page = 1,
    int limit = 10,
  }) async {
    final url = "$baseUrl/order/get-all-Admin-orders";
    final response = await http.get(Uri.parse(url), headers: defaultHeaders);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> changeOrderStatus(
    String orderId, {
    String? orderStatus,
    String? paymentStatus,
  }) async {
    final body = <String, dynamic>{};
    if (orderStatus != null) body['orderStatus'] = orderStatus;
    if (paymentStatus != null) body['paymentStatus'] = paymentStatus;
    final url = '$baseUrl/order/order/change-status/$orderId';
    print('Change order status REQUEST URL: ' + url);
    print('Change order status REQUEST BODY: ' + jsonEncode(body));
    final response = await post(
      '/order/change-status/$orderId',
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

  Future<Map<String, dynamic>> updateOrderNoteByAdmin(
    String orderId,
    String orderNote,
  ) async {
    final url = "$baseUrl/order/update-order-notes-by-admin/$orderId";
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"orderNote": orderNote}),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> changeOrderStatusByAdmin({
    required String orderId,
    required String newStatus,
    String trackingId = '',
    String deliveryVendor = '',
  }) async {
    final url = "$baseUrl/order/change-status-by-admin/$orderId";
    final body = {
      "orderId": orderId,
      "newStatus": newStatus,
      "trackingId": trackingId,
      "deliveryVendor": deliveryVendor,
    };
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateOrderPaymentByAdmin({
    required String orderId,
    required double additionalPayment,
    required String paymentMethod,
    String notes = '',
  }) async {
    final url = "$baseUrl/order/update-order-payment-by-admin/$orderId";
    final body = {
      "orderId": orderId,
      "additionalPayment": additionalPayment,
      "paymentMethod": paymentMethod,
      "notes": notes,
    };
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    return jsonDecode(response.body);
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
    final response = await post(
      '/user/send-otp-for-user-signup',
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
    final response = await post(
      '/user/verify-otp-for-user-signup',
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

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.get(url, headers: headers);
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    return await http.post(url, headers: headers, body: body);
  }

  Future<http.Response> multipart(
    String endpoint,
    Map<String, String> fields,
    List<http.MultipartFile> files, {
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    var request = http.MultipartRequest('POST', url);
    request.fields.addAll(fields);
    request.files.addAll(files);
    if (headers != null) request.headers.addAll(headers);
    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await post(
      '/admin-login',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == true && data['data'] != null) {
        return {'user': data['data']['user'], 'token': data['data']['token']};
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
