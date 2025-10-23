import 'package:flutter/material.dart';
import 'package:project_application/mainpage.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // WAJIB sebelum setAccessToken

  MapboxOptions.setAccessToken(
    "pk.eyJ1IjoiamhhbG9wYXgyMyIsImEiOiJjbWZmY3dhM2IwMmxsMmxzN2dtcmN2OXV1In0.CxFnHlofcKHP9Z_nPMwx9g",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-Commerce App',
      home: const MainPage(), // MainPage jadi landing page
    );
  }
}
