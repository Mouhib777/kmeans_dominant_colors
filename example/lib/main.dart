import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:kmeans_dominant_colors/kmeans_dominant_colors.dart';

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
      home: const ColorExtractionPage(),
    );
  }
}

class ColorExtractionPage extends StatefulWidget {
  const ColorExtractionPage({super.key});

  @override
  State<ColorExtractionPage> createState() => _ColorExtractionPageState();
}

class _ColorExtractionPageState extends State<ColorExtractionPage> {
  List<Color>? _dominantColors;
  List<ColorCluster>? _detailedClusters;
  bool _isLoading = false;
  String? _errorMessage;

  final _imageAssets = [
    'assets/sample1.jpg',
    'assets/sample2.jpg',
    'assets/sample3.jpg',
  ];

  Future<img.Image?> _loadImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      return img.decodeImage(bytes);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load image: $e';
      });
      return null;
    }
  }

  Future<void> _extractColors(String assetPath) async {
    setState(() {
      _isLoading = true;
      _dominantColors = null;
      _detailedClusters = null;
      _errorMessage = null;
    });

    try {
      final image = await _loadImage(assetPath);
      if (image == null) return;

      // Extract basic colors
      final colors = KMeansDominantColors.extract(
        image: image,
        count: 5,
        maxIterations: 15,
      );

      // Extract detailed clusters
      final clusters = KMeansDominantColors.extractDetailed(
        image: image,
        count: 5,
        maxIterations: 15,
      );

      setState(() {
        _dominantColors = colors;
        _detailedClusters = clusters;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error extracting colors: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildColorPalette(List<Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dominant Colors:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.asMap().entries.map((entry) {
            final index = entry.key;
            final color = entry.value;
            return Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDetailedClusters(List<ColorCluster> clusters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Analysis:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...clusters.map((cluster) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cluster.color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              title: Text(
                ColorUtils.toHexString(cluster.color),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorUtils.getContrastingTextColor(cluster.color),
                ),
              ),
              subtitle: Text(
                '${cluster.pixelCount} pixels (${cluster.percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  color: ColorUtils.getContrastingTextColor(cluster.color)
                      .withOpacity(0.8),
                ),
              ),
              tileColor: cluster.color,
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dominant Colors Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image selection buttons
            const Text(
              'Select Sample Image:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _imageAssets.asMap().entries.map((entry) {
                final index = entry.key;
                final asset = entry.value;
                return ElevatedButton(
                  onPressed: _isLoading ? null : () => _extractColors(asset),
                  child: Text('Image ${index + 1}'),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Loading indicator
            if (_isLoading) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Analyzing image...'),
                  ],
                ),
              ),
            ],

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Results
            if (_dominantColors != null) ...[
              _buildColorPalette(_dominantColors!),
              const SizedBox(height: 20),
            ],

            if (_detailedClusters != null) ...[
              _buildDetailedClusters(_detailedClusters!),
            ],

            // Instructions when no image is selected
            if (_dominantColors == null &&
                !_isLoading &&
                _errorMessage == null) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.palette, size: 64, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        'Select an image to extract dominant colors',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
