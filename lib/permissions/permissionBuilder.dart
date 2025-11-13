import 'package:flutter/material.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';

typedef PermissionWidgetBuilder =
    Widget Function(BuildContext context, bool hasPermission);

class PermissionBuilder extends StatelessWidget {
  final String permissionOrRoute;
  final String action;
  final PermissionWidgetBuilder builder;

  const PermissionBuilder({
    required this.permissionOrRoute,
    required this.action,
    required this.builder,
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
      builder: (context, snapshot) {
        final has = snapshot.data == true;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return builder(context, has);
      },
    );
  }
}
