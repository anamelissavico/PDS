class RegisterRequest {
  final String email;
  final String senha;

  RegisterRequest({
    required this.email,
    required this.senha,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'senha': senha,
    };
  }
}