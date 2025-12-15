import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => CaptionHistory(),
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

  void _goTo(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onOpenCamera: () => _goTo(1)),
      const CameraPage(),
      const HistoryPage(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70),
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
        child: SafeArea(
          top: false,
          child: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Prototype',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 0.4,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.onOpenCamera, super.key});

  final VoidCallback onOpenCamera;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 16),
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
          const Spacer(),
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
          const SizedBox(height: 12),
          Text(
            'No images are uploaded anywhere – this is a local prototype.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 8),
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
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  Future<void>? _initialization;
  XFile? _lastImage;
  String? _lastCaption;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      setState(() {
        _cameraController = controller;
        _initialization = controller.initialize();
      });
      await _initialization;
    } catch (_) {
      // If camera setup fails we simply won’t show a preview.
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureWithCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
    });
    try {
      final image = await _cameraController!.takePicture();
      _onImageSelected(image);
    } catch (_) {
      setState(() {
        _isBusy = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
    });
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _onImageSelected(image);
      } else {
        setState(() {
          _isBusy = false;
        });
      }
    } catch (_) {
      setState(() {
        _isBusy = false;
      });
    }
  }

  void _onImageSelected(XFile image) {
    final placeholderCaption =
        'A stylish placeholder caption describing this scene in a friendly, human way.';

    context.read<CaptionHistory>().addEntry(
          caption: placeholderCaption,
          imagePath: image.path,
        );

    setState(() {
      _lastImage = image;
      _lastCaption = placeholderCaption;
      _isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 20),
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
                if (_lastCaption != null && _lastImage != null)
                  _CaptionCard(
                    imagePath: _lastImage!.path,
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
    if (_cameraController == null) {
      return _CameraUnavailable(
        onPickFromGallery: _isBusy ? null : _pickFromGallery,
      );
    }

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        }
        if (!_cameraController!.value.isInitialized) {
          return _CameraUnavailable(
            onPickFromGallery: _isBusy ? null : _pickFromGallery,
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),
            Positioned(
              top: 14,
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
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: _isBusy ? null : _captureWithCamera,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _isBusy
                            ? Colors.white30
                            : Colors.white.withOpacity(0.9),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isBusy
                                ? [
                                    Colors.white24,
                                    Colors.white12,
                                  ]
                                : const [
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
          ],
        );
      },
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

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<CaptionHistory>().entries;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 90, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'History',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            history.isEmpty
                ? 'Your recent captions will show up here.'
                : 'Tap a card to expand and read the full caption.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: history.isEmpty
                ? const _EmptyHistoryState()
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = history[index];
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
    final history = context.read<CaptionHistory>();
    final created = entry.createdAt;
    final timeLabel =
        '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => history.toggleExpanded(entry.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
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
                        maxLines: entry.isExpanded ? 4 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
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
                Icon(
                  entry.isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white60,
                ),
              ],
            ),
            if (entry.isExpanded) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.02),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Placeholder caption only – plug in your own model or API here.',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.white70,
                                ),
                      ),
            ),
          ],
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
  });

  final String id;
  final String caption;
  final DateTime createdAt;
  final String? imagePath;
  bool isExpanded;
}

class CaptionHistory extends ChangeNotifier {
  final List<CaptionEntry> _entries = [];

  List<CaptionEntry> get entries => List.unmodifiable(_entries);

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
  }

  void toggleExpanded(String id) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _entries[index].isExpanded = !_entries[index].isExpanded;
    notifyListeners();
  }
}


