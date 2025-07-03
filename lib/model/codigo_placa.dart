class CodigoPlaca {
  final String codigo;
  final String placa;

  CodigoPlaca({required this.codigo, required this.placa});

  Map<String, dynamic> toJson() => {
        'codigo': codigo,
        'placa': placa,
      };

  factory CodigoPlaca.fromJson(Map<String, dynamic> json) {
    return CodigoPlaca(
      codigo: json['codigo'],
      placa: json['placa'],
    );
  }

  @override
  String toString() {
    return 'Código: $codigo | Placa: $placa';
  }
}
