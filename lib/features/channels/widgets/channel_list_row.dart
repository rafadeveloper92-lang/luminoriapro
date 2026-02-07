import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/models/channel.dart';
import '../../../core/platform/platform_detector.dart';
import '../../../core/widgets/tv_focusable.dart';
import '../../../core/widgets/channel_logo_widget.dart';

/// Linha compacta para lista de canais (número, logo, nome, programa) — estilo IPTV Smarters.
/// Reduz travamento ao substituir grid de miniaturas por lista com lazy build.
class ChannelListRow extends StatelessWidget {
  final Channel channel;
  final int index; // 1-based para exibição (número do canal)
  final String? currentProgram;
  final bool isSelected;
  final bool isFavorite;
  final bool isUnavailable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final FocusNode? focusNode;
  final VoidCallback? onLeft;
  final VoidCallback? onUp;
  final VoidCallback? onDown;
  final VoidCallback? onFocused;

  const ChannelListRow({
    super.key,
    required this.channel,
    required this.index,
    this.currentProgram,
    this.isSelected = false,
    this.isFavorite = false,
    this.isUnavailable = false,
    this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.focusNode,
    this.onLeft,
    this.onUp,
    this.onDown,
    this.onFocused,
  });

  @override
  Widget build(BuildContext context) {
    final isTV = PlatformDetector.isTV;
    final subtitle = currentProgram ?? 'Nenhum programa encontrado';

    const selectedColor = Color(0xFF1A3A3A);
    final content = Material(
      color: isTV ? Colors.transparent : (isSelected ? selectedColor : Colors.transparent),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Número do canal
              SizedBox(
                width: 44,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.getTextSecondary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Logo pequeno
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 48,
                  height: 36,
                  child: channel.logoUrl != null && channel.logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: channel.logoUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, __) => _placeholder(context),
                          errorWidget: (_, __, ___) => _placeholder(context),
                        )
                      : ChannelLogoWidget(channel: channel, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 12),
              // Nome + programa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      channel.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.getTextPrimary(context),
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : AppTheme.getTextMuted(context),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isFavorite)
                Icon(Icons.favorite, color: Colors.red.shade400, size: 20),
              if (isUnavailable)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Off',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (isTV) {
      return TVFocusable(
        focusNode: focusNode,
        onSelect: onTap,
        onLeft: onLeft,
        onUp: onUp,
        onDown: onDown,
        onFocus: onFocused,
        focusScale: 1.0,
        showFocusBorder: false,
        builder: (context, isFocused, child) {
          final selected = isSelected || isFocused;
          return Container(
            decoration: BoxDecoration(
              color: selected ? selectedColor : null,
              border: Border(
                left: BorderSide(
                  color: selected ? AppTheme.getPrimaryColor(context) : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
            child: child,
          );
        },
        child: content,
      );
    }

    return content;
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: AppTheme.getCardColor(context),
      child: Icon(Icons.live_tv, color: AppTheme.getTextMuted(context), size: 20),
    );
  }
}
