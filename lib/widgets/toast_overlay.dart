import 'package:flutter/material.dart';
import '../theme/github_theme.dart';

/// Defines toast notification intent categories.
enum ToastType {
  /// Informational status toast.
  info,

  /// Successful action completion toast.
  success,

  /// Warning condition toast.
  warning,

  /// Error failure notification toast.
  error,
}

/// Service providing top-centered floating toast notifications.
class ToastService {
  static OverlayEntry? _currentEntry;

  /// Displays a floating toast bubble anchored at the top center of the screen.
  ///
  /// [context] is the current [BuildContext].
  /// [message] is the string payload to present.
  /// [type] defines the color accent and icon semantics.
  /// [duration] controls how long the bubble remains visible.
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext overlayContext) => _ToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future<void>.delayed(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}

/// Internal animated toast presentation widget.
class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getAccentColor() {
    switch (widget.type) {
      case ToastType.success:
        return GitHubTheme.successFg;
      case ToastType.warning:
        return GitHubTheme.warningFg;
      case ToastType.error:
        return GitHubTheme.dangerFg;
      case ToastType.info:
        return GitHubTheme.accent;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.warning:
        return Icons.warning_amber_rounded;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = _getAccentColor();
    final double topPadding = MediaQuery.of(context).padding.top + 16.0;

    return Positioned(
      top: topPadding,
      left: 20.0,
      right: 20.0,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: GitHubTheme.canvasSubtle,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12.0,
                      offset: const Offset(0.0, 4.0),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getIcon(), size: 18.0, color: accentColor),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontFamily: GitHubTheme.fontGoogleSans,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w500,
                          color: GitHubTheme.fgDefault,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
