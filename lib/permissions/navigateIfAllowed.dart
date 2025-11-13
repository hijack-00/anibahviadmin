import 'package:flutter/material.dart';
import 'package:anibhaviadmin/services/app_data_repo.dart';

Future<bool> navigateIfAllowed(
  BuildContext context,
  String routeName,
  String action, {
  Object? arguments,
}) async {
  // force fresh permission fetch
  final allowed = await AppDataRepo().currentUserHasPermission(
    routeName,
    action,
    forceReload: true,
  );
  if (allowed) {
    Navigator.of(context).pop(); // close drawer / sheet if any
    final current = ModalRoute.of(context)?.settings.name;
    if (current == routeName) return true;
    if (routeName == '/dashboard') {
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (r) => false);
    } else {
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
    }
    return true;
  } else {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Access denied')));
    return false;
  }
}
