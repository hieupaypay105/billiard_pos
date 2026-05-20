import 'dart:async';

import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Figma-styled table card shell with optional pinch-to-zoom support.
class AnZoomableTableCard extends StatefulWidget {
  const AnZoomableTableCard({
    required this.child,
    super.key,
    this.enableZoom = true,
    this.minScale = 0.75,
    this.maxScale = 2.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.transparentShell = false,
  });

  final Widget child;
  final bool enableZoom;
  final double minScale;
  final double maxScale;
  final BorderRadius borderRadius;
  final bool transparentShell;

  @override
  State<AnZoomableTableCard> createState() => _AnZoomableTableCardState();
}

class _AnZoomableTableCardState extends State<AnZoomableTableCard> {
  static const Duration _indicatorVisibilityDuration = Duration(seconds: 2);

  final TransformationController _zoomController = TransformationController();
  Timer? _hideIndicatorTimer;
  double _currentScale = 1;
  bool _showZoomIndicator = false;

  @override
  void dispose() {
    _hideIndicatorTimer?.cancel();
    _zoomController.dispose();
    super.dispose();
  }

  void _onInteractionStart(ScaleStartDetails _) {
    _showIndicator();
  }

  void _onInteractionUpdate(ScaleUpdateDetails _) {
    _showIndicator();
    final nextScale = _zoomController.value.getMaxScaleOnAxis().clamp(
      widget.minScale,
      widget.maxScale,
    );
    if (_currentScale == nextScale) return;
    setState(() {
      _currentScale = nextScale;
    });
  }

  void _onInteractionEnd(ScaleEndDetails _) {
    _scheduleIndicatorHide();
  }

  void _showIndicator() {
    _hideIndicatorTimer?.cancel();
    if (!_showZoomIndicator) {
      setState(() {
        _showZoomIndicator = true;
      });
    }
  }

  void _scheduleIndicatorHide() {
    _hideIndicatorTimer?.cancel();
    _hideIndicatorTimer = Timer(_indicatorVisibilityDuration, () {
      if (!mounted) return;
      setState(() {
        _showZoomIndicator = false;
      });
    });
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
    setState(() {
      _currentScale = 1.0;
      _showZoomIndicator = true;
    });
    _scheduleIndicatorHide();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transparentShell) {
      return Stack(
        alignment: Alignment.topRight,
        children: [
          if (widget.enableZoom)
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: _resetZoom,
              child: InteractiveViewer(
                transformationController: _zoomController,
                minScale: widget.minScale,
                maxScale: widget.maxScale,
                onInteractionStart: _onInteractionStart,
                onInteractionUpdate: _onInteractionUpdate,
                onInteractionEnd: _onInteractionEnd,
                child: widget.child,
              ),
            )
          else
            widget.child,
          AnimatedOpacity(
            opacity: _showZoomIndicator ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 52),
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${_currentScale.toStringAsFixed(1)}\u00D7',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.dashboardCardStart, AppColors.dashboardCardEnd],
        ),
        borderRadius: widget.borderRadius,
        border: Border.all(color: AppColors.tableCardBorder),
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            if (widget.enableZoom)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: _resetZoom,
                child: InteractiveViewer(
                  transformationController: _zoomController,
                  minScale: widget.minScale,
                  maxScale: widget.maxScale,
                  panEnabled: false,
                  onInteractionStart: _onInteractionStart,
                  onInteractionUpdate: _onInteractionUpdate,
                  onInteractionEnd: _onInteractionEnd,
                  child: widget.child,
                ),
              )
            else
              widget.child,
            AnimatedOpacity(
              opacity: _showZoomIndicator ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IgnorePointer(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 52),
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${_currentScale.toStringAsFixed(1)}\u00D7',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.authButtonText,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
