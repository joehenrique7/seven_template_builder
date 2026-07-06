import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Captura o [RepaintBoundary] identificado por [boundaryKey] como PNG.
///
/// Uso típico: envolver um `TemplateCanvas` em `RepaintBoundary(key: k)` exibido
/// no tamanho `displayWidth`, e chamar com `pixelRatio = canvasWidth / displayWidth`
/// para gerar a imagem na resolução real do canvas.
///
/// Deve ser chamado após o boundary estar montado e pintado (ex.: em um
/// `WidgetsBinding.instance.addPostFrameCallback`). Retorna `null` se o boundary
/// não estiver disponível.
Future<Uint8List?> rasterizeBoundary(
  GlobalKey boundaryKey, {
  double pixelRatio = 1.0,
}) async {
  final context = boundaryKey.currentContext;
  if (context == null) return null;

  final object = context.findRenderObject();
  if (object is! RenderRepaintBoundary) return null;

  // Se ainda precisa pintar, aguarda um frame antes de capturar.
  if (object.debugNeedsPaint) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }

  final ui.Image image = await object.toImage(pixelRatio: pixelRatio);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
