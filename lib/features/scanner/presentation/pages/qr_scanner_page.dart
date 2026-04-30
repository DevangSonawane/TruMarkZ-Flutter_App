import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key, this.onScanned});

  final ValueChanged<String>? onScanned;

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  late final MobileScannerController _controller;
  String? _lastValue;
  bool _isShowingSheet = false;
  bool _torchOn = false;
  bool _frontCamera = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showResultSheet(String value) async {
    if (_isShowingSheet) return;
    _isShowingSheet = true;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.x4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Scan result', style: AppTypography.heading1),
              const SizedBox(height: AppSpacing.x2),
              SelectableText(value, style: AppTypography.body2),
              const SizedBox(height: AppSpacing.x4),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Rescan'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        final ValueChanged<String>? cb = widget.onScanned;
                        if (cb != null) {
                          cb(value);
                          return;
                        }
                        if (!mounted) return;
                        context.go(AppRouter.publicVerificationResultPath);
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    _isShowingSheet = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: ColoredBox(color: Colors.black)),
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) async {
              final Barcode? barcode = capture.barcodes.isNotEmpty
                  ? capture.barcodes.first
                  : null;
              final String? rawValue = barcode?.rawValue;
              if (rawValue == null || rawValue.isEmpty) return;
              if (rawValue == _lastValue) return;

              _lastValue = rawValue;
              HapticFeedback.mediumImpact();
              SystemSound.play(SystemSoundType.click);
              await _showResultSheet(rawValue);
            },
          ),
          _ScannerOverlay(
            message: 'Align identity QR code within the frame',
            windowSize: 280,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x4),
              child: Row(
                children: <Widget>[
                  _OverlayIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  _OverlayIconButton(
                    icon: _frontCamera
                        ? Icons.camera_front_rounded
                        : Icons.camera_rear_rounded,
                    onPressed: () async {
                      await _controller.switchCamera();
                      setState(() => _frontCamera = !_frontCamera);
                    },
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  _OverlayIconButton(
                    icon: _torchOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    onPressed: () async {
                      await _controller.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatefulWidget {
  const _ScannerOverlay({required this.message, required this.windowSize});

  final String message;
  final double windowSize;

  @override
  State<_ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<_ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double borderRadius = 16;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double left = (constraints.maxWidth - widget.windowSize) / 2;
          final double top = (constraints.maxHeight - widget.windowSize) / 2;

          return Stack(
            children: <Widget>[
              CustomPaint(
                size: Size.infinite,
                painter: _OverlayDimPainter(
                  windowSize: widget.windowSize,
                  borderRadius: borderRadius,
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: SizedBox(
                    width: widget.windowSize,
                    height: widget.windowSize,
                    child: Stack(
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                            border: Border.all(
                              color: Colors.white.withAlpha(51),
                            ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _scanController,
                          builder: (BuildContext context, _) {
                            final double y =
                                (_scanController.value * widget.windowSize)
                                    .clamp(0, widget.windowSize);
                            return Positioned(
                              left: 10,
                              right: 10,
                              top: y,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      Colors.transparent,
                                      AppColors.brandBlue.withAlpha(220),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: AppColors.brandBlue.withAlpha(80),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: _CornerAccents(
                            size: widget.windowSize,
                            radius: borderRadius,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: AppSpacing.x10,
                child:
                    Text(
                          widget.message,
                          textAlign: TextAlign.center,
                          style: AppTypography.body2.copyWith(
                            color: Colors.white,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 250.ms)
                        .slideY(begin: 0.08, end: 0, duration: 250.ms),
              ),
              Positioned(left: left, top: top, child: const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }
}

class _CornerAccents extends StatelessWidget {
  const _CornerAccents({required this.size, required this.radius});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    const double stroke = 4;
    const double length = 26;

    Widget corner({required Alignment alignment, required double rotation}) {
      return Align(
        alignment: alignment,
        child: Transform.rotate(
          angle: rotation,
          child: SizedBox(
            width: length,
            height: length,
            child: CustomPaint(painter: _CornerPainter(strokeWidth: stroke)),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: <Widget>[
            corner(alignment: Alignment.topLeft, rotation: 0),
            corner(alignment: Alignment.topRight, rotation: 1.57079632679),
            corner(alignment: Alignment.bottomRight, rotation: 3.14159265359),
            corner(alignment: Alignment.bottomLeft, rotation: -1.57079632679),
          ],
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.strokeWidth});

  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppColors.brandBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final Path path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.strokeWidth != strokeWidth;
}

class _OverlayDimPainter extends CustomPainter {
  const _OverlayDimPainter({
    required this.windowSize,
    required this.borderRadius,
  });

  final double windowSize;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dimPaint = Paint()..color = AppColors.darkNavy.withAlpha(179);

    final Rect screen = Offset.zero & size;
    final Rect holeRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: windowSize,
      height: windowSize,
    );
    final RRect hole = RRect.fromRectAndRadius(
      holeRect,
      Radius.circular(borderRadius),
    );

    final Path overlayPath = Path()
      ..addRect(screen)
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, dimPaint);
  }

  @override
  bool shouldRepaint(covariant _OverlayDimPainter oldDelegate) =>
      oldDelegate.windowSize != windowSize ||
      oldDelegate.borderRadius != borderRadius;
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(110),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
