import 'package:flutter/material.dart';

/// Concentric "radar" pulse with a centred icon — the visual anchor for any
/// active NFC session (read or write).
class NfcPulse extends StatefulWidget {
  const NfcPulse({
    super.key,
    required this.color,
    this.icon = Icons.nfc_rounded,
    this.size = 180,
    this.active = true,
  });

  final Color color;
  final IconData icon;
  final double size;
  final bool active;

  @override
  State<NfcPulse> createState() => _NfcPulseState();
}

class _NfcPulseState extends State<NfcPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant NfcPulse old) {
    super.didUpdateWidget(old);
    if (widget.active && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.active && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final core = widget.size * 0.34;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 3; i++) _ring(i / 3),
              Container(
                width: core,
                height: core,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.color,
                      Color.lerp(widget.color, Colors.black, 0.25)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.45),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(widget.icon,
                    color: Colors.white, size: core * 0.5),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double phase) {
    final t = widget.active ? (_c.value + phase) % 1.0 : phase;
    final scale = 0.42 + t * 0.58;
    final opacity = widget.active ? (1 - t) * 0.4 : 0.18;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Container(
        width: widget.size * scale,
        height: widget.size * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.color, width: 2),
        ),
      ),
    );
  }
}
