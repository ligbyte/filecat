import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CopyButton extends StatefulWidget {
  final VoidCallback onTap;

  const CopyButton({super.key, required this.onTap});

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _isPressed 
              ? AppColors.primary.withOpacity(0.05) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.content_copy_outlined,
          color: _isPressed ? AppColors.primary : AppColors.textLight,
          size: 16,
        ),
      ),
    );
  }
}
