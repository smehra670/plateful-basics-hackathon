import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/food_facts.dart';
import '../utils/photo_crop.dart';
import '../theme/app_theme.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/pressable.dart';
import '../widgets/skeleton.dart';
import 'pantry_confirm_screen.dart';

class PantryImportScreen extends StatefulWidget {
  const PantryImportScreen({super.key, this.asTab = false});

  final bool asTab;

  @override
  State<PantryImportScreen> createState() => _PantryImportScreenState();
}

class _PantryImportScreenState extends State<PantryImportScreen>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  final _manualCtrl = TextEditingController();
  late final AnimationController _scan;
  CameraController? _camera;
  bool _busy = false;
  bool _several = false;
  bool _flashOn = false;
  bool _shutterDown = false;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initCamera();
  }

  @override
  void dispose() {
    _scan.dispose();
    _manualCtrl.dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final ok = await Permission.camera.request();
      if (!ok.isGranted || !mounted) return;
      final cameras = await availableCameras();
      if (cameras.isEmpty || !mounted) return;
      CameraDescription back = cameras.first;
      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.back) {
          back = camera;
          break;
        }
      }
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _camera = controller);
    } catch (_) {
      // Shutter falls back to the system camera.
    }
  }

  Future<File> _compress(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final target = p.join(
        dir.path,
        'pantry_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality: 55,
        minWidth: 900,
        minHeight: 900,
        format: CompressFormat.jpeg,
      );
      return result != null ? File(result.path) : file;
    } catch (_) {
      return file;
    }
  }

  Future<String> _persist(File file) async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(docs.path, 'pantry_photos'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final dest = File(
      p.join(
        folder.path,
        'item_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    await file.copy(dest.path);
    return dest.path;
  }

  Future<void> _openConfirm(List<PantryDraft> drafts) async {
    if (!mounted || drafts.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PantryConfirmScreen(drafts: drafts)),
    );
  }

  Future<File?> _takePhoto() async {
    final ok = await Permission.camera.request();
    if (!ok.isGranted) {
      setState(() => _error = 'Camera permission is needed.');
      return null;
    }
    final shot = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (shot == null) return null;
    return File(shot.path);
  }

  Future<void> _fromCamera() async {
    setState(() => _error = null);
    try {
      final file = await _takePhoto();
      if (file == null) return;
      await _analyse([file]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not open the camera. Try typing the item instead.');
    }
  }

  Future<void> _fromMultipleInOnePhoto() async {
    setState(() => _error = null);
    try {
      final file = await _takePhoto();
      if (file == null) return;
      await _analyse([file]);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not open the camera. Try typing the item instead.');
    }
  }

  Future<void> _shutter() async {
    if (_busy) return;
    setState(() => _error = null);
    final cam = _camera;
    if (cam != null && cam.value.isInitialized && !cam.value.isTakingPicture) {
      try {
        final shot = await cam.takePicture();
        await _analyse([File(shot.path)]);
        return;
      } catch (_) {
        // Fall back to the system camera picker.
      }
    }
    if (_several) {
      await _fromMultipleInOnePhoto();
    } else {
      await _fromCamera();
    }
  }

  Future<void> _toggleFlash() async {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) return;
    final next = !_flashOn;
    try {
      await cam.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (!mounted) return;
      setState(() => _flashOn = next);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Flash is not available on this camera.');
    }
  }

  Future<void> _fromGallery() async {
    setState(() => _error = null);
    try {
      try {
        await Permission.photos.request();
      } catch (_) {
        await Permission.storage.request();
      }
      final shots = await _picker.pickMultiImage(imageQuality: 85);
      if (shots.isEmpty) return;
      await _analyse(shots.map((x) => File(x.path)).toList());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not open photos. Try typing the item instead.');
    }
  }

  Future<void> _analyse(List<File> files) async {
    setState(() {
      _busy = true;
      _error = null;
      _status = 'Preparing photos…';
    });
    final drafts = <PantryDraft>[];
    final failures = <String>[];
    try {
      final state = context.read<AppState>();
      for (var i = 0; i < files.length; i++) {
        if (!mounted) return;
        setState(() {
          _status = files.length == 1
              ? 'Reading the photo…'
              : 'Reading photo ${i + 1} of ${files.length}…';
        });
        try {
          final compressed = await _compress(files[i]);
          final savedPath = await _persist(compressed);
          final result = await state.analyseImageFile(
            compressed,
            skipHealthCheck: false,
          );
          final pieces = <_DetectedPiece>[];
          for (final item in result.ingredients) {
            final names = _splitDetectedNames(item.name);
            final sharedName = names.length > 1;
            for (final name in names) {
              pieces.add(
                _DetectedPiece(
                  name: name,
                  quantity: item.quantity ?? 1,
                  unit: item.unit.isEmpty ? 'pcs' : item.unit,
                  box: sharedName ? null : item.box,
                  shelfLifeDays: item.shelfLifeDays,
                  storagePlace: item.storagePlace,
                  price: item.estimatedPriceGbp,
                ),
              );
            }
          }
          for (final piece in pieces) {
            String photo = savedPath;
            final box = piece.box;
            if (pieces.length > 1 && box != null && box.usable) {
              final cropped = await cropIngredientPhoto(savedPath, box);
              if (cropped != null) photo = cropped;
            }
            final days = piece.shelfLifeDays ?? FoodFacts.shelfDays(piece.name);
            drafts.add(
              PantryDraft(
                name: piece.name,
                quantity: piece.quantity,
                unit: piece.unit,
                photoPath: photo,
                expiry: DateTime.now().add(Duration(days: days)),
                storagePlace: piece.storagePlace ?? FoodFacts.storage(piece.name),
                estimatedPriceGbp:
                    piece.price ?? FoodFacts.pricePerUnit(piece.name, piece.unit),
              ),
            );
          }
        } catch (e) {
          failures.add(
            e
                .toString()
                .replaceFirst('Exception: ', '')
                .replaceFirst('Bad state: ', '')
                .replaceFirst('HttpException: ', ''),
          );
        }
      }
      if (!mounted) return;
      setState(() => _busy = false);
      if (drafts.isEmpty) {
        setState(() {
          _error = failures.isNotEmpty
              ? failures.first
              : 'Nothing was recognised. Try a clearer photo or type the item.';
        });
        return;
      }
      await _openConfirm(drafts);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _busy = false;
      });
    }
  }

  List<String> _splitDetectedNames(String raw) {
    final name = raw.trim();
    const keep = [
      'macaroni and cheese',
      'fish and chips',
      'salt and pepper',
      'bangers and mash',
      'peanut butter',
      'sweet and sour',
    ];
    final lower = name.toLowerCase();
    if (keep.any(lower.contains) ||
        !RegExp(r'\s+(and|&)\s+', caseSensitive: false).hasMatch(name)) {
      return [name];
    }
    final parts = name
        .split(RegExp(r'\s+(?:and|&)\s+', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.length > 1)
        .toList();
    return parts.length < 2 ? [name] : parts;
  }

  Future<void> _addManual() async {
    final name = _manualCtrl.text.trim();
    if (name.isEmpty) return;
    _manualCtrl.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $name')),
    );
    await _openConfirm([
      PantryDraft(name: name, quantity: 1, unit: 'pcs'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = widget.asTab ? kFloatingNavClearance : 24.0;
    final body = _busy
        ? _progress()
        : ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
            children: [
              if (!widget.asTab)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CircleIconButton(
                    icon: PhosphorIconsRegular.arrowLeft,
                    semanticLabel: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              Text('Add to pantry', style: AppText.h1()),
              const SizedBox(height: 8),
              Text(
                'Snap one item, or a whole shelf at once.',
                style: AppText.body(),
              ),
              const SizedBox(height: 20),
              _modeControl(),
              const SizedBox(height: 20),
              _cameraCard(),
              const SizedBox(height: 20),
              _shutterRow(),
              const SizedBox(height: 20),
              _typeBar(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: AppText.body(color: AppColors.roseText)),
              ],
            ],
          );

    if (widget.asTab) {
      return SafeArea(bottom: false, child: body);
    }

    return Scaffold(
      backgroundColor: AppColors.ground,
      body: SafeArea(child: body),
    );
  }

  Widget _modeControl() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.modeTrack,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: _several ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppShadows.chip,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _modeLabel('One item', selected: !_several, onTap: () {
                  setState(() => _several = false);
                }),
              ),
              Expanded(
                child: _modeLabel(
                  'Several at once',
                  selected: _several,
                  onTap: () => setState(() => _several = true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeLabel(
    String text, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: text,
      child: Center(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(
            fontSize: 14,
            color: selected ? AppColors.forest : AppColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _cameraPreview() {
    final preview = _camera!.value.previewSize;
    final width = preview?.height ?? 210;
    final height = preview?.width ?? 190;
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: width,
        height: height,
        child: CameraPreview(_camera!),
      ),
    );
  }

  Widget _cameraCard() {
    final ready = _camera != null && _camera!.value.isInitialized;
    return Container(
      height: 330,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          SizedBox(
            width: 210,
            height: 190,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.lgLg),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (ready) _cameraPreview()
                  else
                    ColoredBox(
                      color: AppColors.cameraPlaceholder,
                      child: Icon(
                        PhosphorIconsRegular.carrot,
                        color: AppColors.sageBorder.withValues(alpha: 0.55),
                        size: 48,
                      ),
                    ),
                  const CustomPaint(painter: _CornerBracketsPainter()),
                  if (ready)
                    AnimatedBuilder(
                      animation: _scan,
                      builder: (context, _) {
                        return Align(
                          alignment: Alignment(0, -1 + (2 * _scan.value)),
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: AppColors.forest.withValues(alpha: 0.45),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            _several
                ? 'Fit them all in — each gets added'
                : 'Frame one food — then set its expiry',
            textAlign: TextAlign.center,
            style: AppText.label(color: AppColors.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _shutterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _sideButton(
            icon: PhosphorIconsRegular.image,
            label: 'Choose from gallery',
            onTap: _fromGallery,
          ),
          _shutterButton(),
          _sideButton(
            icon: _flashOn
                ? PhosphorIconsFill.lightning
                : PhosphorIconsRegular.lightning,
            label: 'Flash',
            onTap: _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _sideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Pressable(
      semanticLabel: label,
      onTap: onTap,
      child: Tooltip(
        message: label,
        child: Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppShadows.chip,
          ),
          child: Icon(icon, color: AppColors.ink, size: 22),
        ),
      ),
    );
  }

  Widget _shutterButton() {
    return Semantics(
      button: true,
      label: 'Take photo',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _shutterDown = true),
        onTapUp: (_) => setState(() => _shutterDown = false),
        onTapCancel: () => setState(() => _shutterDown = false),
        onTap: _shutter,
        child: Container(
          width: 80,
          height: 80,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: AppShadows.primaryGlow,
          ),
          child: AnimatedScale(
            scale: _shutterDown ? 0.9 : 1,
            duration: const Duration(milliseconds: 90),
            child: Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: AppColors.forest,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.chip,
      ),
      child: Row(
        children: [
          const Icon(PhosphorIconsRegular.pencilSimple, color: AppColors.muted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _manualCtrl,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.itemTitle(fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Or type it — e.g. Bananas',
                hintStyle: AppText.body(fontSize: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _addManual(),
            ),
          ),
          Pressable(
            semanticLabel: 'Add ingredient',
            onTap: _addManual,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.sageSoft,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                PhosphorIconsRegular.plus,
                color: AppColors.forest,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progress() {
    return Column(
      children: [
        const Expanded(child: RecipeLoadingView(kind: LoadKind.pantry)),
        Text(
          _status ?? 'Working…',
          style: AppText.body(),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: widget.asTab ? kFloatingNavClearance : 24),
      ],
    );
  }
}

class _CornerBracketsPainter extends CustomPainter {
  const _CornerBracketsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.forest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const length = 22.0;
    const radius = 14.0;
    final corners = <Path>[
      Path()
        ..moveTo(radius, 0)
        ..lineTo(length, 0)
        ..moveTo(0, radius)
        ..lineTo(0, length)
        ..moveTo(0, radius)
        ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius)),
      Path()
        ..moveTo(size.width - length, 0)
        ..lineTo(size.width - radius, 0)
        ..arcToPoint(
          Offset(size.width, radius),
          radius: const Radius.circular(radius),
        )
        ..lineTo(size.width, length),
      Path()
        ..moveTo(0, size.height - length)
        ..lineTo(0, size.height - radius)
        ..arcToPoint(
          Offset(radius, size.height),
          radius: const Radius.circular(radius),
          clockwise: false,
        )
        ..lineTo(length, size.height),
      Path()
        ..moveTo(size.width, size.height - length)
        ..lineTo(size.width, size.height - radius)
        ..arcToPoint(
          Offset(size.width - radius, size.height),
          radius: const Radius.circular(radius),
        )
        ..lineTo(size.width - length, size.height),
    ];
    for (final path in corners) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DetectedPiece {
  const _DetectedPiece({
    required this.name,
    required this.quantity,
    required this.unit,
    this.box,
    this.shelfLifeDays,
    this.storagePlace,
    this.price,
  });

  final String name;
  final double quantity;
  final String unit;
  final IngredientBox? box;
  final int? shelfLifeDays;
  final String? storagePlace;
  final double? price;
}

class PantryDraft {
  PantryDraft({
    required this.name,
    required this.quantity,
    required this.unit,
    this.expiry,
    this.storagePlace,
    this.photoPath,
    this.estimatedPriceGbp,
  });

  String name;
  double quantity;
  String unit;
  DateTime? expiry;
  String? storagePlace;
  String? photoPath;
  double? estimatedPriceGbp;
}
