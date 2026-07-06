/// Seven Template Editor — motor genérico de editor visual (tipo Canva
/// simplificado) e renderer de templates para banners.
///
/// O package **não conhece** o domínio do app (evento, etc.): ele opera sobre
/// um [TemplateSpec] (canvas + elementos) e resolve campos dinâmicos por meio de
/// um [DynamicFieldResolver] fornecido por quem usa. Assim o mesmo motor serve
/// para banner de evento hoje e para outros contextos depois.
///
/// Peças principais:
/// - [TemplateSpec] / [TemplateElement]: modelo serializável do template.
/// - [TemplateEditorController]: estado + operações de edição.
/// - [TemplateEditorCanvas]: canvas interativo (arrastar/redimensionar/rotacionar).
/// - [TemplateCanvas]: renderer puro (preview e rasterização).
/// - [rasterizeBoundary]: captura um [RepaintBoundary] em PNG.
library;

export 'src/controller/template_editor_controller.dart';
export 'src/editor/template_editor_canvas.dart';
export 'src/models/dynamic_field.dart';
export 'src/models/template_element.dart';
export 'src/models/template_spec.dart';
export 'src/models/text_style_spec.dart';
export 'src/render/template_canvas.dart';
export 'src/render/template_rasterizer.dart';
