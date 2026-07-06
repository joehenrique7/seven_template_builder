import 'dart:ui';

import 'dynamic_field.dart';
import 'text_style_spec.dart';

/// Elemento posicionável do template.
///
/// Toda a geometria é **fracionária** (0..1) e relativa ao canvas, então o
/// template é independente de resolução:
/// - [position]: centro do elemento (fração da largura/altura).
/// - [rotation]: em radianos.
/// - [opacity]: 0..1.
/// - [zIndex]: ordem de empilhamento (maior fica na frente).
abstract class TemplateElement {
  const TemplateElement({
    required this.id,
    required this.position,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.zIndex = 0,
  });

  final String id;
  final Offset position;
  final double rotation;
  final double opacity;
  final int zIndex;

  String get type;

  /// Cópia com nova geometria/ordem (mantém o tipo e os atributos próprios).
  TemplateElement copyBase({
    Offset? position,
    double? rotation,
    double? opacity,
    int? zIndex,
  });

  Map<String, dynamic> toJson();

  Map<String, dynamic> baseJson() => {
        'id': id,
        'type': type,
        'x': position.dx,
        'y': position.dy,
        'rotation': rotation,
        'opacity': opacity,
        'zIndex': zIndex,
      };

  static TemplateElement fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'text':
        return TextElement.fromJson(json);
      case 'dynamicText':
        return DynamicTextElement.fromJson(json);
      default:
        throw ArgumentError('Tipo de elemento desconhecido: ${json['type']}');
    }
  }

  static Offset _positionFromJson(Map<String, dynamic> json) =>
      Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

/// Base dos elementos que exibem texto (texto fixo ou campo dinâmico).
abstract class TextualElement extends TemplateElement {
  const TextualElement({
    required super.id,
    required super.position,
    super.rotation,
    super.opacity,
    super.zIndex,
    this.style = const TextStyleSpec(),
  });

  final TextStyleSpec style;

  /// Texto a exibir. Para campo dinâmico, resolve via [resolver] com fallback.
  String resolveText(DynamicFieldResolver? resolver);

  TextualElement copyStyle(TextStyleSpec style);
}

// ---------------------------------------------------------------------------

/// Texto fixo digitado pelo autor do template.
class TextElement extends TextualElement {
  const TextElement({
    required super.id,
    required super.position,
    super.rotation,
    super.opacity,
    super.zIndex,
    super.style,
    required this.text,
  });

  final String text;

  @override
  String get type => 'text';

  @override
  String resolveText(DynamicFieldResolver? resolver) => text;

  @override
  TextElement copyBase({Offset? position, double? rotation, double? opacity, int? zIndex}) => TextElement(
        id: id,
        position: position ?? this.position,
        rotation: rotation ?? this.rotation,
        opacity: opacity ?? this.opacity,
        zIndex: zIndex ?? this.zIndex,
        style: style,
        text: text,
      );

  @override
  TextElement copyStyle(TextStyleSpec style) => TextElement(
        id: id,
        position: position,
        rotation: rotation,
        opacity: opacity,
        zIndex: zIndex,
        style: style,
        text: text,
      );

  TextElement copyWith({String? text}) => TextElement(
        id: id,
        position: position,
        rotation: rotation,
        opacity: opacity,
        zIndex: zIndex,
        style: style,
        text: text ?? this.text,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        'style': style.toJson(),
        'text': text,
      };

  factory TextElement.fromJson(Map<String, dynamic> json) => TextElement(
        id: json['id'] as String,
        position: TemplateElement._positionFromJson(json),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
        style: json['style'] is Map ? TextStyleSpec.fromJson(Map<String, dynamic>.from(json['style'] as Map)) : const TextStyleSpec(),
        text: (json['text'] as String?) ?? '',
      );
}

// ---------------------------------------------------------------------------

/// Campo dinâmico: exibe um dado do contexto (ex.: nome do evento), resolvido
/// no momento da renderização. Guarda a [field] (chave) e um [placeholder]
/// mostrado no editor/quando o dado está ausente.
class DynamicTextElement extends TextualElement {
  const DynamicTextElement({
    required super.id,
    required super.position,
    super.rotation,
    super.opacity,
    super.zIndex,
    super.style,
    required this.field,
    this.placeholder = '',
  });

  final String field;
  final String placeholder;

  @override
  String get type => 'dynamicText';

  @override
  String resolveText(DynamicFieldResolver? resolver) {
    final value = resolver?.call(field);
    if (value != null && value.isNotEmpty) return value;
    return placeholder;
  }

  @override
  DynamicTextElement copyBase({Offset? position, double? rotation, double? opacity, int? zIndex}) => DynamicTextElement(
        id: id,
        position: position ?? this.position,
        rotation: rotation ?? this.rotation,
        opacity: opacity ?? this.opacity,
        zIndex: zIndex ?? this.zIndex,
        style: style,
        field: field,
        placeholder: placeholder,
      );

  @override
  DynamicTextElement copyStyle(TextStyleSpec style) => DynamicTextElement(
        id: id,
        position: position,
        rotation: rotation,
        opacity: opacity,
        zIndex: zIndex,
        style: style,
        field: field,
        placeholder: placeholder,
      );

  @override
  Map<String, dynamic> toJson() => {
        ...baseJson(),
        'style': style.toJson(),
        'field': field,
        'placeholder': placeholder,
      };

  factory DynamicTextElement.fromJson(Map<String, dynamic> json) => DynamicTextElement(
        id: json['id'] as String,
        position: TemplateElement._positionFromJson(json),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
        style: json['style'] is Map ? TextStyleSpec.fromJson(Map<String, dynamic>.from(json['style'] as Map)) : const TextStyleSpec(),
        field: (json['field'] as String?) ?? '',
        placeholder: (json['placeholder'] as String?) ?? '',
      );
}
