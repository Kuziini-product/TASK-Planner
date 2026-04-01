import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

class QuickAddFab extends StatelessWidget {
  const QuickAddFab({
    super.key,
    this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'quick_add_fab',
      onPressed: onPressed ?? () => context.push(AppRoutes.createTask),
      elevation: 4,
      backgroundColor: AppColors.primary,
      child: Icon(
        PhosphorIcons.plus(PhosphorIconsStyle.bold),
        color: Colors.white,
        size: 28,
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          duration: 400.ms,
          curve: Curves.elasticOut,
          delay: 300.ms,
        )
        .fadeIn(duration: 200.ms, delay: 300.ms);
  }
}

class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    this.onCreateTask,
    this.onQuickAdd,
  });

  final VoidCallback? onCreateTask;
  final VoidCallback? onQuickAdd;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Quick add option
        if (_isOpen) ...[
          _MiniAction(
            label: 'Quick Add',
            icon: PhosphorIcons.lightning(PhosphorIconsStyle.fill),
            color: AppColors.warning,
            onTap: () {
              _toggle();
              widget.onQuickAdd?.call();
            },
          ),
          const SizedBox(height: 8),
          _MiniAction(
            label: 'New Task',
            icon: PhosphorIcons.notepad(PhosphorIconsStyle.fill),
            color: AppColors.primary,
            onTap: () {
              _toggle();
              (widget.onCreateTask ??
                  () => context.push(AppRoutes.createTask))();
            },
          ),
          const SizedBox(height: 12),
        ],

        // Main FAB
        FloatingActionButton(
          heroTag: 'expandable_fab',
          onPressed: _toggle,
          backgroundColor: AppColors.primary,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 0.75,
                child: Icon(
                  _isOpen
                      ? PhosphorIcons.x(PhosphorIconsStyle.bold)
                      : PhosphorIcons.plus(PhosphorIconsStyle.bold),
                  color: Colors.white,
                  size: 28,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        const SizedBox(width: 8),
        FloatingActionButton.small(
          heroTag: 'mini_$label',
          onPressed: onTap,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 200.ms)
        .moveY(begin: 10, duration: 200.ms);
  }
}
