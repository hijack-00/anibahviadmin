import 'universal_navbar.dart';
import 'dart:convert';

import 'package:anibhaviadmin/screens/userDetailsPage.dart';
import 'package:flutter/material.dart';
import '../services/app_data_repo.dart';
// import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

class UsersPage extends StatefulWidget {
  final bool showActive;
  UsersPage({Key? key, required this.showActive}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

Future<bool?> showUserCreationDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => _UserCreationDialog(),
  );
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  bool _disposed = false;
  List<Map<String, dynamic>> _activeUsers = [];
  List<Map<String, dynamic>> _inactiveUsers = [];
  List<Map<String, dynamic>> _filteredActive = [];
  List<Map<String, dynamic>> _filteredInactive = [];
  bool _loading = true;
  String _searchActive = '';
  String _searchInactive = '';
  late TabController _tabController;
  // Single search controller shared between both tabs
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.showActive ? 0 : 1,
    );
    _fetchUsers();
  }

  @override
  void dispose() {
    _disposed = true;
    _tabController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (_disposed) return;
    setState(() {
      _loading = true;
    });
    try {
      final repo = AppDataRepo();
      await repo.loadAllUsers();
      final users = AppDataRepo.users;
      if (_disposed) return;
      setState(() {
        _activeUsers = users.where((u) => u['isActive'] == true).toList();
        _inactiveUsers = users.where((u) => u['isActive'] == false).toList();
        _filteredActive = _activeUsers;
        _filteredInactive = _inactiveUsers;
        _loading = false;
      });
      // Preload orders for all users after fetching
      await _preloadUserOrders(users);
      if (_disposed) return;
      setState(() {}); // trigger rebuild after cache
    } catch (e) {
      if (_disposed) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    }
  }

  // Single search function applied to both active & inactive users.
  Future<void> _applySearch(String value) async {
    if (_disposed) return;
    final q = value.trim().toLowerCase();
    setState(() {
      _searchQuery = q;
      // if empty, show all
      if (q.isEmpty) {
        _filteredActive = List.from(_activeUsers);
        _filteredInactive = List.from(_inactiveUsers);
      } else {
        _filteredActive = _activeUsers.where((u) {
          final name = (u['name'] ?? '').toString().toLowerCase();
          final shop = (u['shopname'] ?? '').toString().toLowerCase();
          final phone = (u['phone'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          return name.contains(q) ||
              shop.contains(q) ||
              phone.contains(q) ||
              email.contains(q);
        }).toList();

        _filteredInactive = _inactiveUsers.where((u) {
          final name = (u['name'] ?? '').toString().toLowerCase();
          final shop = (u['shopname'] ?? '').toString().toLowerCase();
          final phone = (u['phone'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          return name.contains(q) ||
              shop.contains(q) ||
              phone.contains(q) ||
              email.contains(q);
        }).toList();
      }
    });

    // preload orders for the filtered users (both lists) to keep UI consistent
    final combined = <Map<String, dynamic>>[];
    combined.addAll(_filteredActive);
    combined.addAll(_filteredInactive);
    await _preloadUserOrders(combined);
    if (_disposed) return;
    setState(() {});
  }

  // void _searchUsers(bool active, String value) async {
  //   if (_disposed) return;
  //   final q = value.trim().toLowerCase();
  //   setState(() {
  //     if (active) {
  //       _searchActive = value;
  //       _filteredActive = _activeUsers.where((u) {
  //         final name = (u['name'] ?? '').toString().toLowerCase();
  //         final shop = (u['shopname'] ?? '').toString().toLowerCase();
  //         final phone = (u['phone'] ?? '').toString().toLowerCase();
  //         final email = (u['email'] ?? '').toString().toLowerCase();
  //         return name.contains(q) ||
  //             shop.contains(q) ||
  //             phone.contains(q) ||
  //             email.contains(q);
  //       }).toList();
  //     } else {
  //       _searchInactive = value;
  //       _filteredInactive = _inactiveUsers.where((u) {
  //         final name = (u['name'] ?? '').toString().toLowerCase();
  //         final shop = (u['shopname'] ?? '').toString().toLowerCase();
  //         final phone = (u['phone'] ?? '').toString().toLowerCase();
  //         final email = (u['email'] ?? '').toString().toLowerCase();
  //         return name.contains(q) ||
  //             shop.contains(q) ||
  //             phone.contains(q) ||
  //             email.contains(q);
  //       }).toList();
  //     }
  //   });
  //   // Preload orders for filtered users after search
  //   await _preloadUserOrders(active ? _filteredActive : _filteredInactive);
  //   if (_disposed) return;
  //   setState(() {});
  // }

  // Cache for user orders and spent
  Map<String, Map<String, dynamic>> _userOrderCache = {};

  Future<void> _preloadUserOrders(List<Map<String, dynamic>> users) async {
    for (final user in users) {
      final userId = user['_id'];
      if (!_userOrderCache.containsKey(userId)) {
        try {
          final resp = await AppDataRepo().fetchOrdersByUserId(userId);
          int orderCount = 0;
          double totalSpent = 0;
          if (resp['success'] == true) {
            final orders = List<Map<String, dynamic>>.from(
              resp['orders'] ?? [],
            );
            orderCount = orders.length;
            totalSpent = orders.fold(
              0,
              (sum, o) =>
                  sum +
                  (double.tryParse(o['totalAmount']?.toString() ?? '0') ?? 0),
            );
          }
          _userOrderCache[userId] = {
            'orderCount': orderCount,
            'totalSpent': totalSpent,
          };
        } catch (_) {
          _userOrderCache[userId] = {'orderCount': 0, 'totalSpent': 0.0};
        }
      }
    }
  }

  // Remove didChangeDependencies override (no longer needed)

  Widget _buildUserList(List<Map<String, dynamic>> users) {
    if (users.isEmpty) {
      return Center(child: Text('No users found'));
    }
    // return ListView.builder(
    // wrap list with RefreshIndicator so user can pull to refresh the whole users list
    return RefreshIndicator(
      onRefresh: _fetchUsers,
      child: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, idx) {
          final user = users[idx];
          final cache = _userOrderCache[user['_id']];
          final shopName = user['shopname'] ?? '';
          final addressObj = user['address'] ?? {};
          final address = [
            addressObj['street'],
            addressObj['city'],
            addressObj['state'],
            addressObj['zipCode'],
            addressObj['country'],
          ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
          return Card(
            color: Colors.white,
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserDetailsPage(userId: user['_id']),
                  ),
                );
                _fetchUsers();
              },
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage:
                              user['photo'] != null &&
                                  user['photo'].toString().isNotEmpty
                              ? NetworkImage(user['photo'])
                              : null,
                          child:
                              user['photo'] == null ||
                                  user['photo'].toString().isEmpty
                              ? Icon(Icons.person, size: 28, color: Colors.grey)
                              : null,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                shopName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo,
                                ),
                              ),
                              if ((user['email'] ?? '').toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    user['email'],
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              if ((user['phone'] ?? '').toString().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    user['phone'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (address.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    address,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  cache == null
                                      ? Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 22,
                                                decoration: BoxDecoration(
                                                  color: Colors.yellow[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Container(
                                                width: 80,
                                                height: 22,
                                                decoration: BoxDecoration(
                                                  color: Colors.indigo[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Expanded(
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.yellow[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Orders: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${cache['orderCount']}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[100],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Spent: ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    Text(
                                                      '₹${cache['totalSpent'].toStringAsFixed(2)}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Removed chevron arrow to avoid overlay with status icon
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Icon(
                      user['isActive'] == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: user['isActive'] == true
                          ? Colors.green
                          : Colors.red,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onNavTap(int index) {
    String? route;
    switch (index) {
      case 0:
        route = '/dashboard';
        break;
      case 1:
        route = '/orders';
        break;
      case 2:
        route = '/users';
        break;
      case 3:
        route = '/catalogue';
        break;
      case 4:
        route = '/challan';
        break;
    }
    if (route != null && ModalRoute.of(context)?.settings.name != route) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (r) => r.settings.name == '/dashboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Replace your appBar property in Scaffold with this:
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade500, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Users',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: _loading
          ? _UsersSkeleton()
          : Column(
              children: [
                // TabBar + single shared search bar
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.indigo,
                        labelColor: Colors.indigo,
                        unselectedLabelColor: Colors.grey,
                        tabs: const [
                          Tab(text: 'Active Users'),
                          Tab(text: 'Inactive Users'),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search by name / shop / phone / email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                          onChanged: (v) => _applySearch(v),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Active
                      _filteredActive.isEmpty && !_loading
                          ? Center(child: Text('No users found'))
                          : _buildUserList(_filteredActive),
                      // Inactive
                      _filteredInactive.isEmpty && !_loading
                          ? Center(child: Text('No users found'))
                          : _buildUserList(_filteredInactive),
                    ],
                  ),
                ),
                // Container(
                //   color: Colors.white,
                //   child: TabBar(
                //     controller: _tabController,
                //     indicatorColor: Colors.indigo,
                //     labelColor: Colors.indigo,
                //     unselectedLabelColor: Colors.grey,
                //     tabs: [
                //       Tab(text: 'Active Users'),
                //       Tab(text: 'Inactive Users'),
                //     ],
                //   ),
                // ),
                // Expanded(
                //   child: TabBarView(
                //     controller: _tabController,
                //     children: [
                //       Column(
                //         children: [
                //           Padding(
                //             padding: const EdgeInsets.all(16.0),
                //             child: TextField(
                //               decoration: InputDecoration(
                //                 labelText: 'Search by name',
                //                 border: OutlineInputBorder(),
                //                 prefixIcon: Icon(Icons.search),
                //               ),
                //               onChanged: (v) => _searchUsers(true, v),
                //             ),
                //           ),
                //           Expanded(child: _buildUserList(_filteredActive)),
                //         ],
                //       ),
                //       Column(
                //         children: [
                //           Padding(
                //             padding: const EdgeInsets.all(16.0),
                //             child: TextField(
                //               decoration: InputDecoration(
                //                 labelText: 'Search by name',
                //                 border: OutlineInputBorder(),
                //                 prefixIcon: Icon(Icons.search),
                //               ),
                //               onChanged: (v) => _searchUsers(false, v),
                //             ),
                //           ),
                //           Expanded(child: _buildUserList(_filteredInactive)),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
        onPressed: () async {
          final created = await showUserCreationDialog(context);
          if (created == true) {
            _fetchUsers();
          }
        },
      ),
      bottomNavigationBar: UniversalNavBar(selectedIndex: 2, onTap: _onNavTap),
    );
  }
}

class _UsersSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, idx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, color: Colors.white),
                      SizedBox(height: 8),
                      Container(height: 12, width: 80, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserCreationDialog extends StatefulWidget {
  @override
  State<_UserCreationDialog> createState() => _UserCreationDialogState();
}

class _UserCreationDialogState extends State<_UserCreationDialog> {
  // Step 1: Email/OTP
  final TextEditingController _emailController = TextEditingController();
  bool _emailSent = false;
  String? _emailError;
  bool _emailLoading = false;

  // Step 2: User Details
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _detailsEnabled = false;
  String? _detailsError;
  bool _detailsLoading = false;
  String? _userId;

  // Step 3: Address/Photo
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _shopnameController = TextEditingController();
  File? _photoFile;
  bool _addressEnabled = false;
  String? _addressError;
  bool _addressLoading = false;
  bool _autoLocationLoading = false;

  Future<void> _sendOtp() async {
    setState(() {
      _emailError = null;
      _emailLoading = true;
    });
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailError = 'Please enter email';
        _emailLoading = false;
      });
      return;
    }
    try {
      final repo = AppDataRepo();
      final resp = await repo.sendOtpForUserSignup(email);
      if (resp['success'] == true) {
        setState(() {
          _emailSent = true;
          _detailsEnabled = true;
        });
      } else {
        setState(() {
          _emailError = resp['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      setState(() {
        _emailError = e.toString();
      });
    } finally {
      setState(() {
        _emailLoading = false;
      });
    }
  }

  Future<void> _verifyOtpAndDetails() async {
    setState(() {
      _detailsError = null;
      _detailsLoading = true;
    });
    final otp = _otpController.text.trim();
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();
    if (otp.isEmpty || name.isEmpty || mobile.isEmpty || password.isEmpty) {
      setState(() {
        _detailsError = 'Please fill all fields';
        _detailsLoading = false;
      });
      return;
    }
    try {
      final repo = AppDataRepo();
      final resp = await repo.verifyOtpForUserSignup(
        fullName: name,
        mobile: mobile,
        email: _emailController.text.trim(),
        otp: otp,
        password: password,
      );
      if (resp['status'] == true &&
          resp['data'] != null &&
          resp['data']['user'] != null) {
        setState(() {
          _userId = resp['data']['user']['_id'];
          _addressEnabled = true;
        });
      } else {
        setState(() {
          _detailsError = resp['message'] ?? 'Failed to verify OTP';
        });
      }
    } catch (e) {
      setState(() {
        _detailsError = e.toString();
      });
    } finally {
      setState(() {
        _detailsLoading = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _photoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _autoDetectLocation() async {
    setState(() {
      _autoLocationLoading = true;
    });
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      setState(() {
        _autoLocationLoading = false;
      });
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        setState(() {
          _autoLocationLoading = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      setState(() {
        _autoLocationLoading = false;
      });
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print(
        'Auto location output: ${position.latitude}, ${position.longitude}',
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _streetController.text = place.street ?? '';
          _cityController.text = place.locality ?? '';
          _stateController.text = place.administrativeArea ?? '';
          _zipController.text = place.postalCode ?? '';
          _countryController.text = place.country ?? '';
        });
        print('Auto location address: ${place.toString()}');
      }
    } catch (e) {
      print('Auto location error: $e');
    } finally {
      setState(() {
        _autoLocationLoading = false;
      });
    }
  }

  Future<void> _createUser() async {
    setState(() {
      _addressError = null;
      _addressLoading = true;
    });
    try {
      final repo = AppDataRepo();
      final resp = await repo.updateUserWithPhoto(
        userId: _userId ?? '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipController.text.trim(),
        country: _countryController.text.trim(),
        phone: _mobileController.text.trim(),
        shopname: _shopnameController.text.trim(),
        photoPath: _photoFile?.path ?? '',
      );
      if (resp['success'] == true) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User Created Successfully!')));
      } else {
        setState(() {
          _addressError = resp['message'] ?? 'Failed to update user';
        });
      }
    } catch (e) {
      setState(() {
        _addressError = e.toString();
      });
    } finally {
      setState(() {
        _addressLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDialogHeight = MediaQuery.of(context).size.height * 0.7;
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      textStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: EdgeInsets.symmetric(vertical: 10),
    );
    final textFieldDecoration = (String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    );
    return AlertDialog(
      title: Text('Create User'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: 450,
          minWidth: 290, // wider dialog
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Step 1: Email/OTP
              TextField(
                controller: _emailController,
                decoration: textFieldDecoration('Email'),
                enabled: !_emailSent,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed: _emailLoading || _emailSent ? null : _sendOtp,
                      child: _emailLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Send OTP'),
                    ),
                  ),
                ],
              ),
              if (_emailError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    _emailError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Divider(height: 16),
              // Step 2: User Details
              TextField(
                controller: _otpController,
                decoration: textFieldDecoration('OTP').copyWith(
                  suffixIcon: (_otpController.text.length > 6)
                      ? Tooltip(
                          message: 'Max 6 digits allowed',
                          child: Icon(Icons.warning, color: Colors.red),
                        )
                      : null,
                  counterText: '',
                ),
                enabled: _detailsEnabled && !_addressEnabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: textFieldDecoration('Full Name'),
                enabled: _detailsEnabled && !_addressEnabled,
                keyboardType: TextInputType.name,
              ),
              SizedBox(height: 6),
              TextField(
                controller: _mobileController,
                decoration: textFieldDecoration('Mobile').copyWith(
                  suffixIcon: (_mobileController.text.length > 10)
                      ? Tooltip(
                          message: 'Max 10 digits allowed',
                          child: Icon(Icons.warning, color: Colors.red),
                        )
                      : null,
                  counterText: '',
                ),
                enabled: _detailsEnabled && !_addressEnabled,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                decoration: textFieldDecoration('Password'),
                obscureText: true,
                enabled: _detailsEnabled && !_addressEnabled,
                keyboardType: TextInputType.visiblePassword,
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed:
                          _detailsLoading || !_detailsEnabled || _addressEnabled
                          ? null
                          : _verifyOtpAndDetails,
                      child: _detailsLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Verify & Next'),
                    ),
                  ),
                ],
              ),
              if (_detailsError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    _detailsError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              Divider(height: 16),
              // Step 3: Address/Photo
              GestureDetector(
                onTap: _addressEnabled ? _pickPhoto : null,
                child: CircleAvatar(
                  radius: 32,
                  backgroundImage: _photoFile != null
                      ? FileImage(_photoFile!)
                      : null,
                  child: _photoFile == null
                      ? Icon(Icons.camera_alt, size: 24)
                      : null,
                ),
              ),
              SizedBox(height: 6),
              Text('Tap to upload photo'),
              SizedBox(height: 6),
              TextField(
                controller: _shopnameController,
                decoration: textFieldDecoration('Shop Name'),
                enabled: _addressEnabled,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed: _addressEnabled && !_autoLocationLoading
                          ? _autoDetectLocation
                          : null,
                      child: _autoLocationLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Auto Detect Location'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              TextField(
                controller: _streetController,
                decoration: textFieldDecoration('Street'),
                enabled: _addressEnabled,
                keyboardType: TextInputType.streetAddress,
              ),
              SizedBox(height: 6),
              TextField(
                controller: _cityController,
                decoration: textFieldDecoration('City'),
                enabled: _addressEnabled,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 6),
              TextField(
                controller: _stateController,
                decoration: textFieldDecoration('State'),
                enabled: _addressEnabled,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 6),
              TextField(
                controller: _zipController,
                decoration: textFieldDecoration('Zip Code').copyWith(
                  suffixIcon: (_zipController.text.length > 6)
                      ? Tooltip(
                          message: 'Max 6 digits allowed',
                          child: Icon(Icons.warning, color: Colors.red),
                        )
                      : null,
                  counterText: '', // Hide default counter
                ),
                enabled: _addressEnabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => setState(() {}),
              ),
              SizedBox(height: 6),
              TextField(
                controller: _countryController,
                decoration: textFieldDecoration('Country'),
                enabled: _addressEnabled,
                keyboardType: TextInputType.text,
              ),

              SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: buttonStyle,
                      onPressed: _addressLoading || !_addressEnabled
                          ? null
                          : _createUser,
                      child: _addressLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Create User'),
                    ),
                  ),
                ],
              ),
              if (_addressError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    _addressError!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
