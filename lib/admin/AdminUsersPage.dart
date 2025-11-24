import 'package:anibhaviadmin/widgets/universal_navbar.dart';
import 'package:anibhaviadmin/widgets/universal_scaffold.dart';
import 'package:anibhaviadmin/widgets/universal_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_data_repo.dart';
import 'package:anibhaviadmin/services/api_service.dart'; // Add this line
import 'package:anibhaviadmin/services/app_data_repo.dart';
import 'package:anibhaviadmin/permissions/permission_helper.dart';
import 'package:anibhaviadmin/permissions/navigateIfAllowed.dart';
import 'package:anibhaviadmin/permissions/permission_helper.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  _AdminUsersPageState createState() => _AdminUsersPageState();
}

// class _AdminUsersPageState extends State<AdminUsersPage> {
class _AdminUsersPageState extends State<AdminUsersPage> with PermissionHelper {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _admins = [];

  bool _disposed = false;
  List<Map<String, dynamic>> _adminUsers = [];
  List<Map<String, dynamic>> _filteredAdminUsers = [];
  // bool _loading = true;
  String _search = '';

  // New state for role chips
  List<String> _availableRoles = [];
  final Set<String> _selectedRoles = {};

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _newRole = '';
  String _newStatus = 'Active';
  final List<String> _defaultRoles = [
    'Viewer',
    'Manager',
    'Staff',
    'Super Admin',
    'Distributor',
  ];

  @override
  void initState() {
    super.initState();
    // initialize permissions first, then fetch admins only if read allowed
    initPermissions('/admin-users').then((_) {
      if (!mounted) return;
      debugPrint(
        'AdminUsersPage permissions: canRead=$canRead canWrite=$canWrite canUpdate=$canUpdate canDelete=$canDelete',
      );
      if (canRead) {
        _fetch();
      } else {
        setState(() {
          _loading = false;
          _adminUsers = [];
          _filteredAdminUsers = [];
        });
      }
    });

    // _fetch();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AppDataRepo().fetchAdminUsers(page: 1, limit: 1000);
      _users = data;
      _filtered = List<Map<String, dynamic>>.from(_users);

      // build available roles list (unique, preserve original casing)
      final roles = <String>{};
      for (final u in _users) {
        final r = (u['role'] ?? '').toString().trim();
        if (r.isNotEmpty) roles.add(r);
      }
      _availableRoles = roles.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    } catch (e) {
      _error = 'Failed to load users';
    }
    setState(() {
      _loading = false;
    });
  }

  void _applyFilter() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        final phone = (u['phone'] ?? '').toString().toLowerCase();
        final role = (u['role'] ?? '').toString().toLowerCase();

        final matchesQuery = q.isEmpty
            ? true
            : (name.contains(q) ||
                  email.contains(q) ||
                  phone.contains(q) ||
                  role.contains(q));

        final matchesRole = _selectedRoles.isEmpty
            ? true
            : _selectedRoles.any((sel) => sel.toLowerCase() == role);

        return matchesQuery && matchesRole;
      }).toList();
    });
  }

  // Toggle role chip selection
  void _toggleRole(String role) {
    setState(() {
      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }
      _applyFilter();
    });
  }

  // Clear all role selections
  void _clearRoleFilters() {
    setState(() {
      _selectedRoles.clear();
      _applyFilter();
    });
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Widget _roleChip(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Colors.indigo,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final s = status.toLowerCase();
    Color bg;
    if (s == 'active')
      bg = Colors.green.shade50;
    else if (s == 'inactive' || s == 'blocked')
      bg = Colors.red.shade50;
    else
      bg = Colors.grey.shade100;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: s == 'active' ? Colors.green.shade800 : Colors.grey.shade800,
          fontSize: 12,
        ),
      ),
    );
  }

  String _shortId(String id) {
    if (id == null) return '';
    final s = id.toString();
    return s.length > 15 ? s.substring(0, 15) + '...' : s;
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _confirmDelete(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete user "$name"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final resp = await AppDataRepo().deleteAdminUserByAdmin(id);
      final success =
          (resp['status'] == true) ||
          (resp['success'] == true) ||
          (resp['statusCode'] == 200);
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User deleted')));
        await _fetch();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(resp['message'] ?? 'Delete failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Widget _buildField(
    String label,
    TextEditingController c, {
    TextInputType? type,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: c,
            keyboardType: type,
            obscureText: obscure,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.indigo.shade400,
                  width: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateAdminSheet() async {
    _newRole = _availableRoles.isNotEmpty
        ? _availableRoles.first
        : _defaultRoles.first;
    _newStatus = 'Active';
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Add New Admin User',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            splashRadius: 20,
                            onPressed: () => Navigator.of(sheetCtx).pop(),
                          ),
                        ],
                      ),
                      const Divider(height: 16),

                      /// Helper to build text fields

                      /// INPUTS
                      _buildField('Full Name', _nameController),
                      const SizedBox(height: 10),
                      _buildField(
                        'Email Address',
                        _emailController,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      _buildField(
                        'Phone Number',
                        _phoneController,
                        type: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      // _buildField(
                      //   'Password',
                      //   _passwordController,
                      //   obscure: true,
                      // ),
                      PasswordField(
                        controller: _passwordController,
                      ), // Use the new PasswordField widget

                      const SizedBox(height: 14),

                      /// DROPDOWNS
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Role',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _newRole.isNotEmpty ? _newRole : null,
                                  items:
                                      (_availableRoles.isNotEmpty
                                              ? _availableRoles
                                              : _defaultRoles)
                                          .map(
                                            (r) => DropdownMenuItem(
                                              value: r,
                                              child: Text(
                                                r,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) =>
                                      setState(() => _newRole = v ?? ''),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _newStatus,
                                  items: ['Active', 'Inactive']
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _newStatus = v ?? 'Active',
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// ACTION BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => Navigator.of(sheetCtx).pop(),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                final name = _nameController.text.trim();
                                final email = _emailController.text.trim();
                                final phone = _phoneController.text.trim();
                                final password = _passwordController.text;
                                if (name.isEmpty ||
                                    email.isEmpty ||
                                    phone.isEmpty ||
                                    password.isEmpty ||
                                    _newRole.isEmpty) {
                                  ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please fill all fields'),
                                    ),
                                  );
                                  return;
                                }

                                final confirmed = await showDialog<bool>(
                                  context: sheetCtx,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm'),
                                    content: Text(
                                      'Create user "$name" with role "$_newRole"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true) return;

                                // Call API
                                final userForm = {
                                  "name": name,
                                  "email": email,
                                  "phone": phone,
                                  "password": password,
                                  "role": _newRole,
                                  "status": _newStatus,
                                  "oldPassword": "",
                                };

                                // show loading
                                showDialog(
                                  context: sheetCtx,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                try {
                                  final resp = await AppDataRepo()
                                      .createAdminUser(userForm: userForm);
                                  Navigator.of(
                                    sheetCtx,
                                  ).pop(); // remove loading
                                  final ok =
                                      (resp['status'] == true) ||
                                      (resp['success'] == true) ||
                                      (resp['statusCode'] == 200);
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'User created successfully',
                                        ),
                                      ),
                                    );
                                    await _fetch(); // refresh list
                                    Navigator.of(sheetCtx).pop(); // close sheet
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          resp['message']?.toString() ??
                                              'Create failed',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  Navigator.of(sheetCtx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Create failed: $e'),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Add User',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Future<void> _showEditAdminSheet(Map<String, dynamic> user) async {
  //   // Initialize controllers with current user data
  //   _nameController.text = user['name'] ?? '';
  //   _emailController.text = user['email'] ?? '';
  //   _phoneController.text = user['phone'] ?? '';
  //   _newRole = user['role'] ?? '';
  //   _newStatus = user['status'] ?? 'Active';

  //   await showModalBottomSheet<void>(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (sheetCtx) {
  //       return SafeArea(
  //         child: FractionallySizedBox(
  //           heightFactor: 0.9,
  //           child: Container(
  //             decoration: BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: const BorderRadius.vertical(
  //                 top: Radius.circular(16),
  //               ),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: Colors.black26.withOpacity(0.08),
  //                   blurRadius: 10,
  //                   offset: const Offset(0, -2),
  //                 ),
  //               ],
  //             ),
  //             child: Padding(
  //               padding: EdgeInsets.only(
  //                 left: 16,
  //                 right: 16,
  //                 top: 14,
  //                 bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
  //               ),
  //               child: SingleChildScrollView(
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     Text('Edit User', style: TextStyle(fontSize: 20)),
  //                     const SizedBox(height: 16),
  //                     _buildField('Full Name', _nameController),
  //                     const SizedBox(height: 10),
  //                     _buildField(
  //                       'Email Address',
  //                       _emailController,
  //                       type: TextInputType.emailAddress,
  //                     ),
  //                     const SizedBox(height: 10),
  //                     _buildField(
  //                       'Phone Number',
  //                       _phoneController,
  //                       type: TextInputType.phone,
  //                     ),
  //                     const SizedBox(height: 10),
  //                     // Add role and status dropdowns if needed
  //                     const SizedBox(height: 20),
  //                     ElevatedButton(
  //                       onPressed: () async {
  //                         final confirm = await showDialog<bool>(
  //                           context: context,
  //                           builder: (ctx) => AlertDialog(
  //                             title: const Text('Confirm Update'),
  //                             content: const Text(
  //                               'Are you sure you want to update this user?',
  //                             ),
  //                             actions: [
  //                               TextButton(
  //                                 onPressed: () => Navigator.of(ctx).pop(false),
  //                                 child: const Text('Cancel'),
  //                               ),
  //                               ElevatedButton(
  //                                 onPressed: () => Navigator.of(ctx).pop(true),
  //                                 child: const Text('Update'),
  //                               ),
  //                             ],
  //                           ),
  //                         );

  //                         if (confirm == true) {
  //                           await _updateUser(user['_id']);
  //                         }
  //                       },
  //                       child: const Text('Update User'),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // Future<void> _showEditAdminSheet(Map<String, dynamic> user) async {
  //   _nameController.text = user['name'] ?? '';
  //   _emailController.text = user['email'] ?? '';
  //   _phoneController.text = user['phone'] ?? '';
  //   _newRole = user['role'] ?? '';
  //   _newStatus = user['status'] ?? 'Active';

  //   await showModalBottomSheet<void>(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (sheetCtx) {
  //       return SafeArea(
  //         child: Container(
  //           height: MediaQuery.of(context).size.height * 0.9, // Full height
  //           padding: const EdgeInsets.all(16.0),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Edit User',
  //                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //               ),
  //               const SizedBox(height: 16),
  //               _buildField('Name', _nameController),
  //               const SizedBox(height: 16),
  //               _buildField('Email', _emailController),
  //               const SizedBox(height: 16),
  //               _buildField('Phone', _phoneController),
  //               const SizedBox(height: 16),
  //               _buildField('New Password', _passwordController, obscure: true),
  //               const SizedBox(height: 16),
  //               DropdownButtonFormField<String>(
  //                 value: _newRole,
  //                 decoration: InputDecoration(
  //                   labelText: 'Role',
  //                   filled: true,
  //                   fillColor: Colors.grey.shade50,
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                     borderSide: BorderSide(
  //                       color: Colors.grey.shade300,
  //                       width: 1,
  //                     ),
  //                   ),
  //                 ),
  //                 items: _defaultRoles.map((String role) {
  //                   return DropdownMenuItem<String>(
  //                     value: role,
  //                     child: Text(role),
  //                   );
  //                 }).toList(),
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _newRole = newValue ?? '';
  //                   });
  //                 },
  //               ),
  //               const SizedBox(height: 16),
  //               DropdownButtonFormField<String>(
  //                 value: _newStatus,
  //                 decoration: InputDecoration(
  //                   labelText: 'Status',
  //                   filled: true,
  //                   fillColor: Colors.grey.shade50,
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                     borderSide: BorderSide(
  //                       color: Colors.grey.shade300,
  //                       width: 1,
  //                     ),
  //                   ),
  //                 ),
  //                 items: ['Active', 'Inactive'].map((String status) {
  //                   return DropdownMenuItem<String>(
  //                     value: status,
  //                     child: Text(status),
  //                   );
  //                 }).toList(),
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _newStatus = newValue ?? 'Active';
  //                   });
  //                 },
  //               ),
  //               const SizedBox(height: 16),
  //               ElevatedButton(
  //                 onPressed: () async {
  //                   final confirm = await showDialog<bool>(
  //                     context: context,
  //                     builder: (ctx) => AlertDialog(
  //                       title: const Text('Confirm Update'),
  //                       content: const Text(
  //                         'Are you sure you want to update this user?',
  //                       ),
  //                       actions: [
  //                         TextButton(
  //                           onPressed: () => Navigator.of(ctx).pop(false),
  //                           child: const Text('Cancel'),
  //                         ),
  //                         ElevatedButton(
  //                           onPressed: () => Navigator.of(ctx).pop(true),
  //                           child: const Text('Update'),
  //                         ),
  //                       ],
  //                     ),
  //                   );

  //                   if (confirm == true) {
  //                     await _updateUser(user['_id']);
  //                   }
  //                 },
  //                 child: const Text('Update User'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // Future<void> _showEditAdminSheet(Map<String, dynamic> user) async {
  //   _nameController.text = user['name'] ?? '';
  //   _emailController.text = user['email'] ?? '';
  //   _phoneController.text = user['phone'] ?? '';
  //   _newRole = user['role'] ?? '';
  //   _newStatus = user['status'] ?? 'Active';

  //   await showModalBottomSheet<void>(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (sheetCtx) {
  //       return SafeArea(
  //         child: Container(
  //           height: MediaQuery.of(context).size.height * 0.9, // Full height
  //           padding: const EdgeInsets.all(16.0),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Edit User',
  //                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //               ),
  //               const SizedBox(height: 16),
  //               _buildField('Name', _nameController),
  //               const SizedBox(height: 16),
  //               _buildField('Email', _emailController),
  //               const SizedBox(height: 16),
  //               _buildField('Phone', _phoneController),
  //               const SizedBox(height: 16),
  //               // Add role and status selection if needed
  //               ElevatedButton(
  //                 onPressed: () async {
  //                   final userForm = {
  //                     "name": _nameController.text,
  //                     "email": _emailController.text,
  //                     "phone": _phoneController.text,
  //                     "oldPassword": "", // Handle old password appropriately
  //                     "role": _newRole,
  //                     "status": _newStatus,
  //                   };

  //                   print(
  //                     'User Form for Update: $userForm',
  //                   ); // Log the user form before updating

  //                   final confirm = await showDialog<bool>(
  //                     context: context,
  //                     builder: (ctx) => AlertDialog(
  //                       title: const Text('Confirm Update'),
  //                       content: const Text(
  //                         'Are you sure you want to update this user?',
  //                       ),
  //                       actions: [
  //                         TextButton(
  //                           child: const Text('Cancel'),
  //                           onPressed: () => Navigator.of(ctx).pop(false),
  //                         ),
  //                         ElevatedButton(
  //                           child: const Text('Update'),
  //                           onPressed: () => Navigator.of(ctx).pop(true),
  //                         ),
  //                       ],
  //                     ),
  //                   );

  //                   if (confirm == true) {
  //                     await _updateUser(user['_id']);
  //                   }
  //                 },
  //                 child: const Text('Update User'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // Future<void> _showEditAdminSheet(Map<String, dynamic> user) async {
  //   _nameController.text = user['name'] ?? '';
  //   _emailController.text = user['email'] ?? '';
  //   _phoneController.text = user['phone'] ?? '';
  //   _newRole = user['role'] ?? '';
  //   _newStatus = user['status'] ?? 'Active';

  //   await showModalBottomSheet<void>(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (sheetCtx) {
  //       return SafeArea(
  //         child: Container(
  //           height: MediaQuery.of(context).size.height * 0.9, // Full height
  //           padding: const EdgeInsets.all(16.0),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Edit User',
  //                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //               ),
  //               const SizedBox(height: 16),
  //               _buildField('Name', _nameController),
  //               const SizedBox(height: 16),
  //               _buildField('Email', _emailController),
  //               const SizedBox(height: 16),
  //               _buildField('Phone', _phoneController),
  //               const SizedBox(height: 16),
  //               _buildField('New Password', _passwordController, obscure: true),
  //               const SizedBox(height: 16),
  //               DropdownButtonFormField<String>(
  //                 value: _newRole,
  //                 decoration: InputDecoration(
  //                   labelText: 'Role',
  //                   filled: true,
  //                   fillColor: Colors.grey.shade50,
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                     borderSide: BorderSide(
  //                       color: Colors.grey.shade300,
  //                       width: 1,
  //                     ),
  //                   ),
  //                 ),
  //                 items: _defaultRoles.map((String role) {
  //                   return DropdownMenuItem<String>(
  //                     value: role,
  //                     child: Text(role),
  //                   );
  //                 }).toList(),
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _newRole = newValue ?? '';
  //                   });
  //                 },
  //               ),
  //               const SizedBox(height: 16),
  //               DropdownButtonFormField<String>(
  //                 value: _newStatus,
  //                 decoration: InputDecoration(
  //                   labelText: 'Status',
  //                   filled: true,
  //                   fillColor: Colors.grey.shade50,
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                     borderSide: BorderSide(
  //                       color: Colors.grey.shade300,
  //                       width: 1,
  //                     ),
  //                   ),
  //                 ),
  //                 items: ['Active', 'Inactive'].map((String status) {
  //                   return DropdownMenuItem<String>(
  //                     value: status,
  //                     child: Text(status),
  //                   );
  //                 }).toList(),
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _newStatus = newValue ?? 'Active';
  //                   });
  //                 },
  //               ),
  //               const SizedBox(height: 16),
  //               ElevatedButton(
  //                 onPressed: () async {
  //                   final userForm = {
  //                     "name": _nameController.text,
  //                     "email": _emailController.text,
  //                     "phone": _phoneController.text,
  //                     "oldPassword": "", // Handle old password appropriately
  //                     "password":
  //                         _passwordController.text, // Include new password
  //                     "role": _newRole,
  //                     "status": _newStatus,
  //                   };

  //                   print(
  //                     'User Form for Update: $userForm',
  //                   ); // Log the user form before updating

  //                   final confirm = await showDialog<bool>(
  //                     context: context,
  //                     builder: (ctx) => AlertDialog(
  //                       title: const Text('Confirm Update'),
  //                       content: const Text(
  //                         'Are you sure you want to update this user?',
  //                       ),
  //                       actions: [
  //                         TextButton(
  //                           child: const Text('Cancel'),
  //                           onPressed: () => Navigator.of(ctx).pop(false),
  //                         ),
  //                         ElevatedButton(
  //                           child: const Text('Update'),
  //                           onPressed: () => Navigator.of(ctx).pop(true),
  //                         ),
  //                       ],
  //                     ),
  //                   );

  //                   if (confirm == true) {
  //                     await _updateUser(user['_id']);
  //                   }
  //                 },
  //                 child: const Text('Update User'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  // Future<void> _showEditAdminSheet(Map<String, dynamic> user) async {
  //   _nameController.text = user['name'] ?? '';
  //   _emailController.text = user['email'] ?? '';
  //   _phoneController.text = user['phone'] ?? '';
  //   _newRole = user['role'] ?? '';
  //   _newStatus = user['status'] ?? 'Active';

  //   await showModalBottomSheet<void>(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (sheetCtx) {
  //       return SafeArea(
  //         child: Container(
  //           height: MediaQuery.of(context).size.height * 0.9, // Full height
  //           padding: const EdgeInsets.all(16.0),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //           ),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Edit User',
  //                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //               ),
  //               const SizedBox(height: 16),
  //               _buildField('Name', _nameController),
  //               const SizedBox(height: 16),
  //               _buildField('Email', _emailController),
  //               const SizedBox(height: 16),
  //               _buildField('Phone', _phoneController),
  //               const SizedBox(height: 16),
  //               _buildField('New Password', _passwordController, obscure: true),
  //               const SizedBox(height: 16),
  //               DropdownButtonFormField<String>(
  //                 value: _newRole,
  //                 decoration: InputDecoration(
  //                   labelText: 'Role',
  //                   filled: true,
  //                   fillColor: Colors.grey.shade50,
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                     borderSide: BorderSide(
  //                       color: Colors.grey.shade300,
  //                       width: 1,
  //                     ),
  //                   ),
  //                 ),
  //                 items: _defaultRoles.map((String role) {
  //                   return DropdownMenuItem<String>(
  //                     value: role,
  //                     child: Text(role),
  //                   );
  //                 }).toList(),
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _newRole = newValue ?? '';
  //                   });
  //                 },
  //               ),
  //               const SizedBox(height: 16),
  //               DropdownButtonFormField<String>(
  //                 value: _newStatus,
  //                 decoration: InputDecoration(
  //                   labelText: 'Status',
  //                   filled: true,
  //                   fillColor: Colors.grey.shade50,
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(8),
  //                     borderSide: BorderSide(
  //                       color: Colors.grey.shade300,
  //                       width: 1,
  //                     ),
  //                   ),
  //                 ),
  //                 items: ['Active', 'Inactive'].map((String status) {
  //                   return DropdownMenuItem<String>(
  //                     value: status,
  //                     child: Text(status),
  //                   );
  //                 }).toList(),
  //                 onChanged: (String? newValue) {
  //                   setState(() {
  //                     _newStatus = newValue ?? 'Active';
  //                   });
  //                 },
  //               ),
  //               const SizedBox(height: 16),
  //               ElevatedButton(
  //                 onPressed: () async {
  //                   final userForm = {
  //                     "name": _nameController.text,
  //                     "email": _emailController.text,
  //                     "phone": _phoneController.text,
  //                     "oldPassword": "", // Handle old password appropriately
  //                     "password":
  //                         _passwordController.text, // Include new password
  //                     "role": _newRole,
  //                     "status": _newStatus,
  //                   };

  //                   print(
  //                     'User Form for Update: $userForm',
  //                   ); // Log the user form before updating

  //                   final confirm = await showDialog<bool>(
  //                     context: context,
  //                     builder: (ctx) => AlertDialog(
  //                       title: const Text('Confirm Update'),
  //                       content: const Text(
  //                         'Are you sure you want to update this user?',
  //                       ),
  //                       actions: [
  //                         TextButton(
  //                           child: const Text('Cancel'),
  //                           onPressed: () => Navigator.of(ctx).pop(false),
  //                         ),
  //                         ElevatedButton(
  //                           child: const Text('Update'),
  //                           onPressed: () => Navigator.of(ctx).pop(true),
  //                         ),
  //                       ],
  //                     ),
  //                   );

  //                   if (confirm == true) {
  //                     await _updateUser(user['_id']);
  //                     Navigator.of(
  //                       context,
  //                     ).pop(); // Close the bottom sheet after update
  //                   }
  //                 },
  //                 child: const Text('Update User'),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget buildInput(
    String label,
    TextEditingController c, {
    TextInputType? type,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: c,
            keyboardType: type,
            obscureText: obscure,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.indigo.shade400,
                  width: 1.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ...existing code...

  Future<void> _showEditAdminSheet(Map<String, dynamic> user) async {
    _nameController.text = user['name'] ?? '';
    _emailController.text = user['email'] ?? '';
    _phoneController.text = user['phone'] ?? '';
    _newRole = user['role'] ?? '';
    _newStatus = user['status'] ?? 'Active';
    _passwordController.clear(); // Clear the password field

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit User', style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 16),
                      _buildField('Full Name', _nameController),
                      const SizedBox(height: 10),
                      _buildField(
                        'Email Address',
                        _emailController,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      _buildField(
                        'Phone Number',
                        _phoneController,
                        type: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      PasswordField(
                        controller: _passwordController,
                      ), // Use the new PasswordField widget

                      const SizedBox(height: 10),

                      /// Dropdowns Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Role',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _newRole.isNotEmpty ? _newRole : null,
                                  items: _defaultRoles
                                      .map(
                                        (role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(
                                            role,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _newRole = v ?? ''),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: _newStatus,
                                  items: ['Active', 'Inactive']
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _newStatus = v ?? 'Active',
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Update'),
                              content: const Text(
                                'Are you sure you want to update this user?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Update'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            final userForm = {
                              "name": _nameController.text,
                              "email": _emailController.text,
                              "phone": _phoneController.text,
                              "oldPassword":
                                  "", // Handle old password appropriately
                              "password": _passwordController.text.isNotEmpty
                                  ? _passwordController.text
                                  : "",
                              "role": _newRole,
                              "status": _newStatus,
                            };

                            print(
                              'User Form for Update: $userForm',
                            ); // Log the user form before updating

                            await _updateUser(
                              user['_id'],
                              userForm,
                            ); // Pass userForm here
                            Navigator.of(
                              context,
                            ).pop(); // Close the bottom sheet after update
                          }
                        },
                        child: const Text('Update User'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> userForm) async {
    try {
      final response = await AppDataRepo().updateAdminUserByAdmin(
        userId: userId,
        userForm: userForm, // Pass userForm directly
      );
      print('API Response: $response'); // Log the API response
      if (response['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin user updated successfully')),
        );
        await _fetch(); // Refresh the user list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Update failed')),
        );
      }
    } catch (e) {
      print('Error updating user: $e'); // Log the error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final name = u['name'] ?? 'Unknown';
    final email = u['email'] ?? '';
    final phone = u['phone'] ?? '';
    final id = u['_id'] ?? u['id'] ?? '';
    final role = u['role'] ?? '';
    final status = u['status'] ?? '';
    final created = _formatDate(u['createdAt']?.toString());
    final lastLogin = _formatDate(u['lastLogin']?.toString()); // Add last login

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Header row with avatar + name + role chips
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.indigo.shade100,
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                _roleChip(role),
                                SizedBox(width: 6),
                                _statusChip(status),
                              ],
                            ),
                            // const SizedBox(width: 6),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Text(
                        //   'ID: ${_shortId(id)}',
                        //   style: TextStyle(
                        //     fontSize: 11,
                        //     color: Colors.grey.shade600,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade200, thickness: 1, height: 12),

              /// Contact info section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last Login: $lastLogin', // Display last login
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Created: $created',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: Colors.grey.shade200, thickness: 1, height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canUpdate)
                    Tooltip(
                      message: canUpdate ? 'Edit' : 'Access denied',
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.indigo,
                          side: BorderSide(color: Colors.indigo.shade200),
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          minimumSize: const Size(0, 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // disable when no update permission
                        onPressed: () => _showEditAdminSheet(u),

                        icon: const Icon(Icons.edit, size: 15),
                        label: const Text(
                          'Edit',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (canDelete)
                    Tooltip(
                      message: canDelete ? 'Delete' : 'Access denied',
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          minimumSize: Size(32, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        // disable when no delete permission
                        onPressed: canDelete
                            ? () => _confirmDelete(
                                u['_id'].toString(),
                                u['name'].toString(),
                              )
                            : null,
                        icon: const Icon(Icons.delete, size: 15),
                        label: const Text(
                          'Delete',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),

              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     OutlinedButton.icon(
              //       style: OutlinedButton.styleFrom(
              //         foregroundColor: Colors.indigo,
              //         side: BorderSide(color: Colors.indigo.shade200),
              //         padding: const EdgeInsets.symmetric(
              //           vertical: 6,
              //           horizontal: 12,
              //         ),
              //         minimumSize: const Size(0, 32),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //       ),
              //       onPressed: () {
              //         _showEditAdminSheet(u); // Pass user data to edit
              //       },
              //       icon: const Icon(Icons.edit, size: 15),
              //       label: const Text('Edit', style: TextStyle(fontSize: 12)),
              //     ),
              //     const SizedBox(width: 8),
              //     ElevatedButton.icon(
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Colors.red.shade600,
              //         foregroundColor: Colors.white,
              //         padding: const EdgeInsets.symmetric(
              //           vertical: 6,
              //           horizontal: 12,
              //         ),
              //         minimumSize: Size(32, 0),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //       ),
              //       onPressed: () => _confirmDelete(
              //         u['_id'].toString(),
              //         u['name'].toString(),
              //       ),
              //       icon: const Icon(Icons.delete, size: 15),
              //       label: const Text('Delete', style: TextStyle(fontSize: 12)),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // Clear all filters and selections
  void _clearAllFilters() {
    _searchController.clear();
    _clearRoleFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // show skeleton while permissions check runs
    if (!permissionsReady()) {
      return UniversalScaffold(
        selectedIndex: 7,
        appIcon: Icons.admin_panel_settings,
        title: 'Admin & Staffs',
        body: ListView.builder(
          itemCount: 3,
          itemBuilder: (context, idx) {
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(
                    4,
                    (i) => Container(
                      height: 12,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // if no read permission, show access denied
    if (!canRead) {
      return UniversalScaffold(
        selectedIndex: 7,
        appIcon: Icons.admin_panel_settings,
        title: 'Admin & Staffs',
        body: Center(
          child: Text('You do not have permission to view Admin & Staffs'),
        ),
      );
    }
    return UniversalScaffold(
      selectedIndex: 0,
      title: 'User & Role Management',
      appIcon: Icons.admin_panel_settings,
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 12),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, email or mobile',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),

              // NEW: Role filter chips
              if (_availableRoles.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _availableRoles.map((role) {
                              final selected = _selectedRoles.contains(role);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(
                                    role,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  selected: selected,
                                  onSelected: (_) => _toggleRole(role),
                                  selectedColor: Colors.indigo.shade50,
                                  checkmarkColor: Colors.indigo,
                                  backgroundColor: Colors.grey.shade100,
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? Colors.indigo.shade800
                                        : Colors.black87,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      if (_selectedRoles.isNotEmpty)
                        TextButton(
                          onPressed: _clearRoleFilters,
                          child: const Text(
                            'Clear',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          return _buildUserCard(_filtered[i]);
                        },
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              onPressed: _showCreateAdminSheet,
              label: const Text('Add Admin', style: TextStyle(fontSize: 12)),
              icon: const Icon(Icons.person_add, size: 18),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const PasswordField({Key? key, required this.controller}) : super(key: key);

  @override
  _PasswordFieldState createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: widget.controller,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.indigo.shade400,
                  width: 1.3,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
