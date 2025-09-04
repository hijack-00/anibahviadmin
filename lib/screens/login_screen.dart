import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../services/app_data_repo.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _showPassword = false;

  final AppDataRepo _appDataRepo = AppDataRepo();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final loggedIn = await _appDataRepo.isLoggedIn();
    if (loggedIn) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _login() async {
  final apiService = ApiService();
  final fullUrl = apiService.baseUrl + '/admin/admin-login';
  print('Login endpoint URL: ' + fullUrl);
    setState(() {
      _error = null;
      _loading = true;
    });
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _error = 'Please enter email/mobile and password';
        _loading = false;
      });
      return;
    }
    final requestBody = {
      'email': _emailController.text.toString(),
      'password': _passwordController.text.toString(),
    };
    print('Login request body: ' + jsonEncode(requestBody));
    try {
      // Use AppDataRepo to call the API and save user data
      final apiService = ApiService();
  final response = await apiService.post('/admin/admin-login',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
  print('Login response code: ' + response.statusCode.toString());
  print('Login response: ' + response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          await _appDataRepo.saveUserData(data['data']['user'], data['data']['token']);
          setState(() { _loading = false; });
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          setState(() {
            _error = data['message'] ?? 'Login failed';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Login failed: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Mobile or Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                  ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Forgot Password'),
                    content: Text('Password reset link sent (dummy).'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              child: Text('Forgot Password?'),
            ),
          ],
        ),
      ),
    );
  }
}
