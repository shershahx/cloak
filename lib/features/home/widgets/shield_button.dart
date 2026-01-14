import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../../core/models/vpn_state.dart';
import '../../../shared/theme/app_colors.dart';

/// Animated shield button for VPN toggle
class ShieldButton extends StatefulWidget {
  final VpnState vpnState;
  final VoidCallback onTap;

  const ShieldButton({
    super.key,
    required this.vpnState,
    required this.onTap,
  });

  @override
  State<ShieldButton> createState() => _ShieldButtonState();
}

class _ShieldButtonState extends State<ShieldButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _updateAnimation();
  }

  @override
  void didUpdateWidget(ShieldButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vpnState != widget.vpnState) {
      _updateAnimation();
    }
  }

  void _updateAnimation() {
    if (widget.vpnState.isConnected) {
      _pulseController.repeat(reverse: true);
      _rotateController.stop();
    } else if (widget.vpnState.isTransitioning) {
      _pulseController.stop();
      _rotateController.repeat();
    } else {
      _pulseController.stop();
      _rotateController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  void _handleTap() {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.vpnState.isConnected;
    final isTransitioning = widget.vpnState.isTransitioning;
    final shieldColor = isActive ? AppColors.shieldActive : AppColors.shieldInactive;

    return GestureDetector(
      onTap: widget.vpnState.canToggle ? _handleTap : null,
      onTapDown: widget.vpnState.canToggle ? _onTapDown : null,
      onTapUp: widget.vpnState.canToggle ? _onTapUp : null,
      onTapCancel: widget.vpnState.canToggle ? _onTapCancel : null,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _rotateController, _scaleAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: (isActive ? _pulseAnimation.value : 1.0) * _scaleAnimation.value,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow ring (when active)
                  if (isActive)
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3 * _pulseAnimation.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),

                  // Second glow layer for depth
                  if (isActive)
                    Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),

                  // Rotating ring (when transitioning)
                  if (isTransitioning)
                    Transform.rotate(
                      angle: _rotateController.value * 2 * math.pi,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 3,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Main shield circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                        color: shieldColor,
                        width: 4,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isActive ? Icons.shield : Icons.shield_outlined,
                      size: 72,
                      color: shieldColor,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
