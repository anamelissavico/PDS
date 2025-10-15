import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizzfront/Screens/loading_screen.dart';
import 'package:quizzfront/Screens/quiz_screen.dart';
import '../services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _temaController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();

  String _nivelEscolar = 'Ensino Fundamental';
  String _dificuldade = 'Fácil';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _temaController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _gerarQuizz() async {
    if (!_formKey.currentState!.validate()) return;

    final tema = _temaController.text.trim();
    final numero = int.tryParse(_numeroController.text.trim()) ?? 0;
    if (numero <= 0) {
      _showSnack('Número de perguntas deve ser maior que zero.');
      return;
    }

    final payload = {
      "NivelEscolar": _nivelEscolar,
      "Tema": tema,
      "NumeroPerguntas": numero,
      "Dificuldade": _dificuldade
    };

    // Abrir a tela de Loading e passar a função onComplete
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizLoadingScreen(
          onComplete: () async {
            try {
              final response = await ApiService.gerarQuizz(payload);
              final quizzId = response['quizzId'];
              if (quizzId == null) throw 'ID do quiz não retornado da API';

              // Navegar para a tela do quiz
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(quizzId: quizzId),
                ),
              );
            } catch (e) {
              _showSnack('⚠️ Erro ao gerar quiz: $e');
              Navigator.pop(context); // Fecha a tela de loading
            }
          },
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _navegarHistorico() => print('Navegando para Histórico');
  void _navegarGrupos() => print('Navegando para Grupos');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF820AD1), Color(0xFF6D28D9), Color(0xFFEAB308)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildMainForm(),
                const SizedBox(height: 24),
                _buildNavigationButtons(),
                const SizedBox(height: 16),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.sports_esports, size: 40, color: Color(0xFFFDE047)),
                SizedBox(width: 8),
                Text(
                  'Quizzia',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black26)],
                  ),
                ),
              ],
            ),
            Positioned(
              top: -4,
              right: 60,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: const Icon(Icons.emoji_events, size: 24, color: Color(0xFFFDE047)),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Teste seus conhecimentos e divirta-se!',
            style: TextStyle(fontSize: 18, color: Color(0xFFFEF3C7)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildMainForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFFDE047), width: 3),
        ),
        color: Colors.white.withOpacity(0.95),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  'Configure Seu Quiz',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF581C87)),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _nivelEscolar,
                  decoration: const InputDecoration(labelText: 'Nível escolar'),
                  items: const [
                    DropdownMenuItem(value: 'Ensino Fundamental', child: Text('Ensino Fundamental')),
                    DropdownMenuItem(value: 'Ensino Médio', child: Text('Ensino Médio')),
                    DropdownMenuItem(value: 'Ensino Superior', child: Text('Ensino Superior')),
                  ],
                  onChanged: (v) => setState(() => _nivelEscolar = v ?? _nivelEscolar),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _temaController,
                  decoration: const InputDecoration(labelText: 'Tema da pergunta', hintText: 'Ex.: Tecnologia, Matemática'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o tema' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _numeroController,
                  decoration: const InputDecoration(labelText: 'Número de perguntas', hintText: 'Ex.: 4'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Informe a quantidade';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Número inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _dificuldade,
                  decoration: const InputDecoration(labelText: 'Nível de dificuldade'),
                  items: const [
                    DropdownMenuItem(value: 'Fácil', child: Text('Fácil')),
                    DropdownMenuItem(value: 'Média', child: Text('Média')),
                    DropdownMenuItem(value: 'Difícil', child: Text('Difícil')),
                  ],
                  onChanged: (v) => setState(() => _dificuldade = v ?? _dificuldade),
                ),
                const SizedBox(height: 24),
                _buildGenerateButton(), // <<<<< botão envia para a loading_screen
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFBBF24), Color(0xFFEAB308)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE047), width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 4), blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _gerarQuizz, // <<<<< aqui encaminha para loading_screen
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flash_on, size: 20, color: Color(0xFF581C87)),
                SizedBox(width: 8),
                Text(
                  'Gerar Quiz Agora!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF581C87)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildNavButton(
            title: 'Histórico',
            subtitle: 'Veja seus resultados',
            icon: Icons.history,
            gradient: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            iconBgColor: Color(0xFFFDE047),
            iconColor: Color(0xFF6D28D9),
            borderColor: Color(0xFFFDE047),
            onTap: _navegarHistorico,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildNavButton(
            title: 'Grupos',
            subtitle: 'Jogue com amigos',
            icon: Icons.group,
            gradient: [Color(0xFFFBBF24), Color(0xFFD97706)],
            iconBgColor: Color(0xFF820AD1),
            iconColor: Color(0xFFFDE047),
            borderColor: Color(0xFFDDD6FE),
            onTap: _navegarGrupos,
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required Color iconBgColor,
    required Color iconColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 3),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                      ],
                    ),
                    child: Icon(icon, size: 32, color: iconColor),
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text(
        '🎮 Divirta-se aprendendo com Quizzia! 🏆',
        style: TextStyle(fontSize: 14, color: Color(0xFFFEF3C7)),
        textAlign: TextAlign.center,
      ),
    );
  }
}
