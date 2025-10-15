import 'dart:io';
import 'dart:convert';
import 'package:http/io_client.dart';

class ApiService {
  // Cria um cliente HTTP que ignora certificados inválidos
  static Future<IOClient> _createHttpClient() async {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true; // aceita tudo

    return IOClient(httpClient);
  }

  // POST: gerar o quiz
  static Future<Map<String, dynamic>> gerarQuizz(Map<String, dynamic> payload) async {
    final client = await _createHttpClient();
    //final url = Uri.parse("https://10.0.2.2:7050/api/quizz/gerar");
    final url = Uri.parse("https://192.168.3.6:7050/api/quizz/gerar");

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw HttpException(
          'Erro ${response.statusCode}: ${response.body}', uri: url);
    }
  }

  // GET: obter perguntas de um quiz específico
  static Future<List<dynamic>> obterPerguntas(int quizzId) async {
    final client = await _createHttpClient();
    //final url = Uri.parse("https://10.0.2.2:7050/api/quizz/$quizzId/perguntas");
    final url = Uri.parse("https://192.168.3.6:7050/api/quizz/$quizzId/perguntas");

    final response = await client.get(url);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);
      return data['perguntas'] ?? [];
    } else {
      throw HttpException(
          'Erro ${response.statusCode}: ${response.body}', uri: url);
    }
  }

  // POST: avaliar respostas do usuário
  // ⚠️ Certifique-se de passar payload.toJson() se estiver usando um objeto Dart
  static Future<Map<String, dynamic>> avaliarQuizz(Map<String, dynamic> payload) async {
    final client = await _createHttpClient();
    //final url = Uri.parse("https://10.0.2.2:7050/api/quizz/avaliar");
    final url = Uri.parse("https://192.168.3.6:7050/api/quizz/avaliar");

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload), // payload já deve ser Map<String, dynamic>
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw HttpException(
          'Erro ${response.statusCode}: ${response.body}', uri: url);
    }
  }
}
