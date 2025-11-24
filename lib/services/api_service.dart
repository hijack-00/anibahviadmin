import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import 'package:path/path.dart' as p;

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

  Future<Map<String, dynamic>> updateChallan({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final url = '$baseUrl/challan/update-challan/$id';
    final body = jsonEncode({'data': data});
    final resp = await http.post(
      Uri.parse(url),
      headers: {...defaultHeaders, 'Content-Type': 'application/json'},
      body: body,
    );
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': resp.statusCode >= 200 && resp.statusCode < 300,
        'message': resp.body,
        'statusCode': resp.statusCode,
      };
    }
  }

  Future<Map<String, dynamic>> fetchAllProductsEndpoint() async {
    final url = "$baseUrl/product/get-all-products";
    try {
      final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteReturn({required String id}) async {
    final url = '$baseUrl/return/delete-return/$id';
    try {
      final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateReturn({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final url = '$baseUrl/return/update-return/$id';
    final body = jsonEncode({'data': data});
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {...defaultHeaders, 'Content-Type': 'application/json'},
        body: body,
      );
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteChallan({required String id}) async {
    final url = '$baseUrl/challan/delete-challan/$id';
    try {
      final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Remove bilti slip for a challan (POST JSON body { "challanId": "<id>" })
  Future<Map<String, dynamic>> removeChallanSlip({
    required String challanId,
  }) async {
    final url = '$baseUrl/challan/remove-slip';
    final resp = await http.post(
      Uri.parse(url),
      headers: {...defaultHeaders, 'Content-Type': 'application/json'},
      body: jsonEncode({'challanId': challanId}),
    );
    try {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return {
        'success': resp.statusCode >= 200 && resp.statusCode < 300,
        'message': resp.body,
        'statusCode': resp.statusCode,
      };
    }
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

  Future<Map<String, dynamic>> fetchProductByProductId(String productId) async {
    final url = '$baseUrl/product/get_product_by_id/$productId';
    print('Product (parent) Details API URL: $url');
    try {
      final resp = await get('/product/get_product_by_id/$productId');
      if (resp.statusCode == 200) {
        return json.decode(resp.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to fetch product by id: ${resp.statusCode}');
      }
    } catch (e) {
      print('fetchProductByProductId ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdminUsersByAdminWithPagination({
    int page = 1,
    int limit = 100,
  }) async {
    final url =
        "$baseUrl/admin/getAdminUsersByAdminwithPagination?page=$page&limit=$limit";
    try {
      final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateAdminUserByAdmin({
    required String userId,
    required Map<String, dynamic> userForm,
  }) async {
    final url = '$baseUrl/admin/update-admin-by-admin/$userId';
    final body = jsonEncode({'userForm': userForm});

    print('API Request URL: $url'); // Log the URL
    print('Request Body: $body'); // Log the request body

    final response = await http.post(
      Uri.parse(url),
      headers: defaultHeaders,
      body: body,
    );

    print('Response Status: ${response.statusCode}'); // Log the response status
    print('Response Body: ${response.body}'); // Log the response body

    return jsonDecode(response.body);
  }

  /// Create admin/staff user by admin
  Future<Map<String, dynamic>> createAdminByAdmin({
    required Map<String, dynamic> userForm,
  }) async {
    final url = "$baseUrl/admin/create-admin-by-admin";
    final body = jsonEncode({'userForm': userForm});
    print('API: POST $url');
    print('Request body: $body');
    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {...defaultHeaders, 'Content-Type': 'application/json'},
        body: body,
      );
      print('Response status: ${resp.statusCode}');
      print('Response body: ${resp.body}');
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      print('createAdminByAdmin ERROR: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAdminUserByAdmin({
    required String userId,
  }) async {
    final url = "$baseUrl/admin/delete-admin-user-by-admin/$userId";
    try {
      final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getAllProducts() async {
    final url = "$baseUrl/product/get-all-products";
    final response = await http.get(Uri.parse(url), headers: defaultHeaders);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> fetchAllCategoriesEndpoint({
    int page = 1,
    int limit = 1000,
  }) async {
    final url =
        "$baseUrl/category/get-all-categorys-with-pagination?page=$page&limit=$limit";
    try {
      final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Future<Map<String, dynamic>> createProductMultipart({
  //   required String name,
  //   required String type,
  //   required String categoryId,
  //   required String subcategoryId,
  //   required String price,
  //   required String sku,
  //   required List<File> files,
  // }) async {
  //   final uri = Uri.parse('$baseUrl/product/create-product');
  //   final request = http.MultipartRequest('POST', uri);

  //   // add fields
  //   request.fields['name'] = name;
  //   request.fields['type'] = type;
  //   request.fields['categoryId'] = categoryId;
  //   request.fields['subcategoryId'] = subcategoryId;
  //   request.fields['price'] = price;
  //   request.fields['sku'] = sku;

  //   // attach files
  //   for (var f in files) {
  //     if (await f.exists()) {
  //       final multipart = await http.MultipartFile.fromPath('files', f.path);
  //       request.files.add(multipart);
  //     }
  //   }

  //   try {
  //     final streamed = await request.send();
  //     final resp = await http.Response.fromStream(streamed);
  //     try {
  //       return jsonDecode(resp.body) as Map<String, dynamic>;
  //     } catch (_) {
  //       return {
  //         'success': resp.statusCode >= 200 && resp.statusCode < 300,
  //         'message': resp.body,
  //         'statusCode': resp.statusCode,
  //       };
  //     }
  //   } catch (e) {
  //     return {'success': false, 'message': e.toString()};
  //   }
  // }

  Future<Map<String, dynamic>> createProductMultipart({
    required String name,
    required String type,
    required String categoryId,
    required List<String> categoryIds,
    required String price,
    required String sku,
    required List<File> productImages,
    required bool status,
  }) async {
    final uri = Uri.parse('$baseUrl/product/create-product');
    print('CREATE PRODUCT URL: $uri');

    final request = http.MultipartRequest('POST', uri);

    // fields expected by API
    request.fields['name'] = name;
    request.fields['sku'] = sku;
    request.fields['categoryId'] = categoryId;
    request.fields['type'] = type;
    request.fields['price'] = price;
    request.fields['status'] = status.toString();

    // // send each subcategory as separate form field so server receives an array
    // // e.g. subcategoryId[0]=id1, subcategoryId[1]=id2 ...
    // for (var i = 0; i < categoryIds.length; i++) {
    //   final id = categoryIds[i].toString();
    //   request.fields['subcategoryId'] = id;
    // }

    // add each subcategory as a separate multipart text part named 'subcategoryId'
    // (this produces repeated keys: subcategoryId=value for each selected id)
    for (var id in categoryIds) {
      try {
        request.files.add(
          http.MultipartFile.fromString('subcategoryId', id.toString()),
        );
      } catch (e) {
        print('CREATE PRODUCT - error adding subcategory field: $e');
      }
    }

    // add default headers if any (MultipartRequest sets Content-Type boundary)
    try {
      request.headers.addAll(defaultHeaders);
      request.headers.remove('Content-Type');
    } catch (_) {}

    // attach productImages as repeated multipart fields named 'productImages'
    final List<String> attachedFiles = [];
    for (var f in productImages) {
      try {
        if (await f.exists()) {
          final multipart = await http.MultipartFile.fromPath(
            'productImages', // backend expects repeated field 'productImages'
            f.path,
            filename: p.basename(f.path),
          );
          request.files.add(multipart);
          attachedFiles.add(f.path);
        } else {
          attachedFiles.add('missing:${f.path}');
        }
      } catch (e) {
        attachedFiles.add('error:${f.path}:${e.toString()}');
      }
    }

    // debug prints
    print(
      'CREATE PRODUCT - Multipart file fields: ${request.files.map((f) => f.field).toList()}',
    );
    print(
      'CREATE PRODUCT - Content-Type header that will be sent: ${request.headers['Content-Type'] ?? "not set (MultipartRequest sets it)"}',
    );
    print('CREATE PRODUCT - Request fields: ${request.fields}');
    print(
      'CREATE PRODUCT - Attached files paths (${attachedFiles.length}): $attachedFiles',
    );

    try {
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);

      print('CREATE PRODUCT - Response status: ${resp.statusCode}');
      print('CREATE PRODUCT - Response body: ${resp.body}');
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (e) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e, st) {
      print('CREATE PRODUCT - ERROR: $e\n$st');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Future<Map<String, dynamic>> createProductMultipart({
  //   required String name,
  //   required String type,
  //   required String mainCategoryId,
  //   required List<String> categoryIds,
  //   required String price,
  //   required String sku,
  //   required List<File> productImages,
  //   required bool status,
  // }) async {
  //   final uri = Uri.parse('$baseUrl/product/create-product');
  //   print('Creating product with name: $uri');

  //   final request = http.MultipartRequest('POST', uri);

  //   // fields expected by API (send categoryIds as JSON array string)
  //   request.fields['name'] = name;
  //   request.fields['sku'] = sku;
  //   request.fields['mainCategoryId'] = mainCategoryId;
  //   request.fields['categoryId'] = jsonEncode(categoryIds);
  //   request.fields['type'] = type;
  //   request.fields['price'] = price;
  //   request.fields['status'] = status.toString();

  //   // attach productImages as repeated multipart fields named 'productImages'
  //   for (var f in productImages) {
  //     if (await f.exists()) {
  //       final multipart = await http.MultipartFile.fromPath(
  //         'productImages',
  //         f.path,
  //         filename: p.basename(f.path),
  //       );
  //       request.files.add(multipart);
  //     }
  //   }

  //   try {
  //     final streamed = await request.send();
  //     final resp = await http.Response.fromStream(streamed);
  //     try {
  //       return jsonDecode(resp.body) as Map<String, dynamic>;
  //     } catch (_) {
  //       return {
  //         'success': resp.statusCode >= 200 && resp.statusCode < 300,
  //         'message': resp.body,
  //         'statusCode': resp.statusCode,
  //       };
  //     }
  //   } catch (e) {
  //     return {'success': false, 'message': e.toString()};
  //   }
  // }

  // Added: fetch all main categories
  Future<Map<String, dynamic>> getAllMainCategories() async {
    final url = "$baseUrl/mainCategory/get-all-main-categorys-with-pagination";
    final response = await http.get(Uri.parse(url), headers: defaultHeaders);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> uploadChallanSlip({
    required File file,
    required String challanId,
  }) async {
    final uri = Uri.parse('$baseUrl/challan/upload-slip');
    final request = http.MultipartRequest('POST', uri);
    try {
      // Attach auth headers if any (remove content-type header, MultipartRequest sets it)
      request.headers.addAll(defaultHeaders);
    } catch (_) {}

    // field for challan id
    request.fields['challanId'] = challanId;

    final fileName = p.basename(file.path);
    final multipartFile = await http.MultipartFile.fromPath(
      'biltiSlip',
      file.path,
      filename: fileName,
    );
    request.files.add(multipartFile);

    final streamed = await request.send();
    final respStr = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      try {
        return jsonDecode(respStr) as Map<String, dynamic>;
      } catch (_) {
        return {'success': true, 'url': respStr};
      }
    } else {
      try {
        return jsonDecode(respStr) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': false,
          'message': 'Upload failed',
          'statusCode': streamed.statusCode,
        };
      }
    }
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
    // final url = "$baseUrl/salesAndReports/get-jeans-shirt-revenue-and-order";
    // final response = await get(
    //   '/salesAndReports/get-jeans-shirt-revenue-and-order',
    // );
    // if (response.statusCode == 200) {
    //   return json.decode(response.body);
    // } else {
    //   throw Exception('Failed to fetch jeans/shirt revenue and order');
    // }
    final endpoint = '/salesAndReports/get-jeans-shirt-revenue-and-order';
    try {
      final response = await get(endpoint);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        print('fetchJeansShirtRevenueAndOrder decoded: $decoded');
        return decoded;
      } else {
        final msg =
            'Failed to fetch jeans/shirt revenue: ${response.statusCode} ${response.body}';
        print(msg);
        throw Exception(msg);
      }
    } catch (e, st) {
      print('fetchJeansShirtRevenueAndOrder ERROR: $e\n$st');
      rethrow;
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
    // final url = "$baseUrl/salesAndReports/get-SalesData";
    // final response = await get('/salesAndReports/get-SalesData');
    // if (response.statusCode == 200) {
    //   return json.decode(response.body);
    // } else {
    //   throw Exception('Failed to fetch sales data');
    // }
    final endpoint = '/salesAndReports/get-SalesData';
    try {
      final response = await get(endpoint);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        print('fetchSalesData decoded: $decoded');
        return decoded;
      } else {
        final msg =
            'Failed to fetch sales data: ${response.statusCode} ${response.body}';
        print(msg);
        throw Exception(msg);
      }
    } catch (e, st) {
      print('fetchSalesData ERROR: $e\n$st');
      rethrow;
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
    // Use GET for delete endpoint as requested
    final response = await get('/order/order-delete/$orderId');
    print(
      'Delete order by id (GET) response: ${response.statusCode} ${response.body}',
    );
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      // Fallback to a safe map if response is not valid JSON
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': response.body,
          'statusCode': response.statusCode,
        };
      }
      return {
        'success': false,
        'message': response.body,
        'statusCode': response.statusCode,
      };
    }
  }

  /// Move order to recycle bin (GET)
  /// Example endpoint: /order/move-to-recycle-bin/<orderId>
  Future<Map<String, dynamic>> moveOrderToRecycleBin(String orderId) async {
    final String url = '$baseUrl/order/move-to-recycle-bin/$orderId';
    print("Move order to recycle bin URL: $url");
    try {
      final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
      print('Move order to recycle bin response: ${resp.body}');

      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> moveOrderToOrder(String orderId) async {
    final String url = '$baseUrl/order/move-to-order/$orderId';
    print("Restore (move-to-order) URL: $url");
    try {
      final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
      print('Restore order response: ${resp.statusCode} ${resp.body}');
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      print('moveOrderToOrder ERROR: $e');
      return {'success': false, 'message': e.toString()};
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

  Future<Map<String, dynamic>> fetchAllRecycledOrdersByAdminWithPagination({
    int page = 1,
    int limit = 10,
  }) async {
    final String url =
        "$baseUrl/order/get-all-recycled-orders-by-admin-with-pagination";
    print('Fetch recycled orders URL: $url');
    try {
      final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
      print('Fetch recycled orders response: ${resp.statusCode} ${resp.body}');
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return {
          'success': resp.statusCode >= 200 && resp.statusCode < 300,
          'message': resp.body,
          'statusCode': resp.statusCode,
        };
      }
    } catch (e) {
      print('fetchAllRecycledOrdersByAdminWithPagination ERROR: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> fetchAllOrdersByAdminWithPagination({
    int page = 1,
    int limit = 10,
  }) async {
    final url = "$baseUrl/order/get-all-orders-by-admin-with-pagination";
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
    // final url = Uri.parse('$baseUrl$endpoint');
    // return await http.get(url, headers: headers);
    final String urlStr = endpoint.startsWith('http')
        ? endpoint
        : '$baseUrl$endpoint';
    print('API GET -> $urlStr');
    try {
      final uri = Uri.parse(urlStr);
      final resp = await http.get(uri, headers: headers);
      print(
        'API GET Response (${resp.statusCode}) from $urlStr : ${resp.body}',
      );
      return resp;
    } catch (e, st) {
      print('API GET ERROR -> $urlStr : $e\n$st');
      rethrow;
    }
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    // final url = Uri.parse('$baseUrl$endpoint');
    // return await http.post(url, headers: headers, body: body);
    final String urlStr = endpoint.startsWith('http')
        ? endpoint
        : '$baseUrl$endpoint';
    print('API POST -> $urlStr');
    try {
      final uri = Uri.parse(urlStr);
      final resp = await http.post(uri, headers: headers, body: body);
      print(
        'API POST Response (${resp.statusCode}) from $urlStr : ${resp.body}',
      );
      return resp;
    } catch (e, st) {
      print('API POST ERROR -> $urlStr : $e\n$st');
      rethrow;
    }
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

  // Future<Map<String, dynamic>> fetchAllRoles() async {
  //   // Returns the raw API response as Map
  //   final response = await get('/adminRole/get-all-roles');
  //   if (response.statusCode == 200) {
  //     return json.decode(response.body) as Map<String, dynamic>;
  //   } else {
  //     throw Exception('Failed to fetch roles: ${response.statusCode}');
  //   }
  // }

  // /// Convenience: fetch single role by id (calls fetchAllRoles and searches)
  // Future<Map<String, dynamic>?> getRoleById(String roleId) async {
  //   try {
  //     final resp = await fetchAllRoles();
  //     if (resp['data'] is List) {
  //       for (var r in resp['data']) {
  //         if (r is Map && (r['_id'] == roleId || r['id'] == roleId)) {
  //           return Map<String, dynamic>.from(r);
  //         }
  //       }
  //     }
  //     return null;
  //   } catch (e) {
  //     print('getRoleById error: $e');
  //     rethrow;
  //   }
  // }

  Future<Map<String, dynamic>> fetchAllRoles() async {
    final url = '$baseUrl/adminRole/get-all-roles';
    final resp = await http.get(Uri.parse(url), headers: defaultHeaders);
    if (resp.statusCode == 200) {
      return json.decode(resp.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch roles: ${resp.statusCode}');
  }

  Future<Map<String, dynamic>?> getRoleById(String roleId) async {
    try {
      final resp = await fetchAllRoles();
      final data = resp['data'];
      if (data is List) {
        for (final r in data) {
          if (r is Map && (r['_id'] == roleId || r['id'] == roleId)) {
            return Map<String, dynamic>.from(r);
          }
        }
      }
    } catch (e) {
      debugPrint('getRoleById error: $e');
    }
    return null;
  }
}
