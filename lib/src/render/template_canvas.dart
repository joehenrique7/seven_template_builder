import 'package:flutter/widgets.dart';

import '../models/dynamic_field.dart';
import '../models/template_element.dart';
import '../models/template_spec.dart';
import 'template_element_view.dart';

/// Renderer **puro** (sem interação) de um [TemplateSpec]: desenha o fundo e os
/// elementos posicionados. Serve para o preview e para a rasterização do banner
/// final (envolto em [RepaintBoundary]).
///
/// O widget preenche o espaço disponível mantendo a proporção do canvas quando
/// [fit] é true (padrão). Passe [backgroundImage] quando o fundo for imagem.
class TemplateCanvas extends StatelessWidget {
  const TemplateCanvas({
    super.key,
    required this.spec,
    this.resolver,
    this.fontFamilyResolver,
    this.backgroundImage,
    this.fit = true,
  });

  final TemplateSpec spec;
  final DynamicFieldResolver? resolver;
  final FontFamilyResolver? fontFamilyResolver;

  /// Imagem de fundo já resolvida pelo host (NetworkImage/FileImage/...).
  final ImageProvider? backgroundImage;

  /// Se true, mantém a proporção do canvas dentro do espaço disponível.
  final bool fit;

  @override
  Widget build(BuildContext context) {
    final canvas = LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return SizedBox.fromSize(
          size: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _background(),
              ...spec.orderedElements.map((el) => _positioned(el, size)),
            ],
          ),
        );
      },
    );

    if (!fit) return canvas;

    return AspectRatio(aspectRatio: spec.aspectRatio, child: canvas);
  }

  Widget _background() {
    if (spec.backgroundType == TemplateBackgroundType.image && backgroundImage != null) {
      return Image(image: backgroundImage!, fit: BoxFit.cover);
    }
    return ColoredBox(color: spec.backgroundColor);
  }

  /// Posiciona o elemento pelo centro (fracionário) usando [Align], aplicando
  /// rotação e opacidade. O conteúdo se auto-dimensiona.
  Widget _positioned(TemplateElement el, Size canvasSize) {
    return Align(
      alignment: Alignment(el.position.dx * 2 - 1, el.position.dy * 2 - 1),
      child: Opacity(
        opacity: el.opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: el.rotation,
          child: TemplateElementView(
            element: el,
            canvasSize: canvasSize,
            resolver: resolver,
            fontFamilyResolver: fontFamilyResolver,
          ),
        ),
      ),
    );
  }
}
