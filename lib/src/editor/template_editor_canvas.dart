import 'package:flutter/widgets.dart';

import '../controller/template_editor_controller.dart';
import '../models/dynamic_field.dart';
import '../models/template_element.dart';
import '../models/template_spec.dart';
import '../render/template_element_view.dart';

/// Canvas **interativo** do editor: renderiza o template do
/// [TemplateEditorController] e permite selecionar, arrastar (mover),
/// redimensionar e rotacionar cada elemento diretamente na arte.
///
/// - Toque no elemento: seleciona. Toque no fundo: desmarca.
/// - Arrastar o corpo: move (posição fracionária).
/// - Alça inferior-direita: redimensiona (tamanho da fonte).
/// - Alça superior: rotaciona.
///
/// A UI de propriedades (fonte, cor, peso, opacidade, camadas...) fica a cargo
/// de quem usa o editor, chamando os métodos do controller.
class TemplateEditorCanvas extends StatefulWidget {
  const TemplateEditorCanvas({
    super.key,
    required this.controller,
    this.resolver,
    this.fontFamilyResolver,
    this.backgroundImage,
    this.selectionColor = const Color(0xFFCC5F31),
  });

  final TemplateEditorController controller;
  final DynamicFieldResolver? resolver;
  final FontFamilyResolver? fontFamilyResolver;
  final ImageProvider? backgroundImage;
  final Color selectionColor;

  @override
  State<TemplateEditorCanvas> createState() => _TemplateEditorCanvasState();
}

class _TemplateEditorCanvasState extends State<TemplateEditorCanvas> {
  final GlobalKey _canvasKey = GlobalKey();

  Size _canvasSize = Size.zero;

  // Estado temporário dos gestos de rotação/redimensionamento.
  Offset _gestureCenter = Offset.zero;
  double _startPointerAngle = 0;
  double _startRotation = 0;
  double _startDistance = 1;
  double _startFontFactor = 0.08;

  TemplateEditorController get controller => widget.controller;

  Offset? _toCanvasLocal(Offset global) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(global);
  }

  Offset _centerOf(TemplateElement el) =>
      Offset(el.position.dx * _canvasSize.width, el.position.dy * _canvasSize.height);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final spec = controller.spec;
        return AspectRatio(
          aspectRatio: spec.aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
              return Stack(
                key: _canvasKey,
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: controller.deselect,
                    child: _background(spec),
                  ),
                  ...spec.orderedElements.map((el) => _element(el, spec)),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _background(TemplateSpec spec) {
    if (spec.backgroundType == TemplateBackgroundType.image && widget.backgroundImage != null) {
      return Image(image: widget.backgroundImage!, fit: BoxFit.cover);
    }
    return ColoredBox(color: spec.backgroundColor);
  }

  Widget _element(TemplateElement el, TemplateSpec spec) {
    final selected = controller.selectedId == el.id;

    final content = Opacity(
      opacity: el.opacity.clamp(0.0, 1.0),
      child: TemplateElementView(
        element: el,
        canvasSize: _canvasSize,
        resolver: widget.resolver,
        fontFamilyResolver: widget.fontFamilyResolver,
      ),
    );

    // Corpo: seleção + movimento.
    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.select(el.id),
      onPanUpdate: (details) {
        final dx = details.delta.dx / _canvasSize.width;
        final dy = details.delta.dy / _canvasSize.height;
        final current = controller.selectedId == el.id ? controller.selectedElement! : el;
        if (controller.selectedId != el.id) controller.select(el.id);
        controller.setGeometry(
          el.id,
          position: Offset(
            (current.position.dx + dx).clamp(0.0, 1.0),
            (current.position.dy + dy).clamp(0.0, 1.0),
          ),
        );
      },
      child: Container(
        decoration: selected
            ? BoxDecoration(border: Border.all(color: widget.selectionColor, width: 1.5))
            : null,
        child: content,
      ),
    );

    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        body,
        if (selected) ..._handles(el),
      ],
    );

    return Align(
      alignment: Alignment(el.position.dx * 2 - 1, el.position.dy * 2 - 1),
      child: Transform.rotate(angle: el.rotation, child: stack),
    );
  }

  List<Widget> _handles(TemplateElement el) {
    return [
      // Alça de rotação (acima, centralizada).
      Positioned(
        top: -34,
        left: 0,
        right: 0,
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _startRotate(el, d.globalPosition),
            onPanUpdate: (d) => _updateRotate(el, d.globalPosition),
            child: _handleDot(icon: _rotateGlyph),
          ),
        ),
      ),
      // Linha até a alça de rotação.
      Positioned(
        top: -18,
        left: 0,
        right: 0,
        child: Center(child: Container(width: 1.5, height: 18, color: widget.selectionColor)),
      ),
      // Alça de redimensionamento (canto inferior-direito).
      Positioned(
        right: -13,
        bottom: -13,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) => _startResize(el, d.globalPosition),
          onPanUpdate: (d) => _updateResize(el, d.globalPosition),
          child: _handleDot(icon: _resizeGlyph),
        ),
      ),
    ];
  }

  Widget _handleDot({required String icon}) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: widget.selectionColor,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFFFFF), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(icon, style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12)),
    );
  }

  // Glyphs simples (o package não depende de fonte de ícones).
  static const _rotateGlyph = '⟳';
  static const _resizeGlyph = '⤢';

  void _startRotate(TemplateElement el, Offset global) {
    final local = _toCanvasLocal(global);
    if (local == null) return;
    controller.select(el.id);
    _gestureCenter = _centerOf(el);
    _startPointerAngle = (local - _gestureCenter).direction;
    _startRotation = el.rotation;
  }

  void _updateRotate(TemplateElement el, Offset global) {
    final local = _toCanvasLocal(global);
    if (local == null) return;
    final angle = (local - _gestureCenter).direction;
    controller.setGeometry(el.id, rotation: _startRotation + (angle - _startPointerAngle));
  }

  void _startResize(TemplateElement el, Offset global) {
    final local = _toCanvasLocal(global);
    if (local == null) return;
    controller.select(el.id);
    _gestureCenter = _centerOf(el);
    _startDistance = (local - _gestureCenter).distance;
    if (_startDistance < 1) _startDistance = 1;
    _startFontFactor = el is TextualElement ? el.style.fontSizeFactor : 0.08;
  }

  void _updateResize(TemplateElement el, Offset global) {
    final local = _toCanvasLocal(global);
    if (local == null) return;
    final distance = (local - _gestureCenter).distance;
    controller.setFontSizeFactor(el.id, _startFontFactor * (distance / _startDistance));
  }
}
