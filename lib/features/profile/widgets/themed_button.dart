import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/profile_theme.dart';
import '../providers/theme_provider.dart';

/// Botão que aplica estilo do tema atual do perfil.
class ThemedButton extends StatelessWidget {
  const ThemedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ThemedButtonVariant.primary,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final ThemedButtonVariant variant;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final theme = themeProvider.currentTheme;
        
        if (theme == null) {
          // Sem tema: usar estilo padrão
          return ElevatedButton(
            onPressed: onPressed,
            style: style,
            child: child,
          );
        }

        // Aplicar estilo do tema
        final primaryColor = theme.primaryColorInt != null
            ? Color(theme.primaryColorInt!)
            : Theme.of(context).colorScheme.primary;
        
        final secondaryColor = theme.secondaryColorInt != null
            ? Color(theme.secondaryColorInt!)
            : Theme.of(context).colorScheme.secondary;

        ButtonStyle themedStyle;
        
        switch (variant) {
          case ThemedButtonVariant.primary:
            themedStyle = ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: theme.buttonStyle?['glow'] == true ? 8 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  (theme.buttonStyle?['border_radius'] as num?)?.toDouble() ?? 12,
                ),
              ),
            );
            break;
          case ThemedButtonVariant.secondary:
            themedStyle = ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              elevation: theme.buttonStyle?['glow'] == true ? 6 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  (theme.buttonStyle?['border_radius'] as num?)?.toDouble() ?? 12,
                ),
              ),
            );
            break;
          case ThemedButtonVariant.outline:
            themedStyle = OutlinedButton.styleFrom(
              foregroundColor: primaryColor,
              side: BorderSide(color: primaryColor, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  (theme.buttonStyle?['border_radius'] as num?)?.toDouble() ?? 12,
                ),
              ),
            );
            break;
        }

        // Aplicar estilo customizado se fornecido
        if (style != null) {
          themedStyle = style!.merge(themedStyle);
        }

        // Aplicar efeito neon se configurado
        if (theme.buttonStyle?['type'] == 'neon' && theme.buttonStyle?['glow'] == true) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                (theme.buttonStyle?['border_radius'] as num?)?.toDouble() ?? 12,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onPressed,
              style: themedStyle,
              child: child,
            ),
          );
        }

        return ElevatedButton(
          onPressed: onPressed,
          style: themedStyle,
          child: child,
        );
      },
    );
  }
}

enum ThemedButtonVariant {
  primary,
  secondary,
  outline,
}
