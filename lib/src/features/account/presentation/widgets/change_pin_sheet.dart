import 'package:anholding_app/src/core/storage/pin_storage.dart';
import 'package:anholding_app/src/core/theme/app_colors.dart';
import 'package:anholding_app/src/features/auth/presentation/widgets/otp_pin_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// Step progression for the Change-PIN flow.
enum ChangePinStep { current, newPin, confirmNew }

/// Bottom sheet with a 3-step flow to change the user's PIN.
///
/// 1. Verify current PIN  →  2. Enter new PIN  →  3. Confirm new PIN.
class ChangePinSheet extends StatefulWidget {
  const ChangePinSheet({super.key});

  @override
  State<ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<ChangePinSheet> {
  final PinStorage _pinStorage = GetIt.I<PinStorage>();

  ChangePinStep _step = ChangePinStep.current;
  String _newPin = '';
  String? _error;
  bool _isLoading = false;

  // Controllers to reset input between steps.
  final TextEditingController _pinController = TextEditingController();

  String get _title {
    switch (_step) {
      case ChangePinStep.current:
        return 'Nhập mã PIN hiện tại';
      case ChangePinStep.newPin:
        return 'Nhập mã PIN mới';
      case ChangePinStep.confirmNew:
        return 'Xác nhận mã PIN mới';
    }
  }

  String get _description {
    switch (_step) {
      case ChangePinStep.current:
        return 'Vui lòng nhập mã PIN hiện tại để xác thực';
      case ChangePinStep.newPin:
        return 'Nhập mã PIN mới gồm 6 chữ số';
      case ChangePinStep.confirmNew:
        return 'Nhập lại mã PIN mới để xác nhận';
    }
  }

  Future<void> _onPinCompleted(String pin) async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    switch (_step) {
      case ChangePinStep.current:
        final valid = await _pinStorage.verifyPin(pin);
        if (!mounted) return;
        if (valid) {
          _resetController();
          setState(() {
            _step = ChangePinStep.newPin;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Mã PIN không đúng';
            _isLoading = false;
          });
          _resetController();
        }

      case ChangePinStep.newPin:
        _newPin = pin;
        _resetController();
        setState(() {
          _step = ChangePinStep.confirmNew;
          _isLoading = false;
        });

      case ChangePinStep.confirmNew:
        if (pin != _newPin) {
          setState(() {
            _error = 'Mã PIN không khớp';
            _isLoading = false;
          });
          _resetController();
          return;
        }
        await _pinStorage.savePin(pin);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đổi mã PIN thành công')),
        );
    }
  }

  void _resetController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pinController.clear();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.cardBackgroundSolid,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.borderInactive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Text(
            _title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            _description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // PIN input
          if (_isLoading)
            const SizedBox(
              height: 38,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryGold),
              ),
            )
          else
            OtpPinInputWidget(
              key: ValueKey(_step),
              controller: _pinController,
              obscureText: true,
              autoFocus: true,
              onCompleted: _onPinCompleted,
            ),

          // Error message
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.redAccent,
              ),
            ),
          ],

          // Step indicator
          const SizedBox(height: 20),
          _StepIndicator(current: _step),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Three-dot step indicator for the Change-PIN flow.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final ChangePinStep current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: ChangePinStep.values.map((step) {
        final isActive = step.index <= current.index;
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.primaryGold : AppColors.borderInactive,
          ),
        );
      }).toList(),
    );
  }
}
