import 'package:flutter/material.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';

class PermissionGate extends StatelessWidget {
  final String permissionOrRoute;
  final String action;
  final Widget child;
  final Widget? fallback;
  const PermissionGate({
    required this.permissionOrRoute,
    required this.action,
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AppDataRepo().currentUserHasPermission(
        permissionOrRoute,
        action,
        forceReload: true,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final ok = snap.data == true;
        return ok
            ? child
            : (fallback ?? const Center(child: Text('Access denied')));
      },
    );
  }
}
