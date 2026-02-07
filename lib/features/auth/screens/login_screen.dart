import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/config/license_config.dart';
import '../../../core/services/admin_auth_service.dart';
import '../widgets/terms_dialog.dart';

/// Tela de Login e Cadastro (Supabase Auth). Após sucesso, vai para a verificação de licença.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false; // Estado do checkbox
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTerms() {
    showDialog(
      context: context,
      builder: (context) => const TermsDialog(),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _errorMessage = null;
      _loading = true;
    });

    if (!_acceptedTerms) {
      setState(() {
        _errorMessage = 'Você precisa aceitar os Termos de Uso.';
        _loading = false;
      });
      return;
    }

    if (!LicenseConfig.isConfigured) {
      setState(() {
        _errorMessage = 'Supabase não configurado. Adicione SUPABASE_URL e SUPABASE_ANON_KEY no arquivo .env na raiz do projeto.';
        _loading = false;
      });
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Preencha e-mail e senha.';
        _loading = false;
      });
      return;
    }
    try {
      if (_isSignUp) {
        await AdminAuthService.instance.signUp(email, password);
      } else {
        await AdminAuthService.instance.signIn(email, password);
      }
      if (!mounted) return;
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRouter.auth);
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message.isNotEmpty ? e.message : 'Erro ao ${_isSignUp ? 'cadastrar' : 'entrar'}.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    final primary = AppTheme.getPrimaryColor(context);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.tv_rounded, size: 64, color: primary),
                  const SizedBox(height: 16),
                  Text(
                    'Luminoria',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSignUp ? 'Criar conta' : 'Entre na sua conta',
                    style: TextStyle(color: textSecondary, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'seu@email.com',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe o e-mail.';
                      return null;
                    },
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Informe a senha.';
                      if (_isSignUp && v.length < 6) return 'Mínimo 6 caracteres.';
                      return null;
                    },
                    onChanged: (_) => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 16),
                  
                  // CHECKBOX DE TERMOS
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        activeColor: primary,
                        onChanged: (val) {
                          setState(() {
                            _acceptedTerms = val ?? false;
                            _errorMessage = null;
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showTerms,
                          child: RichText(
                            text: TextSpan(
                              text: 'Li e aceito os ',
                              style: TextStyle(color: textSecondary, fontSize: 14),
                              children: [
                                TextSpan(
                                  text: 'Termos de Uso e Política Legal',
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: AppTheme.errorColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : () => _submit(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: _loading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_isSignUp ? 'Cadastrar' : 'Entrar'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _errorMessage = null;
                              _acceptedTerms = false; // Reseta ao trocar
                            }),
                    child: Text(
                      _isSignUp ? 'Já tem conta? Entrar' : 'Não tem conta? Cadastrar',
                      style: TextStyle(color: primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
