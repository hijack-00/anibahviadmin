import 'package:flutter/material.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';

mixin PermissionHelper<T extends StatefulWidget> on State<T> {
  final AppDataRepo _repo = AppDataRepo();
  bool canRead = false;
  bool canWrite = false;
  bool canUpdate = false;
  bool canDelete = false;
  bool _permissionsLoaded = false;

  /// Call from initState with route or permission key (e.g. '/orders' or 'orders')
  /// This forces a fresh roles fetch before evaluating permissions.
  Future<void> initPermissions(String permissionKey) async {
    // always fetch latest roles from server
    await _repo.loadRolesFromApi();

    final read = await _repo.currentUserHasPermission(permissionKey, 'read');
    final write = await _repo.currentUserHasPermission(permissionKey, 'write');
    final update = await _repo.currentUserHasPermission(
      permissionKey,
      'update',
    );
    final del = await _repo.currentUserHasPermission(permissionKey, 'delete');
    if (!mounted) return;
    setState(() {
      canRead = read;
      canWrite = write;
      canUpdate = update;
      canDelete = del;
      _permissionsLoaded = true;
    });
  }

  Widget buildWhileLoadingPermission({Widget? loader}) {
    return loader ?? const Center(child: CircularProgressIndicator());
  }

  bool permissionsReady() => _permissionsLoaded;
}
