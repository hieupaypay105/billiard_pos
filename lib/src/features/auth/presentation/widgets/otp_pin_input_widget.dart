import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 6-cell OTP / PIN input widget.
///
/// Built with plain Flutter (no external packages) using a hidden
/// [TextField] and an overlay row of styled boxes.
class OtpPinInputWidget extends StatefulWidget {
  const OtpPinInputWidget({
    required this.onCompleted,
    this.length = 6,
    this.boxSize = 30,
    this.obscureText = false,
    this.onChanged,
    this.controller,
    this.isLoading = false,
    this.autoFocus = false,
    super.key,
  });

  /// Size of each PIN box
  final double boxSize;

  /// Number of cells. Defaults to 6.
  final int length;

  /// Whether to mask the characters (for PIN).
  final bool obscureText;

  /// Called when all cells are filled.
  final ValueChanged<String> onCompleted;

  /// Called on every keystroke.
  final ValueChanged<String>? onChanged;

  /// Optional external controller.
  final TextEditingController? controller;

  /// Whether the input is loading/disabled.
  final bool isLoading;

  /// Whether to request focus automatically after first frame.
  final bool autoFocus;

  @override
  State<OtpPinInputWidget> createState() => _OtpPinInputWidgetState();
}

class _OtpPinInputWidgetState extends State<OtpPinInputWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _value = '';
  // Guard to prevent onCompleted from firing more than once per entry session.
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.autoFocus || widget.isLoading) return;
      _focusNode.requestFocus();
    });
  }

  void _onChanged() {
    final text = _controller.text;

    // Prevent typing beyond max length
    if (text.length > widget.length) {
      _controller.text = text.substring(0, widget.length);
      _controller.selection = TextSelection.collapsed(
        offset: widget.length,
      );
      return;
    }

    if (text != _value) {
      // Reset completion guard when user edits (deletes a digit)
      if (text.length < widget.length) _isCompleted = false;

      setState(() => _value = text);
      widget.onChanged?.call(text);

      if (text.length == widget.length && !_isCompleted) {
        _isCompleted = true;
        _focusNode.unfocus();
        // Defer onCompleted to avoid calling notifyListeners() during a build
        // phase, which would crash with "setState called during build".
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onCompleted(text);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading
          ? null
          : () {
              _focusNode.requestFocus();
            },
      child: Opacity(
        opacity: widget.isLoading ? 0.5 : 1.0,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hidden text field to capture keyboard input
            Opacity(
              opacity: 0,
              child: SizedBox(
                height: 1,
                child: TextField(
                  enabled: !widget.isLoading,
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  maxLength: widget.length,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Visual boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.length, (index) {
                final isActive =
                    index == _value.length ||
                    (index < _value.length && _focusNode.hasFocus);
                final isFilled = index < _value.length;
                final char = isFilled ? _value[index] : '';

                return Container(
                  width: widget.boxSize,
                  height: widget.boxSize,
                  margin: EdgeInsets.only(
                    right: index < widget.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: (isActive && _focusNode.hasFocus) || isFilled
                          ? AppColors.authTextSecondary
                          : AppColors.pinBoxBorderInactive,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.obscureText && isFilled ? '●' : char,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
