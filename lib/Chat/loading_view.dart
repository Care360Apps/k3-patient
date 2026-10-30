import 'package:doctro_patient/const/Palette.dart';
import 'package:flutter/material.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: ShimmerLines()),
      color: Colors.white.withOpacity(0.8),
    );
  }
}

class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration period;
  final Color baseColor;
  final Color highlightColor;
  const Shimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1200),
    this.baseColor = const Color(0xFFE6EDF5),
    this.highlightColor = const Color(0xFFF5F9FF),
  });
  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = _controller.value;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1.0, -0.3),
              end: Alignment(2.0, 0.3),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                (value - 0.3).clamp(0.0, 1.0),
                value.clamp(0.0, 1.0),
                (value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class ShimmerIndicator extends StatelessWidget {
  final double size;
  final bool circle;
  final double borderRadius;
  const ShimmerIndicator({
    super.key,
    this.size = 40,
    this.circle = true,
    this.borderRadius = 12,
  });
  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE6EDF5),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;
  const ShimmerBox({
    super.key,
    required this.height,
    required this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });
  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: const Color(0xFFE6EDF5),
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class ShimmerLines extends StatelessWidget {
  final bool compact;
  const ShimmerLines({super.key, this.compact = false});
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = compact ? 10.0 : 14.0;
    final spacing = compact ? 10.0 : 14.0;
    final w1 = size.width * (compact ? 0.6 : 0.7);
    final w2 = size.width * (compact ? 0.5 : 0.6);
    final w3 = size.width * (compact ? 0.4 : 0.5);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShimmerBox(height: h, width: w1),
        SizedBox(height: spacing),
        ShimmerBox(height: h, width: w2),
        SizedBox(height: spacing),
        ShimmerBox(height: h, width: w3),
      ],
    );
  }
}

class SpinKitFadingCircle extends StatelessWidget {
  final Color color;
  final double size;
  const SpinKitFadingCircle({super.key, this.color = Palette.blue, this.size = 40});
  @override
  Widget build(BuildContext context) {
    return ShimmerIndicator(size: size);
  }
}

class SpinKitPulse extends StatelessWidget {
  final Color color;
  final double size;
  const SpinKitPulse({super.key, this.color = Palette.blue, this.size = 40});
  @override
  Widget build(BuildContext context) {
    return ShimmerIndicator(size: size);
  }
}
