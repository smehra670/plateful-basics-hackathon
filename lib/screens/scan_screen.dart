import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'clarification_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _picker = ImagePicker();
  File? _preview;
  bool _busy = false;
  String? _error;

  Future<bool> _ensureCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<File?> _compress(File file) async {
    final dir = await getTemporaryDirectory();
    final target = p.join(
      dir.path,
      'plateful_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      target,
      quality: 72,
      minWidth: 1280,
      minHeight: 1280,
    );
    return result != null ? File(result.path) : file;
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      if (source == ImageSource.camera) {
        final ok = await _ensureCameraPermission();
        if (!ok) {
          setState(() => _error = 'Camera permission is needed to scan.');
          return;
        }
      }
      final shot = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (shot == null) return;
      final compressed = await _compress(File(shot.path));
      setState(() => _preview = compressed);
      if (!mounted) return;
      context.read<AppState>().setPendingImage(compressed);
    } catch (e) {
      setState(() => _error = 'Could not open image. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _analyse() async {
    if (_preview == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    final state = context.read<AppState>();
    try {
      final result = await state.analysePendingImage();
      if (!mounted) return;
      if (result.questions.isEmpty) {
        await state.finalizeScanAndGenerate();
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ClarificationScreen()),
        );
      }
    } catch (_) {
      setState(() => _error = 'Analysis failed. Check your connection or use demo mode.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan', style: AppText.display(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              'Photograph all your ingredients in one shot.',
              style: AppText.body(),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _preview == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: AppColors.sageMuted,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.green,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'What\'s in your kitchen?',
                            style: AppText.title(fontSize: 20),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Lay everything on the counter and take one photo.',
                              textAlign: TextAlign.center,
                              style: AppText.body(),
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(_preview!, fit: BoxFit.cover),
                          if (_busy)
                            Container(
                              color: Colors.black38,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: AppText.body(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            if (_preview == null) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take photo'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.green,
                        side: const BorderSide(color: AppColors.green),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              setState(() => _preview = null);
                              context.read<AppState>().setPendingImage(null);
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _busy ? null : _analyse,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _busy ? 'Analysing…' : 'Use this photo',
                        style: AppText.button(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
