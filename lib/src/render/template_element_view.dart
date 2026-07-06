import 'package:flutter/widgets.dart';

import '../models/dynamic_field.dart';
import '../models/template_element.dart';

/// Renderiza o **conteúdo** de um elemento (sem posição/rotação/opacidade, que
/// são aplicados por quem posiciona). O tamanho da fonte é derivado da altura do
/// canvas para ficar independente de resolução.
class TemplateElementView extends StatelessWidget {
  const TemplateElementView({
    super.key,
    required this.element,
    required this.canvasSize,
    this.resolver,
    this.fontFamilyResolver,
  });

  final TemplateElement element;
  final Size canvasSize;
  final DynamicFieldResolver? resolver;
  final FontFamilyResolver? fontFamilyResolver;

  @override
  Widget build(BuildContext context) {
    final el = element;
    if (el is TextualElement) {
      final text = el.resolveText(resolver);
      final fontSize = el.style.fontSizeFactor * canvasSize.height;

      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: canvasSize.width * 0.95),
        child: Text(
          text.isEmpty ? ' ' : text,
          textAlign: el.style.align,
          style: TextStyle(
            color: el.style.color,
            fontSize: fontSize <= 0 ? 1 : fontSize,
            fontWeight: el.style.flutterWeight,
            fontFamily: fontFamilyResolver?.call(el.style.fontFamily) ?? el.style.fontFamily,
            height: 1.1,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
