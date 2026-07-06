import 'dart:ui';

/// Estilo de um elemento textual do template, serializável e independente do
/// tamanho do canvas.
///
/// O tamanho da fonte é guardado como fração da **altura** do canvas
/// ([fontSizeFactor]); assim a arte fica igual em qualquer resolução de
/// rasterização. Ex.: `0.08` em um canvas de 720px => ~58px.
class TextStyleSpec {
  const TextStyleSpec({
    this.colorValue = 0xFFFFFFFF,
    this.fontSizeFactor = 0.08,
    this.fontFamily,
    this.fontWeight = 400,
    this.align = TextAlign.center,
  });

  /// Cor ARGB (int).
  final int colorValue;

  /// Tamanho da fonte como fração da altura do canvas (0..1).
  final double fontSizeFactor;

  /// Chave da família de fonte (resolvida pelo host). `null` = padrão.
  final String? fontFamily;

  /// Peso (100..900), múltiplos de 100.
  final int fontWeight;

  /// Alinhamento horizontal do texto.
  final TextAlign align;

  Color get color => Color(colorValue);

  FontWeight get flutterWeight {
    final index = (fontWeight ~/ 100 - 1).clamp(0, FontWeight.values.length - 1);
    return FontWeight.values[index];
  }

  TextStyleSpec copyWith({
    int? colorValue,
    double? fontSizeFactor,
    Object? fontFamily = _noValue,
    int? fontWeight,
    TextAlign? align,
  }) {
    return TextStyleSpec(
      colorValue: colorValue ?? this.colorValue,
      fontSizeFactor: fontSizeFactor ?? this.fontSizeFactor,
      fontFamily: identical(fontFamily, _noValue) ? this.fontFamily : fontFamily as String?,
      fontWeight: fontWeight ?? this.fontWeight,
      align: align ?? this.align,
    );
  }

  Map<String, dynamic> toJson() => {
        'colorValue': colorValue,
        'fontSizeFactor': fontSizeFactor,
        'fontFamily': fontFamily,
        'fontWeight': fontWeight,
        'align': align.name,
      };

  factory TextStyleSpec.fromJson(Map<String, dynamic> json) => TextStyleSpec(
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFFFFFFFF,
        fontSizeFactor: (json['fontSizeFactor'] as num?)?.toDouble() ?? 0.08,
        fontFamily: json['fontFamily'] as String?,
        fontWeight: (json['fontWeight'] as num?)?.toInt() ?? 400,
        align: _alignFromName(json['align'] as String?),
      );

  static TextAlign _alignFromName(String? name) {
    return TextAlign.values.firstWhere(
      (a) => a.name == name,
      orElse: () => TextAlign.center,
    );
  }
}

const Object _noValue = Object();
