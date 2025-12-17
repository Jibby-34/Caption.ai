import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final history = CaptionHistory();
  await history.loadHistory();
  runApp(
    ChangeNotifierProvider(
      create: (_) => history,
      child: const CaptionAiApp(),
    ),
  );
}

class CaptionAiApp extends StatelessWidget {
  const CaptionAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme,
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Caption.ai',
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFF050816),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF050816),
          selectedItemColor: Color(0xFF9F7BFF),
          unselectedItemColor: Colors.white70,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF0B1020),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          elevation: 0,
        ),
      ),
      home: const CaptionAiRoot(),
    );
  }
}

class CaptionAiRoot extends StatefulWidget {
  const CaptionAiRoot({super.key});

  @override
  State<CaptionAiRoot> createState() => _CaptionAiRootState();
}

class _CaptionAiRootState extends State<CaptionAiRoot> {
  int _currentIndex = 0;
  VoidCallback? _scrollHistoryToTop;

  void _goTo(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Scroll to top when navigating to history page
    if (index == 2 && _scrollHistoryToTop != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollHistoryToTop?.call();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCameraPage = _currentIndex == 1;

    final pages = [
      HomePage(
        onOpenCamera: () => _goTo(1),
        onOpenHistory: () => _goTo(2),
      ),
      const CameraPage(fullscreen: true),
      HistoryPage(
        onScrollToTopCallback: (callback) {
          _scrollHistoryToTop = callback;
        },
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isCameraPage
          ? null
          : const PreferredSize(
              preferredSize: Size.fromHeight(48), // Even tighter, almost exactly logo height
              child: CaptionAppBar(),
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          ),
        ),
        child: Builder(
          builder: (context) {
            final topInset = isCameraPage
                ? 0.0
                : kToolbarHeight + MediaQuery.of(context).padding.top;
            return SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(top: topInset),
                child: IndexedStack(
                  index: _currentIndex,
                  children: pages,
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xBF020617),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _goTo,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt_outlined),
                activeIcon: Icon(Icons.camera_alt_rounded),
                label: 'Camera',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_toggle_off),
                activeIcon: Icon(Icons.history_rounded),
                label: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CaptionAppBar extends StatelessWidget {
  const CaptionAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20), // FLUSH, no deadspace
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xCC020617),
            Color(0x00020617),
          ],
        ),
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF4ADE80),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'C',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Caption.ai',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Turn images into words.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.onOpenCamera,
    required this.onOpenHistory,
    super.key,
  });

  final VoidCallback onOpenCamera;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<CaptionHistory>().entries;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Instant captions\nfor every moment.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Capture a photo or pick from your gallery and let Caption.ai craft a smart, shareable description in seconds.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFF22D3EE),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.35),
                        blurRadius: 32,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 18,
                        left: 18,
                        right: 18,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.black.withOpacity(0.2),
                              ),
                              child: Text(
                                'AI captioning',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      letterSpacing: 0.4,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Point. Capture. Caption.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Designed for speed and clarity,\nperfect for sharing.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _FeatureChip(
                icon: Icons.bolt_rounded,
                label: 'Fast captions',
              ),
              _FeatureChip(
                icon: Icons.image_outlined,
                label: 'Camera & gallery',
              ),
              _FeatureChip(
                icon: Icons.history_rounded,
                label: 'Caption history',
              ),
              _FeatureChip(
                icon: Icons.hub_outlined,
                label: 'Clean, modern UI',
              ),
            ],
          ),
          const SizedBox(height: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: onOpenCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Open camera'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onOpenHistory,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.25),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.03),
                ),
                icon: const Icon(Icons.history_rounded),
                label: const Text('View history'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Images are sent to a captioning service to generate descriptions.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Recent captions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onOpenHistory,
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: history
                  .take(3)
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryEntryTile(entry: entry),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({this.fullscreen = false, super.key});

  final bool fullscreen;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  String _selectedMood = 'Funny';
  Uint8List? _pickedImageBytes;
  String? _lastCaption;
  String? _lastImagePath;
  bool _isBusy = false;
  int _fireAnimationTrigger = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (kIsWeb) return; // Camera preview not supported on web
    
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _isCameraPermissionGranted = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        setState(() {
          _isCameraPermissionGranted = false;
        });
      }
    }
  }

  Future<void> _captureWithCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_isBusy) return;
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      await _onImageSelected(bytes, image.path);
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isBusy) return;
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        await _onImageSelected(bytes, image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _onImageSelected(Uint8List imageBytes, String imagePath) async {
    setState(() {
      _pickedImageBytes = imageBytes;
      _lastImagePath = imagePath;
      _lastCaption = null;
      _isBusy = true;
    });

    try {

      final url = Uri.parse(
        'https://caption-ai-proxy.image-proxy-gateway.workers.dev/',
      );
      final headers = {'Content-Type': 'application/json'};
      final base64Image = base64Encode(imageBytes);
      final body = jsonEncode({
        'imageBase64': base64Image,
      });

      final response =
          await http.post(url, headers: headers, body: body).timeout(
                const Duration(seconds: 30),
              );

      String caption;
      if (response.statusCode == 200) {
        caption = _extractCaptionFromGeminiResponse(response.body).trim();
        if (caption.isEmpty) {
          caption =
              'The caption service returned an empty response for this image.';
        }
      } else {
        caption =
            'Unable to generate a caption (status code ${response.statusCode}).';
      }

      context.read<CaptionHistory>().addEntry(
            caption: caption,
            imagePath: imagePath,
          );

      setState(() {
        _lastCaption = caption;
      });
    } catch (_) {
      const fallbackCaption =
          'Something went wrong while generating a caption for this image.';

      context.read<CaptionHistory>().addEntry(
            caption: fallbackCaption,
            imagePath: imagePath,
          );

      setState(() {
        _lastCaption = fallbackCaption;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _resetImage() {
    setState(() {
      _pickedImageBytes = null;
      _lastImagePath = null;
      _lastCaption = null;
    });
  }

  void _showChaosModeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF4500).withOpacity(0.95),
                  const Color(0xFFFF6B00).withOpacity(0.9),
                  const Color(0xFF0B1120).withOpacity(0.98),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: const Color(0xFFFF4500).withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4500).withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 280,
              maxWidth: 400,
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '🔥',
                            style: TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Chaos Mode - Enabled',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '🔥',
                            style: TextStyle(fontSize: 32),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'You have enabled chaos mode! Prepare for chaos!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFFFF4500),
                            Color(0xFFFF6B00),
                          ],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 12,
                            ),
                            child: Text(
                              'Let\'s Go! 🔥',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  left: 12,
                  child: Text(
                    '*Not suitable for younger audiences*',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.25),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _extractCaptionFromGeminiResponse(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        // Standard Gemini-style: candidates[0].content.parts[0].text
        final candidates = decoded['candidates'];
        if (candidates is List && candidates.isNotEmpty) {
          final first = candidates.first;
          if (first is Map<String, dynamic>) {
            final content = first['content'];
            if (content is Map<String, dynamic>) {
              final parts = content['parts'];
              if (parts is List && parts.isNotEmpty) {
                final firstPart = parts.first;
                if (firstPart is Map<String, dynamic>) {
                  final text = firstPart['text'];
                  if (text is String && text.trim().isNotEmpty) {
                    return text;
                  }
                }
              }
            }

            // Some variations may expose text directly on the candidate
            final candidateText = first['text'];
            if (candidateText is String && candidateText.trim().isNotEmpty) {
              return candidateText;
            }
          }
        }

        // Some APIs wrap text at the top level
        final topLevelText = decoded['text'];
        if (topLevelText is String && topLevelText.trim().isNotEmpty) {
          return topLevelText;
        }
      }
    } catch (_) {
      // Fall back to raw body if JSON parsing or shape inspection fails.
    }

    return body;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fullscreen) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(32)),
                  child: _buildCameraPreview(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Camera',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: Colors.white.withOpacity(0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: _isBusy ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_outlined, size: 18),
                label: const Text('Gallery'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF020617),
                          Color(0xFF020617),
                        ],
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: _buildCameraPreview(context),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (_lastCaption != null && _lastImagePath != null)
                  _CaptionCard(
                    imagePath: _lastImagePath!,
                    caption: _lastCaption!,
                  )
                else
                  _EmptyCaptionHint(isBusy: _isBusy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? theme.colorScheme.surfaceVariant : Colors.black;

    final moodOptions = <String, Color>{
      'Funny': Colors.amber,
      'Sarcastic': Colors.purple,
      'Savage': const Color(0xFFDC143C), // Crimson
      'Unhinged': const Color(0xFFFF69B4), // Hot Pink
      'Wholesome': const Color(0xFFFFF9C4), // Soft Yellow
      'Chaos Mode 🔥': const Color(0xFFFF4500), // Orange Red
    };

    // If we have a captured image, show it instead of the camera preview
    Widget? backgroundWidget;
    if (_pickedImageBytes != null) {
      final previewSize = _cameraController?.value.previewSize;
      if (_cameraController != null && _cameraController!.value.isInitialized && previewSize != null) {
        // The plugin reports landscape sizes, swap to portrait dims.
        final double previewWidth = previewSize.height;
        final double previewHeight = previewSize.width;

        backgroundWidget = ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Container(
            color: Colors.black,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewWidth,
                height: previewHeight,
                child: Image.memory(
                  _pickedImageBytes!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      } else {
        // Fallback: contain the image if we can't determine preview size.
        backgroundWidget = ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Container(
            color: bg,
            child: Image.memory(
              _pickedImageBytes!,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        );
      }
    }

    // Web fallback
    if (kIsWeb) {
      return Container(
        color: bg,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Camera preview not available on web',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.tertiary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _isBusy ? null : _pickFromGallery,
                    icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
                    label: const Text(
                      'Upload Image',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Permission/state handling
    if (!_isCameraPermissionGranted) {
      return Container(
        color: bg,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Camera permission required',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: bg,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  'Initializing camera...',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If we have an image, use it as background; otherwise use camera preview
    if (backgroundWidget == null) {
      // Full-screen, cover-scaling camera preview that fills available space
      final previewSize = _cameraController!.value.previewSize;

      if (previewSize == null) {
        return Container(color: bg);
      }

      // The plugin reports landscape size; swap to match portrait if needed
      final double cameraPreviewWidth = previewSize.height;
      final double cameraPreviewHeight = previewSize.width;

      backgroundWidget = ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Container(
          color: Colors.black,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: cameraPreviewWidth,
              height: cameraPreviewHeight,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      );
    }

    final isChaosMode = _selectedMood.contains('Chaos Mode');
    
    return Stack(
      children: [
        Positioned.fill(
          child: backgroundWidget!,
        ),
        // Fire overlay effect when Chaos Mode is active
        if (isChaosMode)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFF4500).withOpacity(0.05),
                    Colors.transparent,
                    const Color(0xFFFF4500).withOpacity(0.08),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        // Animated fire indicator when Chaos Mode is active
        if (isChaosMode)
          Positioned.fill(
            key: const ValueKey('chaos_fire_indicator'),
            child: _ChaosModeFireIndicator(
              trigger: _fireAnimationTrigger,
            ),
          ),
            Positioned(
              top: 24,
              left: 14,
              child: _MoodDropdown(
                value: _selectedMood,
                options: moodOptions,
                onChanged: (value) {
                  if (value == null) return;
                  final wasChaosMode = _selectedMood.contains('Chaos Mode');
                  final isChaosMode = value.contains('Chaos Mode');
                  
                  setState(() {
                    _selectedMood = value;
                  });
                  
                  // Trigger fire animation and show dialog when switching TO Chaos Mode
                  // Use post-frame callback to ensure widget is built first
                  if (!wasChaosMode && isChaosMode) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _fireAnimationTrigger++;
                        });
                        _showChaosModeDialog(context);
                      }
                    });
                  }
                },
              ),
            ),
            if (_isBusy)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF9F7BFF),
                          ),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Processing...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 28,
              right: 14,
              child: Material(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(999),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _isBusy ? null : _pickFromGallery,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: Colors.white.withOpacity(0.95),
                    ),
                  ),
                ),
              ),
            ),
            if (!_isBusy && _lastCaption == null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: GestureDetector(
                    onTap: _captureWithCamera,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isChaosMode
                              ? const Color(0xFFFF4500).withOpacity(0.9)
                              : Colors.white.withOpacity(0.9),
                          width: 4,
                        ),
                        boxShadow: isChaosMode
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF4500).withOpacity(0.5),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isChaosMode
                                ? const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF4500),
                                      Color(0xFFFF6B00),
                                      Color(0xFFFF8C00),
                                    ],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF7C3AED),
                                      Color(0xFF22D3EE),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_lastCaption != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 40),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: isChaosMode
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFFF4500).withOpacity(0.15),
                                const Color(0xFFFF6B00).withOpacity(0.1),
                                const Color(0xFF0B1120),
                              ],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0B1120),
                                Color(0xFF020617),
                              ],
                            ),
                      border: Border.all(
                        color: isChaosMode
                            ? const Color(0xFFFF4500).withOpacity(0.4)
                            : Colors.white.withOpacity(0.18),
                        width: isChaosMode ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isChaosMode
                              ? const Color(0xFFFF4500).withOpacity(0.3)
                              : Colors.black.withOpacity(0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: isChaosMode
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF4500),
                                          Color(0xFFFF6B00),
                                        ],
                                      )
                                    : const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF38BDF8),
                                          Color(0xFF9F7BFF),
                                        ],
                                      ),
                              ),
                              child: Icon(
                                isChaosMode ? Icons.local_fire_department_rounded : Icons.camera_alt_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: Text(
                                  _lastCaption ?? '',
                                  style: GoogleFonts.quicksand(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 17,
                                    height: 1.5,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(999),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: _resetImage,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: isChaosMode
                                ? const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFFFF4500),
                                      Color(0xFFFF6B00),
                                      Color(0xFFFF8C00),
                                    ],
                                  )
                                : const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF9F7BFF),
                                      Color(0xFF38BDF8),
                                    ],
                                  ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // Share button does nothing
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isChaosMode
                                          ? Icons.local_fire_department_rounded
                                          : Icons.share_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isChaosMode ? 'Share 🔥' : 'Share',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}

class _MoodDropdown extends StatelessWidget {
  const _MoodDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final Map<String, Color> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isChaosMode = value.contains('Chaos Mode');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: isChaosMode
            ? const Color(0xFFFF4500).withOpacity(0.2)
            : Colors.black.withOpacity(0.45),
        border: Border.all(
          color: isChaosMode
              ? const Color(0xFFFF4500).withOpacity(0.6)
              : Colors.white.withOpacity(0.16),
          width: isChaosMode ? 1.5 : 1,
        ),
        boxShadow: isChaosMode
            ? [
                BoxShadow(
                  color: const Color(0xFFFF4500).withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          dropdownColor: const Color(0xFF0B1020),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: isChaosMode ? FontWeight.w600 : FontWeight.normal,
              ),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: isChaosMode
                ? const Color(0xFFFF4500)
                : Colors.white70,
          ),
          items: options.entries
              .map(
                (entry) {
                  final isChaosItem = entry.key.contains('Chaos Mode');
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      children: [
                        if (isChaosItem)
                          const Text('🔥', style: TextStyle(fontSize: 16))
                        else
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: entry.value,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontWeight: isChaosItem
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ChaosModeFireIndicator extends StatefulWidget {
  const _ChaosModeFireIndicator({required this.trigger});

  final int trigger;

  @override
  State<_ChaosModeFireIndicator> createState() => _ChaosModeFireIndicatorState();
}

class _ChaosModeFireIndicatorState extends State<_ChaosModeFireIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _verticalAnimations;
  late List<Animation<double>> _horizontalAnimations;
  late List<Animation<double>> _opacityAnimations;
  final int _fireCount = 8;
  int _lastTrigger = -1;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _fireCount,
      (index) => AnimationController(
        duration: Duration(milliseconds: 2000 + (index * 300)),
        vsync: this,
      ),
    );

    _verticalAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: -0.2).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
    }).toList();

    _horizontalAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 0.2,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 1.0),
          weight: 0.5,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 0.3,
        ),
      ]).animate(controller);
    }).toList();
    
    // Start animation if trigger is already set (when widget is first created with trigger > 0)
    _lastTrigger = widget.trigger;
    if (widget.trigger > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          for (var controller in _controllers) {
            controller.forward();
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(_ChaosModeFireIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animation when trigger value increases (not just changes)
    if (widget.trigger > _lastTrigger) {
      _lastTrigger = widget.trigger;
      // Reset and start all animations once
      for (var controller in _controllers) {
        controller.reset();
        controller.forward();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: List.generate(_fireCount, (index) {
          final random = (index * 0.618033988749) % 1.0; // Golden ratio for distribution
          final startX = random;
          
          return AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              final screenSize = MediaQuery.of(context).size;
              final verticalPos = _verticalAnimations[index].value;
              final horizontalPos = startX + 
                  (_horizontalAnimations[index].value - 0.5) * 0.3;
              final opacity = _opacityAnimations[index].value;
              
              return Positioned(
                left: screenSize.width * horizontalPos,
                top: screenSize.height * verticalPos,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: 0.8 + (opacity * 0.4),
                    child: Text(
                      '🔥',
                      style: TextStyle(
                        fontSize: 24 + (opacity * 8),
                        shadows: [
                          Shadow(
                            color: const Color(0xFFFF4500).withOpacity(opacity * 0.8),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({this.onPickFromGallery});

  final VoidCallback? onPickFromGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_rounded,
            size: 48,
            color: Colors.white54,
          ),
          const SizedBox(height: 12),
          Text(
            'Camera preview unavailable',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'You can still select an image from your gallery to generate a caption.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          if (onPickFromGallery != null)
            OutlinedButton.icon(
              onPressed: onPickFromGallery,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Choose from gallery'),
            ),
        ],
      ),
    );
  }
}

class _EmptyCaptionHint extends StatelessWidget {
  const _EmptyCaptionHint({required this.isBusy});

  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.02),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withOpacity(0.05),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isBusy
                  ? 'Working on your image...'
                  : 'Take a photo or pick one from your gallery to see a sample caption.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptionCard extends StatelessWidget {
  const _CaptionCard({
    required this.imagePath,
    required this.caption,
  });

  final String imagePath;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.02),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              File(imagePath),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample caption',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white60,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({this.onScrollToTopCallback, super.key});

  final void Function(VoidCallback)? onScrollToTopCallback;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ScrollController _scrollController = ScrollController();
  String _filterOption = 'All';

  @override
  void initState() {
    super.initState();
    // Register scroll callback with parent
    widget.onScrollToTopCallback?.call(scrollToTop);
    // Scroll to top when the page is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToTop();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<CaptionHistory>();
    final allEntries = history.entries;
    final favoritedEntries = history.favoritedEntries;
    final displayedEntries = _filterOption == 'Favorited' ? favoritedEntries : allEntries;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'History',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                margin: const EdgeInsets.only(right: 2),
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterOption,
                    isDense: true,
                    dropdownColor: const Color(0xFF0B1020),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Colors.white70,
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'All',
                        child: Text('All'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Favorited',
                        child: Text('Favorited'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _filterOption = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            displayedEntries.isEmpty
                ? _filterOption == 'Favorited'
                    ? 'No favorited captions yet.'
                    : 'Your recent captions will show up here.'
                : 'Tap a card to expand and read the full caption.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: displayedEntries.isEmpty
                ? const _EmptyHistoryState()
                : ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.zero, // Start list flush to the top
                    itemCount: displayedEntries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = displayedEntries[index];
                      return _HistoryEntryTile(entry: entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withOpacity(0.03),
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              size: 40,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No captions yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Take a photo or pick one from your gallery to start building your history.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({required this.entry});

  final CaptionEntry entry;

  @override
  Widget build(BuildContext context) {
    final history = context.watch<CaptionHistory>();
    final created = entry.createdAt;
    final timeLabel =
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => history.toggleExpanded(entry.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 80),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.02),
          border: Border.all(
            color: entry.isExpanded
                ? const Color(0xFF7C3AED).withOpacity(0.6)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.imagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(entry.imagePath!),
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withOpacity(0.04),
                    ),
                    child: const Icon(
                      Icons.text_fields_rounded,
                      color: Colors.white70,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.caption,
                        maxLines: entry.isExpanded ? null : 2,
                        overflow: entry.isExpanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: (entry.isExpanded
                                ? Theme.of(context).textTheme.titleMedium
                                : Theme.of(context).textTheme.bodyMedium)
                            ?.copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.white54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.white60,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          history.deleteEntry(entry.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          history.toggleFavorite(entry.id);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            entry.isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 20,
                            color: entry.isFavorited
                                ? Colors.red
                                : Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (entry.isExpanded) ...[
              const SizedBox(height: 12),
              if (entry.imagePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(entry.imagePath!),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF9F7BFF),
                      Color(0xFF38BDF8),
                    ],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Share button - no implementation
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.share_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Share',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class CaptionEntry {
  CaptionEntry({
    required this.id,
    required this.caption,
    required this.createdAt,
    this.imagePath,
    this.isExpanded = false,
    this.isFavorited = false,
  });

  final String id;
  final String caption;
  final DateTime createdAt;
  final String? imagePath;
  bool isExpanded;
  bool isFavorited;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'createdAt': createdAt.toIso8601String(),
      'imagePath': imagePath,
      'isExpanded': isExpanded,
      'isFavorited': isFavorited,
    };
  }

  factory CaptionEntry.fromJson(Map<String, dynamic> json) {
    return CaptionEntry(
      id: json['id'] as String,
      caption: json['caption'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      imagePath: json['imagePath'] as String?,
      isExpanded: json['isExpanded'] as bool? ?? false,
      isFavorited: json['isFavorited'] as bool? ?? false,
    );
  }
}

class CaptionHistory extends ChangeNotifier {
  final List<CaptionEntry> _entries = [];
  static const String _historyKey = 'caption_history';

  List<CaptionEntry> get entries => List.unmodifiable(_entries);

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _entries.clear();
        _entries.addAll(
          decoded.map((e) => CaptionEntry.fromJson(e as Map<String, dynamic>)),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(
        _entries.map((e) => e.toJson()).toList(),
      );
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  void addEntry({
    required String caption,
    String? imagePath,
  }) {
    final now = DateTime.now();
    final entry = CaptionEntry(
      id: '${now.millisecondsSinceEpoch}_${_entries.length}',
      caption: caption,
      createdAt: now,
      imagePath: imagePath,
    );
    _entries.insert(0, entry);
    notifyListeners();
    _saveHistory();
  }

  void toggleExpanded(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _entries[index].isExpanded = !_entries[index].isExpanded;
    notifyListeners();
    _saveHistory();
  }

  void toggleFavorite(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _entries[index].isFavorited = !_entries[index].isFavorited;
    notifyListeners();
    _saveHistory();
  }

  void deleteEntry(String id) {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    _saveHistory();
  }

  List<CaptionEntry> get favoritedEntries {
    return _entries.where((e) => e.isFavorited).toList();
  }
}


