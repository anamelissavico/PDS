import 'package:flutter/material.dart';
import 'dart:math' as math;

class QuizLoadingScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final int durationSeconds;

  const QuizLoadingScreen({
    Key? key,
    this.onComplete,
    this.durationSeconds = 5,
  }) : super(key: key);

  @override
  State<QuizLoadingScreen> createState() => _QuizLoadingScreenState();
}

class _QuizLoadingScreenState extends State<QuizLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _sparkleController;
  late AnimationController _floatingController;

  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  int _currentMessageIndex = 0;

  final List<String> _loadingMessages = [
    "🎮 Preparando o quiz perfeito para você...",
    "🧠 Selecionando as melhores perguntas...",
    "⚡ Ajustando o nível de dificuldade...",
    "🎯 Finalizando os últimos detalhes...",
    "🏆 Tudo pronto! Vamos começar!"
  ];

  final List<IconData> _gameIcons = [
    Icons.games,
    Icons.emoji_events,
    Icons.flash_on,
    Icons.track_changes,
    Icons.psychology,
    Icons.lightbulb,
    Icons.auto_awesome,
  ];

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: Duration(seconds: widget.durationSeconds),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _sparkleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_rotationController);

    _progressController.forward();

    _startMessageTimer();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete?.call();
        });
      }
    });
  }

  void _startMessageTimer() {
    final messageDuration = widget.durationSeconds / _loadingMessages.length;
    Future.delayed(Duration(seconds: messageDuration.round()), () {
      if (!mounted) return;
      setState(() {
        _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
      });
      if (_currentMessageIndex != 0) _startMessageTimer();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _sparkleController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C3AED),
              Color(0xFF6D28D9),
              Color(0xFFEAB308),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animado
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        Stack(
                          children: [
                            AnimatedBuilder(
                              animation: _rotationAnimation,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotationAnimation.value * 2 * math.pi,
                                  child: const Icon(Icons.games, size: 64, color: Color(0xFFFDE047)),
                                );
                              },
                            ),
                            ...List.generate(6, (index) {
                              return AnimatedBuilder(
                                animation: _sparkleController,
                                builder: (context, child) {
                                  final angle = (index * 60 + _sparkleController.value * 360) * math.pi / 180;
                                  final radius = 40.0;
                                  return Positioned(
                                    left: 32 + radius * math.cos(angle) - 6,
                                    top: 32 + radius * math.sin(angle) - 6,
                                    child: Transform.scale(
                                      scale: 0.5 + 0.5 * math.sin(_sparkleController.value * 2 * math.pi + index),
                                      child: const Icon(Icons.auto_awesome, size: 12, color: Color(0xFFFEF3C7)),
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Quizzia',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black26)],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Transform.rotate(
                              angle: math.sin(_pulseController.value * 2 * math.pi) * 0.2,
                              child: const Icon(Icons.emoji_events, size: 32, color: Color(0xFFFDE047)),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Card principal
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 384),
                  child: Card(
                    elevation: 24,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFFDE047), width: 3),
                    ),
                    color: Colors.white.withOpacity(0.95),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Ícones flutuantes centralizados no card
                          SizedBox(
                            height: 80,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final cardWidth = constraints.maxWidth;
                                return Stack(
                                  children: _gameIcons.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    IconData icon = entry.value;
                                    return AnimatedBuilder(
                                      animation: _floatingController,
                                      builder: (context, child) {
                                        final progress = (_floatingController.value + index * 0.15) % 1.0;
                                        final yOffset = -progress * 100;
                                        final opacity = progress < 0.8 ? 1.0 : (1.0 - progress) * 5;
                                        final scale = progress < 0.1
                                            ? progress * 10
                                            : (progress > 0.9 ? (1.0 - progress) * 10 : 1.0);
                                        return Positioned(
                                          left: cardWidth * 0.5 - 16 + math.sin(index) * 30,
                                          top: 80 + yOffset,
                                          child: Transform.scale(
                                            scale: scale,
                                            child: Opacity(
                                              opacity: opacity.clamp(0.0, 1.0),
                                              child: Icon(icon, size: 32, color: const Color(0xFF7C3AED)),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            'Gerando Seu Quiz!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF581C87),
                            ),
                          ),

                          const SizedBox(height: 24),
                          // Barra de progresso animada
                          Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDDD6FE),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFC4B5FD), width: 2),
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _progressAnimation,
                                builder: (context, child) {
                                  return Container(
                                    width: MediaQuery.of(context).size.width * 0.6 * _progressAnimation.value,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFACC15), Color(0xFFEAB308)],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                // Exibe mensagem de carregamento atual fora do card
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    _loadingMessages[_currentMessageIndex],
                    key: ValueKey(_currentMessageIndex),
                    style: const TextStyle(
                      color: Color(0xFFFEF3C7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
