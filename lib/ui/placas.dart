import 'package:flutter/material.dart';
import 'package:nitroscanner/ui/scannercam.dart';
import 'package:nitroscanner/ui/scannerplaca.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:nitroscanner/ui/faixa.dart';
import 'package:nitroscanner/model/codigo_placa.dart';

class PlacasPage extends StatefulWidget {
  const PlacasPage({super.key});

  @override
  State<PlacasPage> createState() => _PlacasPageState();
}

class _PlacasPageState extends State<PlacasPage> {
  List<CodigoPlaca> codigosLidosPlacas = [];

  @override
  void initState() {
    super.initState();
    _carregarCodigos();
  }

  Future<void> _carregarCodigos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('codigos_placas');

    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        setState(() {
          codigosLidosPlacas = jsonList
              .map((e) => CodigoPlaca.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      } catch (e) {
        await prefs.remove('codigos_placas');
        setState(() {
          codigosLidosPlacas = [];
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao carregar códigos, codigos foram zerados!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      }
    } else {
      setState(() {
        codigosLidosPlacas = [];
      });
    }
  }

void _compartilharCodigos() {
    if (codigosLidosPlacas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum código escaneado para compartilhar.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final texto = StringBuffer();
    texto.writeln('Escaneamento Inteligente NitroScanner\n');

    void adicionarBloco(String placa, String titulo) {
      final codigos = codigosLidosPlacas.where((e) => e.placa == placa).map((e) => e.codigo).toList();
      if (codigos.isNotEmpty) {
        texto.writeln('$titulo:');
        for (var codigo in codigos) {
          texto.writeln('$codigo,');
        }
        texto.writeln();
      }
    }

    adicionarBloco('Pequena', 'Placas Pequenas');
    adicionarBloco('Grande', 'Placas Grandes');
    adicionarBloco('Duplicada', 'Placas Duplicadas');

    try {
      Share.share(texto.toString());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao compartilhar: $e')),
      );
    }
  }

  Future<void> _salvarCodigos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(codigosLidosPlacas.map((e) => e.toJson()).toList());
    await prefs.setString('codigos_placas', jsonString);
  }

  void _adicionarCodigos(List<CodigoPlaca> novos) {
    setState(() {
      final novosFiltrados = novos.where((novo) =>
        !codigosLidosPlacas.any((existente) =>
          existente.codigo == novo.codigo && existente.placa == novo.placa
        )
      ).toList();

      codigosLidosPlacas.addAll(novosFiltrados);
    });
    _salvarCodigos();
  }

  void _limparCodigos() async {
    if (codigosLidosPlacas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum código escaneado para limpar.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('codigos_placas');
    setState(() {
      codigosLidosPlacas.clear();
    });
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Codigos limpos com sucesso')),
    );
  }

  void _mostrarModal(String placa) {
    final filtrados = codigosLidosPlacas
        .where((element) => element.placa == placa)
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
                          'Nenhum código escaneado para esta Placa.',
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    _ModalCodigos(
                      placa: placa,
                      codigos: filtrados,
                      onExcluir: (codigo) {
                        setState(() {
                          codigosLidosPlacas.removeWhere((e) => e.codigo == codigo && e.placa == placa);
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
                          'Escanear Placa [$placa]',
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
                          final novosCodigos = await Navigator.push<List<CodigoPlaca>>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScannerPlacaPage(placa: placa),
                            ),
                          );
                          if (novosCodigos != null && novosCodigos.isNotEmpty) {
                            setState(() {
                              for (var c in novosCodigos) {
                                if (!codigosLidosPlacas.any((e) => e.codigo == c.codigo && e.placa == c.placa)) {
                                  codigosLidosPlacas.add(c);
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

  int getTotalPorPlaca(String placa) {
    return codigosLidosPlacas.where((e) => e.placa == placa).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placas', style: TextStyle(color: Colors.white)),
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
                    'Placas escaneadas:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _placaButton(
                    icon: Icons.label_outline,
                    label: 'Placa Pequena (${getTotalPorPlaca("Pequena")})',
                    color: const Color(0xFF6ECBFF),
                    onPressed: () => _mostrarModal("Pequena"),
                  ),
                  const SizedBox(height: 16),
                  _placaButton(
                    icon: Icons.label,
                    label: 'Placa Grande (${getTotalPorPlaca("Grande")})',
                    color: const Color(0xFF6ECBFF),
                    onPressed: () => _mostrarModal("Grande"),
                  ),
                  const SizedBox(height: 16),
                  _placaButton(
                    icon: Icons.copy_all,
                    label: 'Placa Duplicadas (${getTotalPorPlaca("Duplicada")})',
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
                        final resultado = await Navigator.push<List<CodigoPlaca>>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScannerCamPage(),
                          ),
                        );

                        if (resultado != null) {
                          _adicionarCodigos(resultado);
                        }
                      },
                      icon: const Icon(Icons.camera_alt, size: 26),
                      label: const Text(
                        'Escanear Códigos',
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
                          onPressed: () async {
                            final confirmar = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirmar Limpeza'),
                                content: const Text('Tem certeza que deseja apagar todos os códigos escaneados?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Limpar'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmar == true) {
                              _limparCodigos();
                            }
                          },
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
                          onPressed: _compartilharCodigos,
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

  Widget _placaButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF3AA0FF), Color(0xFF6ECBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ModalCodigos extends StatefulWidget {
  final String placa;
  final List<CodigoPlaca> codigos;
  final void Function(String codigo) onExcluir;

  const _ModalCodigos({
    required this.placa,
    required this.codigos,
    required this.onExcluir,
  });

  @override
  State<_ModalCodigos> createState() => _ModalCodigosState();
}

class _ModalCodigosState extends State<_ModalCodigos> {
  late List<CodigoPlaca> listaFiltrada;

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
            'Placa ${widget.placa.toLowerCase()}',
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