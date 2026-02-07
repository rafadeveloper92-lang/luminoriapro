import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsDialog extends StatelessWidget {
  const TermsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text('Termos de Uso e Política Legal', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '1. NATUREZA DO SERVIÇO\n'
                'O aplicativo LUMINORA é estritamente um reprodutor de mídia (Media Player). O aplicativo NÃO fornece, não inclui e não vende nenhum tipo de conteúdo, playlist, canais, filmes ou transmissões.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '2. RESPONSABILIDADE DO USUÁRIO\n'
                'O usuário é o único e exclusivo responsável pelo conteúdo que adiciona ao aplicativo. Ao inserir uma lista de reprodução (M3U, Xtream Codes, etc.), você declara que possui os direitos de acesso a esse conteúdo.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '3. DIREITOS AUTORAIS (COPYRIGHT)\n'
                'Nós condenamos a pirataria. O LUMINORA não tem vínculo com nenhum provedor de terceiros. Se você não possui permissão para acessar determinado conteúdo, não deve utilizá-lo neste aplicativo. Não nos responsabilizamos pelo uso indevido do software.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '4. COLETA DE DADOS\n'
                'Para o funcionamento de recursos sociais (Amigos, Ranking, Perfil), coletamos dados básicos como Nome, E-mail e histórico de visualização vinculado ao seu perfil. Esses dados são armazenados de forma segura e não são vendidos a terceiros.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                '5. ACEITE\n'
                'Ao criar uma conta ou fazer login, você concorda irrevogavelmente com estes termos e isenta os desenvolvedores de qualquer responsabilidade sobre o conteúdo reproduzido.',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('FECHAR', style: TextStyle(color: AppTheme.primaryColor)),
        ),
      ],
    );
  }
}
