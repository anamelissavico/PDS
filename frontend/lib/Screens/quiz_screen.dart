import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RespostaUsuario {
  final int perguntaId;
  final String alternativaEscolhida;

  RespostaUsuario({required this.perguntaId, required this.alternativaEscolhida});

  Map<String, dynamic> toJson() => {
    'perguntaId': perguntaId,
    'alternativaEscolhida': alternativaEscolhida,
  };
}

class AvaliacaoQuizzRequest {
  final int userId;
  final int quizzId;
  final List<RespostaUsuario> respostas;

  AvaliacaoQuizzRequest({
    required this.userId,
    required this.quizzId,
    required this.respostas,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'quizzId': quizzId,
    'respostas': respostas.map((r) => r.toJson()).toList(),
  };
}

class QuizScreen extends StatefulWidget {
  final int quizzId;

  const QuizScreen({super.key, required this.quizzId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<dynamic> _perguntas = [];
  int _currentIndex = 0;
  bool _respostaSelecionada = false;
  String _respostaAtual = '';
  List<RespostaUsuario> respostasUsuario = [];
  bool _showFeedback = false;
  int _timeLeft = 3;
  bool _isProcessing = false;

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _carregarPerguntas();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _carregarPerguntas() async {
    setState(() => _isLoading = true);

    try {
      final perguntas = await ApiService.obterPerguntas(widget.quizzId);
      setState(() {
        _perguntas = perguntas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar quiz: $e')),
      );
    }
  }

  void _selecionarResposta(String alternativa) {
    if (_respostaSelecionada || _isProcessing) return;

    setState(() {
      _respostaSelecionada = true;
      _respostaAtual = alternativa;
      _isProcessing = true;
    });

    final pergunta = _perguntas[_currentIndex];
    respostasUsuario.add(
      RespostaUsuario(perguntaId: pergunta['id'], alternativaEscolhida: alternativa),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        _showFeedback = true;
        _timeLeft = 3;
        _isProcessing = false;
      });
      _startTimer();
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_timeLeft > 1) {
        setState(() => _timeLeft--);
        _startTimer();
      } else {
        _proximaPergunta();
      }
    });
  }

  void _proximaPergunta() {
    if (_currentIndex < _perguntas.length - 1) {
      setState(() {
        _currentIndex++;
        _respostaSelecionada = false;
        _respostaAtual = '';
        _showFeedback = false;
        _timeLeft = 3;
      });
    } else {
      _enviarRespostas();
    }
  }

  Future<void> _enviarRespostas() async {
    final avaliacao = AvaliacaoQuizzRequest(
      userId: 1, // Substitua pelo ID real do usuário
      quizzId: widget.quizzId,
      respostas: respostasUsuario,
    );

    try {
      final resultado = await ApiService.avaliarQuizz(avaliacao.toJson());
      final pontos = resultado['pontos'];
      final pontosTotais = resultado['pontosTotaisUsuario'];

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Quiz finalizado!'),
          content: Text('Você ganhou $pontos pontos!\nTotal: $pontosTotais'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar respostas: $e')),
      );
    }
  }

  Color _getCardColor(String letra) {
    if (!_respostaSelecionada) return Color(0xFF581C87).withOpacity(0.0);
    final correta = _perguntas[_currentIndex]['respostaCorreta'];
    if (letra == correta) return Colors.green.shade500;
    if (_respostaAtual == letra && letra != correta) return Colors.red.shade500;
    return Colors.white.withOpacity(0.1);
  }

  Color _getCardBorderColor(String letra) {
    if (!_respostaSelecionada) return Colors.white.withOpacity(0.3);
    final correta = _perguntas[_currentIndex]['respostaCorreta'];
    if (letra == correta) return Colors.green.shade400;
    if (_respostaAtual == letra && letra != correta) return Colors.red.shade400;
    return Colors.white.withOpacity(0.2);
  }

  Widget? _getCardIcon(String letra) {
    if (!_showFeedback) return null;
    final correta = _perguntas[_currentIndex]['respostaCorreta'];
    if (letra == correta) return const Icon(Icons.check_circle, color: Colors.white, size: 24);
    if (_respostaAtual == letra && letra != correta) return const Icon(Icons.cancel, color: Colors.white, size: 24);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFFEAB308)],
            ),
          ),
          child: const Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    if (_perguntas.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Nenhuma pergunta disponível.')),
      );
    }

    final pergunta = _perguntas[_currentIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF6D28D9), Color(0xFFEAB308)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.home, color: Colors.white, size: 20),
                      ),
                    ),
                    Text(
                      'Pergunta ${_currentIndex + 1}/${_perguntas.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${respostasUsuario.length * 10}pts',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pergunta
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCD34D), width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Text(
                    pergunta['perguntaTexto'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF581C87)),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Alternativas
                Expanded(
                  child: ListView(
                    children: ['A', 'B', 'C', 'D'].map((letra) {
                      final textoAlternativa = pergunta['alternativa$letra'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GestureDetector(
                          onTap: _respostaSelecionada ? null : () => _selecionarResposta(letra),
                          onTapDown: (_) => _scaleController.forward(),
                          onTapUp: (_) => _scaleController.reverse(),
                          onTapCancel: () => _scaleController.reverse(),
                          child: AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _getCardColor(letra),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _getCardBorderColor(letra), width: 2),
                                    boxShadow: [BoxShadow(color: _getCardColor(letra).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                                        ),
                                        child: Center(
                                          child: Text(
                                            letra,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          textoAlternativa,
                                          style: TextStyle(
                                            color: _respostaSelecionada && _getCardIcon(letra) == null
                                                ? Colors.white.withOpacity(0.7)
                                                : Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      AnimatedScale(
                                        scale: _getCardIcon(letra) != null ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        child: _getCardIcon(letra) ?? const SizedBox(),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Botão Pular Pergunta
                if (!_respostaSelecionada && _currentIndex < _perguntas.length - 1) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6), // Roxo mais claro
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        setState(() {
                          // Move a pergunta atual para o final da lista
                          final perguntaPulada = _perguntas.removeAt(_currentIndex);
                          _perguntas.add(perguntaPulada);

                          // Reseta estado para a próxima pergunta
                          _respostaSelecionada = false;
                          _respostaAtual = '';
                          _showFeedback = false;
                          _timeLeft = 3;
                        });
                      },
                      child: const Text(
                        'Pular Pergunta',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],


                // Justificativa
                if (_respostaSelecionada && pergunta['justificativa'] != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Color(0xFF581C87), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Explicação:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF581C87),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pergunta['justificativa'] ?? '',
                          style: const TextStyle(color: Color(0xFF6D28D9), fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
