import 'package:flutter/material.dart';

class FloatingCard extends StatefulWidget {
  final ColorScheme colorScheme;
  final Widget child;
  final double elevation;
  final EdgeInsetsGeometry padding;
  final Duration duration;
  final double hoverElevation;
  final double? maxWidth;
  final double? height;

  const FloatingCard({
    super.key,
    required this.colorScheme,
    required this.child,
    this.elevation = 4,
    this.padding = const EdgeInsets.all(16.0),
    this.duration = const Duration(milliseconds: 200),
    this.hoverElevation = 8,
    this.maxWidth,
    this.height,
  });

  @override
  State<FloatingCard> createState() => _FloatingCardState();
}

class _FloatingCardState extends State<FloatingCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.maxWidth ?? double.infinity,
            minHeight: widget.height ?? 74, // 默认最小高度为74
          ),
          child: AnimatedContainer(
            duration: widget.duration,
            transformAlignment: Alignment.center,
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isHovered ? widget.hoverElevation : widget.elevation,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  splashColor: widget.colorScheme.primary.withOpacity(0.1),
                  hoverColor: widget.colorScheme.primary.withOpacity(0.05),
                  onTap: () {
                    // 可以添加点击事件处理
                  },
                  child: Padding(
                      padding: widget.padding,
                      child: SizedBox(
                        height: widget.height,
                        child: widget.child,
                      )),
                )),
          ),
        ),
      ),
    );
  }
}
