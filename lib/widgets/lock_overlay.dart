// PIN = Personal Identification Number
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/github_theme.dart';

/// Full-page translucent overlay preventing accidental pocket touches while preserving
/// background dashboard visibility, unlocked only by entering a dynamic 4-digit PIN.
class LockOverlay extends StatefulWidget {
  /// Callback fired when the correct dynamic PIN is entered.
  final VoidCallback onUnlock;

  /// Creates a [LockOverlay] instance.
  const LockOverlay({super.key, required this.onUnlock});

  @override
  State<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay> {
  late String _targetPin;
  String _enteredPin = '';
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _generatePin();
  }

  void _generatePin() {
    final Random random = Random();
    final int digit1 = random.nextInt(10);
    final int digit2 = random.nextInt(10);
    final int digit3 = random.nextInt(10);
    final int digit4 = random.nextInt(10);
    _targetPin = '$digit1$digit2$digit3$digit4';
    _enteredPin = '';
    _isError = false;
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _enteredPin += digit;
      _isError = false;
    });

    if (_enteredPin.length == 4) {
      if (_enteredPin == _targetPin) {
        widget.onUnlock();
      } else {
        setState(() {
          _isError = true;
        });
        Future<void>.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _enteredPin = '';
              _isError = false;
              _generatePin();
            });
          }
        });
      }
    }
  }

  void _onClearPressed() {
    setState(() {
      _enteredPin = '';
      _isError = false;
    });
  }

  Widget _buildKeypadButton(String label, {VoidCallback? onPressed, Color? color}) {
    return InkWell(
      onTap: onPressed ?? () => _onDigitPressed(label),
      borderRadius: BorderRadius.circular(32.0),
      child: Container(
        width: 68.0,
        height: 68.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: GitHubTheme.canvasSubtle.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(
            color: GitHubTheme.borderDefault.withValues(alpha: 0.9),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: GitHubTheme.fontGoogleSansCode,
            fontSize: 22.0,
            fontWeight: FontWeight.w600,
            color: color ?? GitHubTheme.fgDefault,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String formattedTarget = _targetPin.split('').join(' ');

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: GitHubTheme.canvasDefault.withValues(alpha: 0.40),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shield Icon & Header
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: GitHubTheme.accentEmphasis.withValues(alpha: 0.2),
                    border: Border.all(color: GitHubTheme.accent.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 32.0,
                    color: GitHubTheme.accent,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Challenge instruction text container styled with number button background
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: GitHubTheme.canvasSubtle.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: GitHubTheme.borderDefault.withValues(alpha: 0.9),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    'Press "$formattedTarget" to open',
                    style: const TextStyle(
                      fontFamily: GitHubTheme.fontGoogleSans,
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                      color: GitHubTheme.fgDefault,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                const Text(
                  'Pocket touch prevention active • Logging continues underneath',
                  style: TextStyle(
                    fontFamily: GitHubTheme.fontGoogleSans,
                    fontSize: 11.0,
                    color: GitHubTheme.fgMuted,
                  ),
                ),
                const SizedBox(height: 20.0),

                // Entered PIN indicator dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (int index) {
                    final bool isFilled = index < _enteredPin.length;
                    Color dotColor = GitHubTheme.fgSubtle;
                    if (_isError) {
                      dotColor = GitHubTheme.dangerFg;
                    } else if (isFilled) {
                      dotColor = GitHubTheme.accent;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6.0),
                      width: 14.0,
                      height: 14.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? dotColor : Colors.transparent,
                        border: Border.all(color: dotColor, width: 1.5),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 30.0),

                // Keypad Grid
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildKeypadButton('1'),
                        const SizedBox(width: 24.0),
                        _buildKeypadButton('2'),
                        const SizedBox(width: 24.0),
                        _buildKeypadButton('3'),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildKeypadButton('4'),
                        const SizedBox(width: 24.0),
                        _buildKeypadButton('5'),
                        const SizedBox(width: 24.0),
                        _buildKeypadButton('6'),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildKeypadButton('7'),
                        const SizedBox(width: 24.0),
                        _buildKeypadButton('8'),
                        const SizedBox(width: 24.0),
                        _buildKeypadButton('9'),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildKeypadButton(
                          'CLR',
                          onPressed: _onClearPressed,
                          color: GitHubTheme.dangerFg,
                        ),
                        const SizedBox(width: 24.0),
                        _buildKeypadButton('0'),
                        const SizedBox(width: 24.0),
                        InkWell(
                          onTap: () {
                            if (_enteredPin.isNotEmpty) {
                              setState(() {
                                _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(32.0),
                          child: Container(
                            width: 68.0,
                            height: 68.0,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: GitHubTheme.canvasSubtle.withValues(alpha: 0.85),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: GitHubTheme.borderDefault.withValues(alpha: 0.9),
                                width: 1.2,
                              ),
                            ),
                            child: const Icon(
                              Icons.backspace_outlined,
                              size: 20.0,
                              color: GitHubTheme.fgMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
