import 'package:flutter/material.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';

class PermissionButton extends StatelessWidget {
  final String permissionOrRoute;
  final String action;
  final VoidCallback onPressed;
  final Widget child;
  final bool disableInsteadOfHide;
  const PermissionButton({
    required this.permissionOrRoute,
    required this.action,
    required this.onPressed,
    required this.child,
    this.disableInsteadOfHide = false,
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
        final allowed = snap.data == true;
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 48,
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!allowed && !disableInsteadOfHide) return const SizedBox.shrink();
        return Opacity(
          opacity: allowed ? 1.0 : 0.5,
          child: ElevatedButton(
            onPressed: allowed ? onPressed : null,
            child: child,
          ),
        );
      },
    );
  }
}
