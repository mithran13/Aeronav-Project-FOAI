import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Wraps any widget with smooth 60 FPS scale elevation and electric glow on cursor hover
class HoverAnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? glowColor;
  final double hoverScale;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const HoverAnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.glowColor,
    this.hoverScale = 1.025,
    this.borderRadius,
    this.padding,
  });

  @override
  State<HoverAnimatedCard> createState() => _HoverAnimatedCardState();
}

class _HoverAnimatedCardState extends State<HoverAnimatedCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = widget.glowColor ?? AppColors.electricBlue;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final s = _isHovered ? widget.hoverScale : 1.0;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          transform: Matrix4.diagonal3Values(s, s, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: effectiveRadius,
            boxShadow: [
              BoxShadow(
                color: _isHovered ? effectiveGlow.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.15),
                blurRadius: _isHovered ? 18 : 8,
                spreadRadius: _isHovered ? 1 : 0,
                offset: _isHovered ? const Offset(0, 4) : const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: effectiveRadius,
              border: Border.all(
                color: _isHovered ? effectiveGlow : effectiveGlow.withValues(alpha: 0.2),
                width: _isHovered ? 1.5 : 1.0,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Reusable Hover Animated Button with scale, glow aura, and icon pulse
class HoverAnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const HoverAnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.color = AppColors.electricBlue,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    this.borderRadius,
  });

  @override
  State<HoverAnimatedButton> createState() => _HoverAnimatedButtonState();
}

class _HoverAnimatedButtonState extends State<HoverAnimatedButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(22);
    final s = _isHovered ? 1.04 : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          transform: Matrix4.diagonal3Values(s, s, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: _isHovered ? widget.color.withValues(alpha: 0.9) : widget.color,
            borderRadius: effectiveRadius,
            boxShadow: [
              BoxShadow(
                color: _isHovered ? widget.color.withValues(alpha: 0.5) : widget.color.withValues(alpha: 0.2),
                blurRadius: _isHovered ? 14 : 6,
                spreadRadius: _isHovered ? 1 : 0,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Sidebar / Navigation Rail Interactive Destination with Hover Scale & Active Glow Pill
class HoverNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isCompact;
  final bool isDark;

  const HoverNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isCompact = false,
    this.isDark = true,
  });

  @override
  State<HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<HoverNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.electricBlue;
    final textColor = widget.isSelected
        ? (widget.isDark ? Colors.white : AppColors.lightText)
        : (widget.isDark ? AppColors.textSecondary : AppColors.lightTextMuted);
    final s = _isHovered ? 1.05 : 1.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 8 : 14,
            vertical: 10,
          ),
          transform: Matrix4.diagonal3Values(s, s, 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? activeColor.withValues(alpha: 0.2)
                : (_isHovered ? activeColor.withValues(alpha: 0.1) : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? activeColor
                  : (_isHovered ? activeColor.withValues(alpha: 0.4) : Colors.transparent),
            ),
            boxShadow: _isHovered || widget.isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: widget.isSelected ? 0.3 : 0.15),
                      blurRadius: 10,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: widget.isCompact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isSelected ? activeColor : (_isHovered ? AppColors.skyBlue : textColor),
                ),
              ),
              if (!widget.isCompact) ...[
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
