import 'package:flutter/material.dart';
import '../../features/tables/tables_provider.dart';

/// Overlay banner hiển thị thông báo từ Desktop khi cập nhật dịch vụ.
/// Banner ở lại cho đến khi người dùng chủ động bấm close hoặc chạm vào thông báo.
class DesktopUpdateBanner extends StatefulWidget {
  final DesktopNotificationEvent event;
  final VoidCallback onDismissed;

  const DesktopUpdateBanner({
    super.key,
    required this.event,
    required this.onDismissed,
  });

  @override
  State<DesktopUpdateBanner> createState() => _DesktopUpdateBannerState();
}

class _DesktopUpdateBannerState extends State<DesktopUpdateBanner>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Shake animation để thu hút sự chú ý
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool _isClosing = false;

  @override
  void initState() {
    super.initState();

    // Slide-in animation — banner trượt xuống từ trên
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // Shake animation — rung nhẹ sau khi vào
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    // Slide in, sau đó shake
    _slideController.forward().then((_) {
      if (mounted) _shakeController.forward();
    });
  }

  void _dismiss() {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    _slideController.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isApproved =
        widget.event.type == DesktopNotificationType.serviceApproved;

    final Color bannerColor =
        isApproved ? const Color(0xFF16A34A) : const Color(0xFF2563EB);
    final IconData bannerIcon =
        isApproved ? Icons.check_circle_rounded : Icons.notifications_active_rounded;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: child,
            ),
            child: Material(
              elevation: 14,
              borderRadius: BorderRadius.circular(20),
              shadowColor: bannerColor.withValues(alpha: 0.5),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _dismiss,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        bannerColor,
                        bannerColor.withValues(alpha: 0.80),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Icon container
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(bannerIcon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),

                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isApproved
                                    ? '✓ Dịch vụ đã được duyệt'
                                    : '🔔 Cập nhật dịch vụ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.event.message,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              // "Nhấn để đóng" hint
                              Text(
                                'Chạm để đóng thông báo',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Close button — prominent
                        Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mixin giúp bất kỳ ConsumerStatefulWidget nào dễ dàng lắng nghe và hiển thị banner.
mixin DesktopUpdateBannerMixin<T extends StatefulWidget> on State<T> {
  DesktopNotificationEvent? _currentNotification;

  /// Timestamp của các sự kiện đã bị user đóng (static để ghi nhớ xuyên suốt các màn hình)
  static DateTime? _globalDismissedTimestamp;

  void handleDesktopNotification(
    TablesState? previous,
    TablesState next,
  ) {
    final newEvent = next.desktopNotification;
    if (newEvent == null) {
      if (_currentNotification != null) {
        setState(() {
          _currentNotification = null;
        });
      }
      return;
    }

    // Không hiện nếu user đã bấm đóng sự kiện này rồi (hoặc cùng timestamp)
    if (_globalDismissedTimestamp == newEvent.timestamp) return;

    // Không hiện lại nếu đang hiển thị cùng sự kiện
    if (_currentNotification?.timestamp == newEvent.timestamp) return;

    if (mounted) {
      setState(() {
        _currentNotification = newEvent;
      });
    }
  }

  void clearDesktopNotification() {
    if (mounted) {
      setState(() {
        // Ghi nhớ timestamp đã đóng vào biến static để không bao giờ hiện lại
        _globalDismissedTimestamp = _currentNotification?.timestamp;
        _currentNotification = null;
      });
    }
  }

  Widget buildDesktopBannerOverlay(Widget child) {
    if (_currentNotification == null) return child;

    return Stack(
      children: [
        child,
        DesktopUpdateBanner(
          key: ValueKey(_currentNotification!.timestamp),
          event: _currentNotification!,
          onDismissed: clearDesktopNotification,
        ),
      ],
    );
  }
}
