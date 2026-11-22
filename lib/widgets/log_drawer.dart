import 'package:flutter/material.dart';
import '../theme/github_theme.dart';

class LogDrawer extends StatefulWidget {
  final List<String> logs;
  final VoidCallback onClear;

  const LogDrawer({
    super.key,
    required this.logs,
    required this.onClear,
  });

  @override
  State<LogDrawer> createState() => _LogDrawerState();
}

class _LogDrawerState extends State<LogDrawer> {
  bool _isExpanded = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant LogDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isExpanded && widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: _isExpanded ? 260 : 48,
      decoration: const BoxDecoration(
        color: GitHubTheme.canvasInset,
        border: Border(
          top: BorderSide(color: GitHubTheme.borderDefault, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // Header / Handle
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              height: 47,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: GitHubTheme.canvasSubtle,
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: GitHubTheme.fgMuted,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'CONSOLE LOG (${widget.logs.length})',
                    style: const TextStyle(
                      fontFamily: GitHubTheme.fontGoogleSansCode,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: GitHubTheme.fgDefault,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  if (_isExpanded) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: GitHubTheme.fgSubtle,
                      tooltip: 'Clear Console',
                      onPressed: widget.onClear,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.logs.isNotEmpty
                          ? GitHubTheme.successFg
                          : GitHubTheme.fgSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Log Content (Expanded)
          if (_isExpanded)
            Expanded(
              child: widget.logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Awaiting telemetry frames...',
                        style: TextStyle(
                          fontFamily: GitHubTheme.fontGoogleSansCode,
                          fontSize: 12,
                          color: GitHubTheme.fgSubtle,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: widget.logs.length,
                      itemBuilder: (context, index) {
                        final line = widget.logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            line,
                            style: TextStyle(
                              fontFamily: GitHubTheme.fontGoogleSansCode,
                              fontSize: 11,
                              color: line.startsWith('[SYSTEM]')
                                  ? GitHubTheme.accent
                                  : (line.startsWith('770') || line.startsWith('212')
                                      ? GitHubTheme.successFg
                                      : GitHubTheme.fgMuted),
                            ),
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
