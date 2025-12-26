import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../data/settings_provider.dart';

class ThemeEffectsOverlay extends ConsumerWidget {
  final Widget child;
  
  const ThemeEffectsOverlay({super.key, required this.child});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectsEnabled = ref.watch(themeEffectsEnabledProvider);
    final appStyle = ref.watch(appStyleProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (!effectsEnabled) return child;
    
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: _buildEffectForStyle(appStyle, isDark),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEffectForStyle(AppStyle style, bool isDark) {
    switch (style) {
      case AppStyle.normal:
        return NormalFloatingParticles(isDark: isDark);
      case AppStyle.glass:
        return GlassBubbleEffect(isDark: isDark);
      case AppStyle.nightcore:
        return NightcoreEffect(isDark: isDark);
      case AppStyle.cyberpunk:
        return CyberpunkGlitchEffect(isDark: isDark);
      case AppStyle.highContrast:
        return HighContrastScanlines(isDark: isDark);
    }
  }
}

class NormalFloatingParticles extends StatefulWidget {
  final bool isDark;
  const NormalFloatingParticles({super.key, required this.isDark});
  
  @override
  State<NormalFloatingParticles> createState() => _NormalFloatingParticlesState();
}

class _NormalFloatingParticlesState extends State<NormalFloatingParticles> with TickerProviderStateMixin {
  late List<_Particle> particles;
  late AnimationController _controller;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    particles = List.generate(15, (_) => _Particle.random(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _controller.addListener(() => setState(() {}));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final color = widget.isDark 
      ? Colors.white.withAlpha(25)
      : Colors.deepPurple.withAlpha(20);
    
    return CustomPaint(
      size: size,
      painter: _ParticlePainter(
        particles: particles,
        progress: _controller.value,
        color: color,
      ),
    );
  }
}

class _Particle {
  double x, y, size, speed;
  
  _Particle({required this.x, required this.y, required this.size, required this.speed});
  
  factory _Particle.random(Random random) {
    return _Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: random.nextDouble() * 4 + 2,
      speed: random.nextDouble() * 0.3 + 0.1,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;
  
  _ParticlePainter({required this.particles, required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    
    for (var p in particles) {
      final y = ((p.y + progress * p.speed) % 1.0) * size.height;
      final x = p.x * size.width + sin(progress * 2 * pi + p.x * 10) * 20;
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }
  
  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

class GlassBubbleEffect extends StatefulWidget {
  final bool isDark;
  const GlassBubbleEffect({super.key, required this.isDark});
  
  @override
  State<GlassBubbleEffect> createState() => _GlassBubbleEffectState();
}

class _GlassBubbleEffectState extends State<GlassBubbleEffect> with TickerProviderStateMixin {
  late List<_Bubble> bubbles;
  late AnimationController _controller;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    bubbles = List.generate(8, (_) => _Bubble.random(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _controller.addListener(() => setState(() {}));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: bubbles.map((bubble) {
        final y = size.height - ((bubble.startY + _controller.value * bubble.speed) % 1.2) * size.height * 1.2;
        final x = bubble.x * size.width + sin(_controller.value * 2 * pi * bubble.wobble) * 30;
        
        return Positioned(
          left: x - bubble.size / 2,
          top: y - bubble.size / 2,
          child: Container(
            width: bubble.size,
            height: bubble.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withAlpha(widget.isDark ? 30 : 50),
                  Colors.white.withAlpha(widget.isDark ? 10 : 20),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withAlpha(widget.isDark ? 40 : 60),
                width: 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Bubble {
  double x, startY, size, speed, wobble;
  
  _Bubble({required this.x, required this.startY, required this.size, required this.speed, required this.wobble});
  
  factory _Bubble.random(Random random) {
    return _Bubble(
      x: random.nextDouble(),
      startY: random.nextDouble(),
      size: random.nextDouble() * 30 + 15,
      speed: random.nextDouble() * 0.4 + 0.2,
      wobble: random.nextDouble() * 2 + 0.5,
    );
  }
}

class NightcoreEffect extends StatefulWidget {
  final bool isDark;
  const NightcoreEffect({super.key, required this.isDark});
  
  @override
  State<NightcoreEffect> createState() => _NightcoreEffectState();
}

class _NightcoreEffectState extends State<NightcoreEffect> with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _catController;
  final Random _random = Random();
  late List<_FloatingIcon> icons;
  bool _showCat = false;
  int _catPosition = 0;
  Timer? _catTimer;
  
  @override
  void initState() {
    super.initState();
    icons = List.generate(12, (_) => _FloatingIcon.random(_random));
    
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();
    _particleController.addListener(() => setState(() {}));
    
    _catController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scheduleCat();
  }
  
  void _scheduleCat() {
    _catTimer = Timer(Duration(seconds: _random.nextInt(8) + 5), () {
      if (mounted) {
        setState(() {
          _showCat = true;
          _catPosition = _random.nextInt(4);
        });
        _catController.forward().then((_) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _catController.reverse().then((_) {
                if (mounted) {
                  setState(() => _showCat = false);
                  _scheduleCat();
                }
              });
            }
          });
        });
      }
    });
  }
  
  @override
  void dispose() {
    _particleController.dispose();
    _catController.dispose();
    _catTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final baseColor = widget.isDark ? const Color(0xFFFF85A2) : const Color(0xFFFF69B4);
    
    return Stack(
      children: [
        ...icons.map((icon) {
          final progress = (_particleController.value + icon.offset) % 1.0;
          final y = size.height * (1 - progress);
          final x = icon.x * size.width + sin(progress * 2 * pi * 2) * 30;
          final opacity = sin(progress * pi) * 0.4;
          
          return Positioned(
            left: x - 10,
            top: y - 10,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Icon(
                icon.isHeart ? Icons.favorite : Icons.star,
                size: icon.size,
                color: icon.isHeart 
                  ? baseColor.withAlpha(150)
                  : Colors.amber.withAlpha(150),
              ),
            ),
          );
        }),
        if (_showCat)
          AnimatedBuilder(
            animation: _catController,
            builder: (context, child) {
              return _buildCat(size, _catController.value);
            },
          ),
      ],
    );
  }
  
  Widget _buildCat(Size size, double progress) {
    final catColor = widget.isDark ? Colors.white : Colors.black;
    final eyeColor = widget.isDark ? const Color(0xFFFF85A2) : const Color(0xFFFF69B4);
    
    double left = 0, top = 0;
    Alignment alignment = Alignment.bottomRight;
    
    switch (_catPosition) {
      case 0:
        left = -40 + progress * 50;
        top = size.height * 0.3;
        alignment = Alignment.centerLeft;
        break;
      case 1:
        left = size.width - 10 - progress * 50;
        top = size.height * 0.4;
        alignment = Alignment.centerRight;
        break;
      case 2:
        left = size.width * 0.2;
        top = size.height - 40 + (1 - progress) * 50;
        alignment = Alignment.bottomCenter;
        break;
      case 3:
        left = size.width * 0.7;
        top = size.height - 40 + (1 - progress) * 50;
        alignment = Alignment.bottomCenter;
        break;
    }
    
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: progress,
        child: SizedBox(
          width: 50,
          height: 40,
          child: CustomPaint(
            painter: _CatPainter(catColor: catColor, eyeColor: eyeColor),
          ),
        ),
      ),
    );
  }
}

class _CatPainter extends CustomPainter {
  final Color catColor;
  final Color eyeColor;
  
  _CatPainter({required this.catColor, required this.eyeColor});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = catColor;
    
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height * 0.7), width: size.width * 0.8, height: size.height * 0.5),
      paint,
    );
    
    final earPath = Path();
    earPath.moveTo(size.width * 0.15, size.height * 0.5);
    earPath.lineTo(size.width * 0.05, size.height * 0.1);
    earPath.lineTo(size.width * 0.35, size.height * 0.4);
    earPath.close();
    canvas.drawPath(earPath, paint);
    
    final earPath2 = Path();
    earPath2.moveTo(size.width * 0.85, size.height * 0.5);
    earPath2.lineTo(size.width * 0.95, size.height * 0.1);
    earPath2.lineTo(size.width * 0.65, size.height * 0.4);
    earPath2.close();
    canvas.drawPath(earPath2, paint);
    
    final eyePaint = Paint()..color = eyeColor;
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.6), 4, eyePaint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.6), 4, eyePaint);
    
    final nosePaint = Paint()..color = const Color(0xFFFFB6C1);
    final nosePath = Path();
    nosePath.moveTo(size.width * 0.5, size.height * 0.7);
    nosePath.lineTo(size.width * 0.45, size.height * 0.8);
    nosePath.lineTo(size.width * 0.55, size.height * 0.8);
    nosePath.close();
    canvas.drawPath(nosePath, nosePaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingIcon {
  double x, offset, size;
  bool isHeart;
  
  _FloatingIcon({required this.x, required this.offset, required this.size, required this.isHeart});
  
  factory _FloatingIcon.random(Random random) {
    return _FloatingIcon(
      x: random.nextDouble(),
      offset: random.nextDouble(),
      size: random.nextDouble() * 12 + 8,
      isHeart: random.nextBool(),
    );
  }
}

class CyberpunkGlitchEffect extends StatefulWidget {
  final bool isDark;
  const CyberpunkGlitchEffect({super.key, required this.isDark});
  
  @override
  State<CyberpunkGlitchEffect> createState() => _CyberpunkGlitchEffectState();
}

class _CyberpunkGlitchEffectState extends State<CyberpunkGlitchEffect> with TickerProviderStateMixin {
  bool _glitching = false;
  Timer? _glitchTimer;
  final Random _random = Random();
  late AnimationController _scanlineController;
  List<_GlitchLine> _glitchLines = [];
  
  @override
  void initState() {
    super.initState();
    _scanlineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanlineController.addListener(() => setState(() {}));
    _scheduleGlitch();
  }
  
  void _scheduleGlitch() {
    _glitchTimer = Timer(Duration(seconds: _random.nextInt(5) + 3), () {
      if (mounted) {
        setState(() {
          _glitching = true;
          _glitchLines = List.generate(
            _random.nextInt(5) + 3,
            (_) => _GlitchLine(
              y: _random.nextDouble(),
              height: _random.nextDouble() * 20 + 5,
              offset: (_random.nextDouble() - 0.5) * 30,
              color: _random.nextBool() ? const Color(0xFFFF006E) : const Color(0xFF00F5D4),
            ),
          );
        });
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() => _glitching = false);
            _scheduleGlitch();
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _scanlineController.dispose();
    _glitchTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: _scanlineController.value * size.height - 2,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF00F5D4).withAlpha(40),
                  const Color(0xFF00F5D4).withAlpha(60),
                  const Color(0xFF00F5D4).withAlpha(40),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFF006E).withAlpha(0),
                  const Color(0xFFFF006E).withAlpha((_scanlineController.value * 80).toInt()),
                  const Color(0xFFFF006E).withAlpha(0),
                ],
                stops: [
                  (_scanlineController.value - 0.2).clamp(0.0, 1.0),
                  _scanlineController.value,
                  (_scanlineController.value + 0.2).clamp(0.0, 1.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00F5D4).withAlpha(0),
                  const Color(0xFF00F5D4).withAlpha(((1 - _scanlineController.value) * 80).toInt()),
                  const Color(0xFF00F5D4).withAlpha(0),
                ],
                stops: [
                  ((1 - _scanlineController.value) - 0.2).clamp(0.0, 1.0),
                  (1 - _scanlineController.value),
                  ((1 - _scanlineController.value) + 0.2).clamp(0.0, 1.0),
                ],
              ),
            ),
          ),
        ),
        if (_glitching)
          ..._glitchLines.map((line) => Positioned(
            left: line.offset,
            right: -line.offset,
            top: line.y * size.height,
            height: line.height,
            child: Container(
              color: line.color.withAlpha(100),
            ),
          )),
      ],
    );
  }
}

class _GlitchLine {
  double y, height, offset;
  Color color;
  
  _GlitchLine({required this.y, required this.height, required this.offset, required this.color});
}

class HighContrastScanlines extends StatefulWidget {
  final bool isDark;
  const HighContrastScanlines({super.key, required this.isDark});
  
  @override
  State<HighContrastScanlines> createState() => _HighContrastScanlinesState();
}

class _HighContrastScanlinesState extends State<HighContrastScanlines> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final lineColor = widget.isDark 
      ? Colors.white.withAlpha(8)
      : Colors.black.withAlpha(8);
    
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: List.generate(60, (i) => i.isEven ? lineColor : Colors.transparent),
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcOver,
      child: Container(
        color: Colors.transparent,
      ),
    );
  }
}
