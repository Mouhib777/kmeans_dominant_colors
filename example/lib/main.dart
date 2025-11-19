import 'package:flutter/material.dart';
import 'package:kmeans_dominant_colors_example/color_extraction_page.dart';

void main() {
  runApp(const DominantColorsApp());
}

class DominantColorsApp extends StatelessWidget {
  const DominantColorsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dominant Colors Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ColorExtractionPage(),
    );
  }
}
