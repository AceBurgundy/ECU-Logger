// ECU = Electronic Control Unit
// BLE = Bluetooth Low Energy
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';
import '../services/ble_service.dart';
import '../services/file_logger_service.dart';
import '../services/dashboard_layout_service.dart';
import 'home_screen.dart';

/// Minimalist splash and loading screen following GitHub Primer dark aesthetics.
///
/// Displays a smooth telemetry pulse indicator, the application title in Canela,
/// and telemetry initialization status before seamlessly transitioning to [HomeScreen].
class SplashScreen extends StatefulWidget {
  /// The duration to display the loading screen before transitioning to [nextScreen].
  final Duration minDisplayDuration;

  /// The destination widget to transition to after initialization completes.
  final Widget nextScreen;

  /// Creates a [SplashScreen] widget.
  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 1200),
    this.nextScreen = const HomeScreen(),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// State controller managing splash animations, service initialization,
/// and smooth route transition to the main dashboard.
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Animation controller driving the rhythmic telemetry pulse and progress indicator.
  late final AnimationController _pulseController;

  /// Scale tween for the subtle cardiac pulse contraction and expansion.
  late final Animation<double> _pulseScaleAnimation;

  /// Opacity tween for luminous ambient glow pulsing.
  late final Animation<double> _pulseOpacityAnimation;

  /// Progress width factor for the minimalist linear progress indicator.
  late final Animation<double> _progressAnimation;

  /// Real-time status message displayed beneath the title during boot.
  String _statusMessage = 'INITIALIZING TELEMETRY...';

  /// Guard flag preventing redundant navigation triggers.
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _pulseScaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseOpacityAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _progressAnimation = Tween<double>(begin: 0.08, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseController.repeat(reverse: true);
    _performInitialization();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Asynchronously loads persistent storage configs and requests necessary hardware permissions.
  Future<void> _performInitialization() async {
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      if (mounted) {
        setState(() {
          _statusMessage = 'RESTORING LOG STORAGE...';
        });
      }
      await FileLoggerService.instance
          .initialize()
          .timeout(const Duration(milliseconds: 1500), onTimeout: () {});

      await DashboardLayoutService.instance
          .initialize()
          .timeout(const Duration(milliseconds: 1000), onTimeout: () {});

      if (mounted) {
        setState(() {
          _statusMessage = 'CHECKING BLE PERMISSIONS...';
        });
      }
      await BleService.instance
          .requestPermissions()
          .timeout(const Duration(milliseconds: 1500), onTimeout: () => true);

      if (mounted) {
        setState(() {
          _statusMessage = 'INITIALIZING TELEMETRY ENGINE...';
        });
      }
      // Non-blocking storage permission check
      await FileLoggerService.instance
          .requestStoragePermissions()
          .timeout(const Duration(milliseconds: 800), onTimeout: () => true);

      if (mounted) {
        setState(() {
          _statusMessage = 'TELEMETRY ENGINE READY';
        });
      }
    } catch (exception) {
      if (mounted) {
        setState(() {
          _statusMessage = 'READY';
        });
      }
    } finally {
      stopwatch.stop();
      final int elapsedMilliseconds = stopwatch.elapsedMilliseconds;
      final int targetMilliseconds = widget.minDisplayDuration.inMilliseconds;
      final int remainingMilliseconds = targetMilliseconds - elapsedMilliseconds;

      if (remainingMilliseconds > 0) {
        await Future<void>.delayed(
          Duration(milliseconds: remainingMilliseconds),
        );
      }

      if (mounted && !_isTransitioning) {
        _isTransitioning = true;
        _navigateToDashboard();
      }
    }
  }

  /// Executes a smooth cross-fade route replacement to the main dashboard.
  void _navigateToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return widget.nextScreen;
        },
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: GitHubTheme.canvasDefault,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Spacer(flex: 3),
                // Animated minimalist telemetry pulse icon
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (BuildContext context, Widget? child) {
                    return Transform.scale(
                      scale: _pulseScaleAnimation.value,
                      child: Opacity(
                        opacity: _pulseOpacityAnimation.value,
                        child: Container(
                          width: 108.0,
                          height: 108.0,
                          decoration: BoxDecoration(
                            color: GitHubTheme.canvasSubtle,
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(
                              color: GitHubTheme.borderDefault,
                              width: 1.5,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: GitHubTheme.accent.withValues(
                                  alpha: 0.15 * _pulseOpacityAnimation.value,
                                ),
                                blurRadius: 24.0,
                                spreadRadius: 2.0,
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            painter: _MinimalistPulsePainter(
                              pulseColor: GitHubTheme.accent,
                              glowColor: GitHubTheme.accentEmphasis,
                              dotColor: GitHubTheme.fgDefault,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32.0),
                // Canela application title
                const Text(
                  'ECU Logger',
                  style: TextStyle(
                    fontFamily: GitHubTheme.fontCanela,
                    fontSize: 30.0,
                    fontWeight: FontWeight.w600,
                    color: GitHubTheme.fgDefault,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12.0),
                // Telemetry status caption
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontFamily: GitHubTheme.fontGoogleSansCode,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    color: GitHubTheme.fgMuted,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 28.0),
                // Minimalist linear loading indicator bar
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (BuildContext context, Widget? child) {
                    return Container(
                      width: 140.0,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: GitHubTheme.borderMuted,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: GitHubTheme.accent,
                            borderRadius: BorderRadius.circular(2.0),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: GitHubTheme.accent.withValues(alpha: 0.5),
                                blurRadius: 6.0,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(flex: 4),
                // Bottom telemetry metadata label
                const Text(
                  'CAN BUS • OBD-II TELEMETRY',
                  style: TextStyle(
                    fontFamily: GitHubTheme.fontGoogleSansCode,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w400,
                    color: GitHubTheme.fgSubtle,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering a clean, ultra-minimal geometric telemetry pulse wave.
class _MinimalistPulsePainter extends CustomPainter {
  /// Primary color for the foreground pulse stroke.
  final Color pulseColor;

  /// Accent color for the pulse peak glow effect.
  final Color glowColor;

  /// Core fill color for the peak pulse node.
  final Color dotColor;

  /// Creates a [_MinimalistPulsePainter] instance.
  const _MinimalistPulsePainter({
    required this.pulseColor,
    required this.glowColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double centerY = height * 0.52;

    final Paint glowPaint = Paint()
      ..color = pulseColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint linePaint = Paint()
      ..color = pulseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Paint dotFillPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final Paint dotGlowPaint = Paint()
      ..color = pulseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Build the geometric pulse path perfectly centered horizontally
    final Path pulsePath = Path();
    pulsePath.moveTo(width * 0.16, centerY);
    pulsePath.lineTo(width * 0.34, centerY);
    pulsePath.lineTo(width * 0.40, centerY + height * 0.05);
    pulsePath.lineTo(width * 0.50, centerY - height * 0.26); // Center pulse spike
    pulsePath.lineTo(width * 0.60, centerY + height * 0.15); // Valley
    pulsePath.lineTo(width * 0.68, centerY - height * 0.05); // Rebound
    pulsePath.lineTo(width * 0.74, centerY);
    pulsePath.lineTo(width * 0.84, centerY);

    // Draw soft glow behind path
    canvas.drawPath(pulsePath, glowPaint);

    // Draw crisp foreground line
    canvas.drawPath(pulsePath, linePaint);

    // Draw centered peak pulse node
    final Offset peakPoint = Offset(width * 0.50, centerY - height * 0.26);
    canvas.drawCircle(peakPoint, 3.5, dotFillPaint);
    canvas.drawCircle(peakPoint, 5.5, dotGlowPaint);
  }

  @override
  bool shouldRepaint(covariant _MinimalistPulsePainter oldDelegate) {
    return oldDelegate.pulseColor != pulseColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.dotColor != dotColor;
  }
}
