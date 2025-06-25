import 'package:flutter/material.dart';
import 'package:nitroscanner/ui/scanneretiqueta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:nitroscanner/ui/faixa.dart';
import 'package:nitroscanner/model/codigo_etiqueta.dart';
import 'package:nitroscanner/ui/scannercamera.dart';

class EtiquetasPage extends StatefulWidget {
  const EtiquetasPage({super.key});

  @override
  State<EtiquetasPage> createState() => _EtiquetasPageState();
}

class _EtiquetasPageState extends State<EtiquetasPage> {
  List<CodigoEtiqueta> codigosLidos = [];

  @override
  void initState() {
    super.initState();
    _carregarCodigos();
  }

  Future<void> _carregarCodigos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('codigos_etiquetas');

    if (jsonString != null) {
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        codigosLidos = jsonList
            .map((e) => CodigoEtiqueta.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } else {
      setState(() {
        codigosLidos = [];
      });
    }
  }

  Future<void> _salvarCodigos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(codigosLidos.map((e) => e.toJson()).toList());
    await prefs.setString('codigos_etiquetas', jsonString);
  }

  void _adicionarCodigos(List<CodigoEtiqueta> novos) {
    setState(() {
      final novosFiltrados = novos.where((novo) =>
        !codigosLidos.any((existente) =>
          existente.codigo == novo.codigo && existente.etiqueta == novo.etiqueta
        )
      ).toList();

      codigosLidos.addAll(novosFiltrados);
    });
    _salvarCodigos();
  }

  void _limparCodigos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('codigos_etiquetas');
    setState(() {
      codigosLidos.clear();
    });
  }

  void _mostrarModal(String etiqueta) {
    final filtrados = codigosLidos
        .where((element) => element.etiqueta == etiqueta)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filtrados.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Text(
                          'Nenhum código escaneado para esta etiqueta.',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    _ModalCodigos(
                      etiqueta: etiqueta,
                      codigos: filtrados,
                      onExcluir: (codigo) {
                        setState(() {
                          codigosLidos.removeWhere((e) => e.codigo == codigo && e.etiqueta == etiqueta);
                        });
                        _salvarCodigos();
                        setModalState(() {});
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner, size: 28),
                        label: Text(
                          'Escanear etiqueta [$etiqueta]',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final novosCodigos = await Navigator.push<List<CodigoEtiqueta>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScannerEtiquetaPage(etiqueta: etiqueta),
                            ),
                          );
                          if (novosCodigos != null && novosCodigos.isNotEmpty) {
                            setState(() {
                              for (var c in novosCodigos) {
                                if (!codigosLidos.any((e) => e.codigo == c.codigo && e.etiqueta == c.etiqueta)) {
                                  codigosLidos.add(c);
                                }
                              }
                            });
                            await _salvarCodigos();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    ).whenComplete(() => setState(() {}));
  }

  int getTotalPorEtiqueta(String etiqueta) {
    return codigosLidos.where((e) => e.etiqueta == etiqueta).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etiquetas', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF40C4FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const FaixasDecorativas(),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Etiquetas escaneadas:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _etiquetaButton(
                    icon: Icons.label_outline,
                    label: 'Etiqueta Branca (${getTotalPorEtiqueta("Branca")})',
                    color: const Color(0xFF6ECBFF),
                    onPressed: () => _mostrarModal("Branca"),
                  ),
                  const SizedBox(height: 16),
                  _etiquetaButton(
                    icon: Icons.label,
                    label: 'Etiqueta Amarela (${getTotalPorEtiqueta("Amarela")})',
                    color: const Color(0xFF6ECBFF),
                    onPressed: () => _mostrarModal("Amarela"),
                  ),
                  const SizedBox(height: 16),
                  _etiquetaButton(
                    icon: Icons.copy_all,
                    label: 'Duplicadas (${getTotalPorEtiqueta("Duplicada")})',
                    color: const Color(0xFF6ECBFF),
                    onPressed: () => _mostrarModal("Duplicada"),
                  ),
                  const SizedBox(height: 24),
                  const Divider(thickness: 1, color: Colors.grey),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final resultado = await Navigator.push<List<CodigoEtiqueta>>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScannerPage(),
                          ),
                        );

                        if (resultado != null) {
                          _adicionarCodigos(resultado);
                        }
                      },
                      icon: const Icon(Icons.camera_alt, size: 26),
                      label: const Text(
                        'Escanear Código',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3AA0FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _limparCodigos,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text(
                            'Limpar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB0C4DE),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _salvarCodigos,
                          icon: const Icon(Icons.send),
                          label: const Text(
                            'Enviar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 145, 144, 144),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiquetaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}

class _ModalCodigos extends StatefulWidget {
  final String etiqueta;
  final List<CodigoEtiqueta> codigos;
  final void Function(String codigo) onExcluir;

  const _ModalCodigos({
    required this.etiqueta,
    required this.codigos,
    required this.onExcluir,
  });

  @override
  State<_ModalCodigos> createState() => _ModalCodigosState();
}

class _ModalCodigosState extends State<_ModalCodigos> {
  late List<CodigoEtiqueta> listaFiltrada;

  @override
  void initState() {
    super.initState();
    listaFiltrada = List.from(widget.codigos);
  }

  void _excluirCodigo(String codigo) {
    widget.onExcluir(codigo);
    setState(() {
      listaFiltrada.removeWhere((e) => e.codigo == codigo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Etiqueta ${widget.etiqueta.toLowerCase()}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: listaFiltrada.length,
              itemBuilder: (context, index) {
                final item = listaFiltrada[index];
                return ListTile(
                  title: Text(item.codigo),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _excluirCodigo(item.codigo),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}