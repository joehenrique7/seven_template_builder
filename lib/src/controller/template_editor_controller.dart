import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/dynamic_field.dart';
import '../models/template_element.dart';
import '../models/template_spec.dart';
import '../models/text_style_spec.dart';

/// Estado e operações do editor de template. As telas (no app) observam este
/// controller e chamam suas operações; o [TemplateEditorCanvas] usa-o para
/// renderizar e mover/redimensionar/rotacionar os elementos.
///
/// A ordem da lista de elementos é a própria ordem de camadas: o `zIndex` é
/// normalizado para o índice a cada mutação.
class TemplateEditorController extends ChangeNotifier {
  TemplateEditorController({
    TemplateSpec? spec,
    List<DynamicField> availableFields = const [],
  })  : _spec = spec ?? const TemplateSpec(),
        availableFields = List.unmodifiable(availableFields) {
    _normalize();
  }

  static const _uuid = Uuid();

  TemplateSpec _spec;
  TemplateSpec get spec => _spec;

  /// Campos dinâmicos que podem ser inseridos (fornecidos por quem usa).
  final List<DynamicField> availableFields;

  String? _selectedId;
  String? get selectedId => _selectedId;

  TemplateElement? get selectedElement {
    if (_selectedId == null) return null;
    for (final el in _spec.elements) {
      if (el.id == _selectedId) return el;
    }
    return null;
  }

  // --- Seleção -------------------------------------------------------------

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  void deselect() => select(null);

  // --- Carregar / substituir spec -----------------------------------------

  void loadSpec(TemplateSpec spec) {
    _spec = spec;
    _selectedId = null;
    _normalize();
    notifyListeners();
  }

  // --- Adicionar elementos -------------------------------------------------

  void addText(String text, {TextStyleSpec? style}) {
    final el = TextElement(
      id: _uuid.v4(),
      position: const Offset(0.5, 0.5),
      style: style ?? const TextStyleSpec(),
      text: text,
    );
    _appendSelected(el);
  }

  void addDynamicField(DynamicField field, {TextStyleSpec? style}) {
    final el = DynamicTextElement(
      id: _uuid.v4(),
      position: const Offset(0.5, 0.5),
      style: style ?? const TextStyleSpec(),
      field: field.key,
      placeholder: field.label,
    );
    _appendSelected(el);
  }

  void _appendSelected(TemplateElement el) {
    final list = [..._spec.elements, el];
    _spec = _spec.copyWith(elements: list);
    _selectedId = el.id;
    _normalize();
    notifyListeners();
  }

  // --- Editar elemento -----------------------------------------------------

  void _replace(String id, TemplateElement Function(TemplateElement) update) {
    final list = _spec.elements.map((e) => e.id == id ? update(e) : e).toList();
    _spec = _spec.copyWith(elements: list);
    notifyListeners();
  }

  /// Atualiza posição (centro fracionário) e/ou rotação — usado no arrasto.
  void setGeometry(String id, {Offset? position, double? rotation}) {
    _replace(id, (e) => e.copyBase(position: position, rotation: rotation));
  }

  void setOpacity(String id, double opacity) {
    _replace(id, (e) => e.copyBase(opacity: opacity.clamp(0.0, 1.0)));
  }

  void setStyle(String id, TextStyleSpec style) {
    _replace(id, (e) => e is TextualElement ? e.copyStyle(style) : e);
  }

  void setFontSizeFactor(String id, double factor) {
    _replace(id, (e) => e is TextualElement ? e.copyStyle(e.style.copyWith(fontSizeFactor: factor.clamp(0.01, 0.6))) : e);
  }

  void setText(String id, String text) {
    _replace(id, (e) => e is TextElement ? e.copyWith(text: text) : e);
  }

  // --- Remover / duplicar --------------------------------------------------

  void removeElement(String id) {
    final list = _spec.elements.where((e) => e.id != id).toList();
    _spec = _spec.copyWith(elements: list);
    if (_selectedId == id) _selectedId = null;
    _normalize();
    notifyListeners();
  }

  void duplicateElement(String id) {
    final index = _spec.elements.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final original = _spec.elements[index];
    final clone = TemplateElement.fromJson({
      ...original.toJson(),
      'id': _uuid.v4(),
      'x': (original.position.dx + 0.04).clamp(0.0, 1.0),
      'y': (original.position.dy + 0.04).clamp(0.0, 1.0),
    });
    final list = [..._spec.elements]..insert(index + 1, clone);
    _spec = _spec.copyWith(elements: list);
    _selectedId = clone.id;
    _normalize();
    notifyListeners();
  }

  // --- Ordem das camadas (z-index) ----------------------------------------

  void bringForward(String id) => _move(id, 1);

  void sendBackward(String id) => _move(id, -1);

  void bringToFront(String id) {
    final index = _spec.elements.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _move(id, _spec.elements.length - 1 - index);
  }

  void sendToBack(String id) {
    final index = _spec.elements.indexWhere((e) => e.id == id);
    if (index < 0) return;
    _move(id, -index);
  }

  void _move(String id, int delta) {
    final index = _spec.elements.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final target = (index + delta).clamp(0, _spec.elements.length - 1);
    if (target == index) return;
    final list = [..._spec.elements];
    final el = list.removeAt(index);
    list.insert(target, el);
    _spec = _spec.copyWith(elements: list);
    _normalize();
    notifyListeners();
  }

  // --- Fundo / canvas ------------------------------------------------------

  void setBackgroundColor(int colorValue) {
    _spec = _spec.copyWith(
      backgroundType: TemplateBackgroundType.color,
      backgroundColorValue: colorValue,
    );
    notifyListeners();
  }

  void setBackgroundImage(String url) {
    _spec = _spec.copyWith(
      backgroundType: TemplateBackgroundType.image,
      backgroundImageUrl: url,
    );
    notifyListeners();
  }

  void clearBackgroundImage() {
    _spec = _spec.copyWith(
      backgroundType: TemplateBackgroundType.color,
      backgroundImageUrl: null,
    );
    notifyListeners();
  }

  void setCanvasSize(int width, int height) {
    _spec = _spec.copyWith(canvasWidth: width, canvasHeight: height);
    notifyListeners();
  }

  /// Reatribui `zIndex` = índice na lista (ordem de camadas = ordem da lista).
  void _normalize() {
    var changed = false;
    final list = <TemplateElement>[];
    for (var i = 0; i < _spec.elements.length; i++) {
      final el = _spec.elements[i];
      if (el.zIndex != i) {
        changed = true;
        list.add(el.copyBase(zIndex: i));
      } else {
        list.add(el);
      }
    }
    if (changed) _spec = _spec.copyWith(elements: list);
  }
}
