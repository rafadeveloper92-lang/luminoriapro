/// Tema de perfil: configuração visual completa (capa, cores, botões, música, decorações).
class ProfileTheme {
  ProfileTheme({
    required this.id,
    required this.themeKey,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.backgroundMusicUrl,
    this.primaryColor,
    this.secondaryColor,
    this.buttonStyle,
    this.decorativeElements,
    this.previewImageUrl,
    this.active = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String themeKey;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final String? backgroundMusicUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final Map<String, dynamic>? buttonStyle;
  final Map<String, dynamic>? decorativeElements;
  final String? previewImageUrl;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Converte cor hex para Color do Flutter
  int? get primaryColorInt {
    if (primaryColor == null || primaryColor!.isEmpty) return null;
    try {
      final hex = primaryColor!.replaceFirst('#', '');
      return int.parse(hex, radix: 16) | 0xFF000000;
    } catch (_) {
      return null;
    }
  }

  int? get secondaryColorInt {
    if (secondaryColor == null || secondaryColor!.isEmpty) return null;
    try {
      final hex = secondaryColor!.replaceFirst('#', '');
      return int.parse(hex, radix: 16) | 0xFF000000;
    } catch (_) {
      return null;
    }
  }

  factory ProfileTheme.fromMap(Map<String, dynamic> map) {
    final createdAtStr = map['created_at'] as String?;
    final updatedAtStr = map['updated_at'] as String?;
    
    Map<String, dynamic>? buttonStyleMap;
    if (map['button_style'] != null) {
      if (map['button_style'] is Map) {
        buttonStyleMap = Map<String, dynamic>.from(map['button_style'] as Map);
      } else if (map['button_style'] is String) {
        // Tentar parsear JSON string
        try {
          buttonStyleMap = Map<String, dynamic>.from(
            (map['button_style'] as String).isNotEmpty
                ? {} // Se for string vazia, deixar null
                : {},
          );
        } catch (_) {
          buttonStyleMap = null;
        }
      }
    }

    Map<String, dynamic>? decorativeMap;
    if (map['decorative_elements'] != null) {
      if (map['decorative_elements'] is Map) {
        decorativeMap = Map<String, dynamic>.from(map['decorative_elements'] as Map);
      } else if (map['decorative_elements'] is String) {
        try {
          decorativeMap = Map<String, dynamic>.from(
            (map['decorative_elements'] as String).isNotEmpty
                ? {}
                : {},
          );
        } catch (_) {
          decorativeMap = null;
        }
      }
    }

    return ProfileTheme(
      id: map['id'] as String? ?? '',
      themeKey: map['theme_key'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      coverImageUrl: map['cover_image_url'] as String?,
      backgroundMusicUrl: map['background_music_url'] as String?,
      primaryColor: map['primary_color'] as String?,
      secondaryColor: map['secondary_color'] as String?,
      buttonStyle: buttonStyleMap,
      decorativeElements: decorativeMap,
      previewImageUrl: map['preview_image_url'] as String?,
      active: map['active'] as bool? ?? true,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'theme_key': themeKey,
      'name': name,
      'description': description,
      'cover_image_url': coverImageUrl,
      'background_music_url': backgroundMusicUrl,
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'button_style': buttonStyle,
      'decorative_elements': decorativeElements,
      'preview_image_url': previewImageUrl,
      'active': active,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  ProfileTheme copyWith({
    String? id,
    String? themeKey,
    String? name,
    String? description,
    String? coverImageUrl,
    String? backgroundMusicUrl,
    String? primaryColor,
    String? secondaryColor,
    Map<String, dynamic>? buttonStyle,
    Map<String, dynamic>? decorativeElements,
    String? previewImageUrl,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileTheme(
      id: id ?? this.id,
      themeKey: themeKey ?? this.themeKey,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      backgroundMusicUrl: backgroundMusicUrl ?? this.backgroundMusicUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      decorativeElements: decorativeElements ?? this.decorativeElements,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
