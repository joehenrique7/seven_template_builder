/// Descreve um campo dinâmico disponível para inserir no template.
///
/// Fornecido por quem usa o editor (ex.: o app registra "nome do evento",
/// "data", "local"...). O motor não conhece a origem dos dados — apenas a
/// [key] (guardada no elemento) e o [label]/[sample] para exibir no editor.
class DynamicField {
  const DynamicField({
    required this.key,
    required this.label,
    required this.sample,
  });

  /// Identificador estável salvo no template (ex.: `event.name`).
  final String key;

  /// Rótulo exibido no menu de campos e como placeholder no editor.
  final String label;

  /// Valor de exemplo mostrado no editor quando não há dados reais.
  final String sample;
}

/// Resolve o valor real de um campo dinâmico a partir da sua [DynamicField.key].
///
/// No editor (sem dados) devolve o exemplo/label; na aplicação final devolve o
/// dado do contexto (ex.: o nome do evento). Retornar `null` esconde o valor.
typedef DynamicFieldResolver = String? Function(String fieldKey);

/// Resolve a família de fonte (string do modelo) para a família realmente
/// registrada no app. Retorne `null` para usar a fonte padrão do sistema.
typedef FontFamilyResolver = String? Function(String? fontFamilyKey);
