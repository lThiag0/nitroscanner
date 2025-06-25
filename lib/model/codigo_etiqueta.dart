class CodigoEtiqueta {
  final String codigo;
  final String etiqueta;

  CodigoEtiqueta({required this.codigo, required this.etiqueta});

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'etiqueta': etiqueta,
      };

  factory CodigoEtiqueta.fromJson(Map<String, dynamic> json) {
    return CodigoEtiqueta(
      codigo: json['codigo'],
      etiqueta: json['etiqueta'],
    );
  }

  @override
  String toString() {
    return 'Código: $codigo | Etiqueta: $etiqueta';
  }
}
