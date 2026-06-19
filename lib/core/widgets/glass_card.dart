import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/theme.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool animateHover;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 16.0,
    this.blur = 15.0,
    this.color,
    this.borderColor,
    this.onTap,
    this.animateHover = true,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.color ?? Colors.white.withOpacity(0.04);
    final borderCol = widget.borderColor ?? Colors.white.withOpacity(0.08);

    Widget current = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isHovered && widget.animateHover
                  ? AppTheme.neonPurple.withOpacity(0.5)
                  : borderCol,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              if (_isHovered && widget.animateHover)
                BoxShadow(
                  color: AppTheme.neonPurple.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null || widget.animateHover) {
      current = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isHovered && widget.animateHover ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: current,
          ),
        ),
      );
    }

    return Padding(
      padding: widget.margin,
      child: current,
    );
  }
}
