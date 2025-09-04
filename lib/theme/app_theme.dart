import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    primary: Colors.indigo,
    secondary: Colors.grey,
    background: Colors.white,
  ),
  textTheme: TextTheme(
    headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
    bodyMedium: TextStyle(color: Colors.grey[800]),
  ),
);
