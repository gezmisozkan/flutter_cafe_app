import 'package:flutter/material.dart';

class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height, this.borderRadius});

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Theme.of(context).colorScheme.surfaceVariant,
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                Theme.of(context).colorScheme.surfaceVariant,
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Skeleton(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                const Skeleton(width: 120, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Skeleton(width: 60, height: 16),
        ],
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Skeleton(width: double.infinity, height: 20),
            const SizedBox(height: 8),
            const Skeleton(width: 150, height: 14),
            const SizedBox(height: 12),
            const Skeleton(width: double.infinity, height: 12),
            const SizedBox(height: 4),
            const Skeleton(width: 200, height: 12),
          ],
        ),
      ),
    );
  }
}
