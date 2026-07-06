import 'dart:ui';

import 'template_element.dart';

/// Tipo de fundo do template.
enum TemplateBackgroundType { color, image }

/// Descrição completa e serializável de um template: dimensões do canvas, fundo
/// (cor ou imagem) e a lista de elementos.
///
/// A imagem de fundo é referenciada por [backgroundImageUrl] (URL de rede ou
/// caminho de arquivo). O motor **não** carrega a imagem sozinho — quem renderiza
/// fornece o `ImageProvider` correspondente (mantém o package sem dependência de
/// rede/cache).
class TemplateSpec {
  const TemplateSpec({
    this.canvasWidth = 1280,
    this.canvasHeight = 720,
    this.backgroundType = TemplateBackgroundType.color,
    this.backgroundColorValue = 0xFF101828,
    this.backgroundImageUrl,
    this.elements = const [],
  });

  final int canvasWidth;
  final int canvasHeight;
  final TemplateBackgroundType backgroundType;
  final int backgroundColorValue;
  final String? backgroundImageUrl;
  final List<TemplateElement> elements;

  double get aspectRatio => canvasWidth / canvasHeight;

  Color get backgroundColor => Color(backgroundColorValue);

  /// Elementos ordenados por z-index (do fundo para a frente).
  List<TemplateElement> get orderedElements {
    final list = [...elements];
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }

  TemplateSpec copyWith({
    int? canvasWidth,
    int? canvasHeight,
    TemplateBackgroundType? backgroundType,
    int? backgroundColorValue,
    Object? backgroundImageUrl = _noValue,
    List<TemplateElement>? elements,
  }) {
    return TemplateSpec(
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      backgroundImageUrl: identical(backgroundImageUrl, _noValue) ? this.backgroundImageUrl : backgroundImageUrl as String?,
      elements: elements ?? this.elements,
    );
  }

  Map<String, dynamic> toJson() => {
        'canvasWidth': canvasWidth,
        'canvasHeight': canvasHeight,
        'backgroundType': backgroundType.name,
        'backgroundColorValue': backgroundColorValue,
        'backgroundImageUrl': backgroundImageUrl,
        'elements': elements.map((e) => e.toJson()).toList(),
      };

  factory TemplateSpec.fromJson(Map<String, dynamic> json) => TemplateSpec(
        canvasWidth: (json['canvasWidth'] as num?)?.toInt() ?? 1280,
        canvasHeight: (json['canvasHeight'] as num?)?.toInt() ?? 720,
        backgroundType: TemplateBackgroundType.values.firstWhere(
          (t) => t.name == json['backgroundType'],
          orElse: () => TemplateBackgroundType.color,
        ),
        backgroundColorValue: (json['backgroundColorValue'] as num?)?.toInt() ?? 0xFF101828,
        backgroundImageUrl: json['backgroundImageUrl'] as String?,
        elements: ((json['elements'] as List?) ?? const [])
            .map((e) => TemplateElement.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

const Object _noValue = Object();
