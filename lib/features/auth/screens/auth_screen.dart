import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/navigation/app_router.dart';
import '../../../core/config/license_config.dart';
import '../../../core/services/license_service.dart';
import '../../../core/services/admin_auth_service.dart';
import '../../../core/services/stripe_checkout_service.dart';

/// Verifica licença (por user_id ou device_id). Se ativa → Home; senão → tela de bloqueio com Assinar + Explorar app.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with WidgetsBindingObserver {
  bool _loading = true;
  LicenseCheckResult? _result;
  bool _checkoutLoading = false;
  bool _vipDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLicense();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLicense();
    }
  }

  Future<void> _checkLicense() async {
    if (!AdminAuthService.instance.isSignedIn) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
      return;
    }
    final result = await LicenseService.instance.checkLicense();
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
    });
    if (result.isActive) {
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    }
  }

  Future<void> _openStripeCheckout() async {
    setState(() => _checkoutLoading = true);
    try {
      final url = await StripeCheckoutService.instance.getCheckoutUrl();
      if (!mounted) return;
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir o checkout.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _checkoutLoading = false);
    }
  }

  void _showVipWelcomeDialog() {
    if (!mounted || !EnvConfig.isStripeConfigured) return;
    final primaryColor = AppTheme.getPrimaryColor(context);
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: primaryColor, size: 32),
            const SizedBox(width: 12),
            Text(
              'Acesso VIP',
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo ao Luminoria! Ative seu acesso VIP por apenas 2,99€ e desbloqueie o melhor do streaming.',
                style: TextStyle(color: textPrimary, fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Canais ao vivo, filmes, séries e muito mais.',
                        style: TextStyle(color: textSecondary, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Depois', style: TextStyle(color: textSecondary)),
          ),
          FilledButton.icon(
            onPressed: _checkoutLoading
                ? null
                : () async {
                    Navigator.of(ctx).pop();
                    await _openStripeCheckout();
                  },
            icon: _checkoutLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.payment, size: 20),
            label: Text(_checkoutLoading ? 'Abrindo...' : 'Assinar Agora'),
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppTheme.getPrimaryColor(context);
    final bgColor = AppTheme.getBackgroundColor(context);
    final textPrimary = AppTheme.getTextPrimary(context);
    final textSecondary = AppTheme.getTextSecondary(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Verificando licença...',
                style: TextStyle(color: textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Mostra o pop-up VIP na primeira vez que o usuário vê a tela sem licença (Stripe configurado)
    if (EnvConfig.isStripeConfigured && !_vipDialogShown) {
      _vipDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showVipWelcomeDialog();
      });
    }

    // Licença inativa: tela com Assinar + Explorar o app (sem WhatsApp)
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 80, color: primaryColor.withOpacity(0.8)),
                const SizedBox(height: 24),
                Text(
                  'Luminoria',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ative sua assinatura para reproduzir vídeos',
                  style: TextStyle(color: textSecondary, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                if (_result?.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao verificar: ${_result!.error}',
                    style: TextStyle(color: AppTheme.errorColor, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),
                if (EnvConfig.isStripeConfigured)
                  FilledButton.icon(
                    onPressed: _checkoutLoading ? null : _openStripeCheckout,
                    icon: _checkoutLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.payment),
                    label: Text(_checkoutLoading ? 'Abrindo...' : 'Assinar Agora'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.getCardColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Assinaturas: adicione STRIPE_PRICE_ID no .env e faça um novo build.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRouter.home);
                  },
                  icon: const Icon(Icons.explore),
                  label: const Text('Explorar o app'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Você pode navegar pelo app; ao voltar do pagamento, a licença é verificada automaticamente.',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
