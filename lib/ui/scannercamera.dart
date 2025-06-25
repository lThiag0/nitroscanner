import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nitroscanner/model/codigo_etiqueta.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );

  final List<CodigoEtiqueta> codigosLidos = [];
  late final AudioPlayer _player;
  bool isTorchOn = false;
  bool isScanning = false;
  late final GlobalKey<AnimatedListState> _listKey;
  bool _dialogAberto = false;

  bool validarCodigoEan = true;
  bool beepAtivado = true;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _listKey = GlobalKey<AnimatedListState>();
  }

  @override
  void dispose() {
    _player.dispose();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    try {
      await _player.play(AssetSource('beepscan.mp3'));
    } catch (e) {
      debugPrint('Erro ao tocar o beep: ${e.toString()}');
    }
  }

  void _toggleTorch() {
    setState(() {
      isTorchOn = !isTorchOn;
    });
    cameraController.toggleTorch();
  }

  void _removerCodigo(CodigoEtiqueta codigoEtiqueta) {
    final index = codigosLidos.indexOf(codigoEtiqueta);
    if (index >= 0) {
      setState(() {
        codigosLidos.removeAt(index);
      });
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.red[100],
            child: ListTile(
              title: Text(
                '${codigoEtiqueta.codigo} - ${codigoEtiqueta.etiqueta}',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 400),
      );
    }
  }

  Future<String?> mostrarEscolhaEtiqueta(String codigo) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Escolha a etiqueta para o código: $codigo',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, 'Branca'),
              child: const Text('Etiqueta Branca',
              style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, 'Amarela'),
              child: const Text('Etiqueta Amarela',
              style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, 'Duplicada'),
              child: const Text('Etiqueta Duplicada',
              style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF616161),
                minimumSize: const Size(double.infinity, 48),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancelar leitura', 
              style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarAlertaCodigoRepetido(String codigo) async {
    if (_dialogAberto) return;
    _dialogAberto = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Código já escaneado'),
        content: Text('O código $codigo já foi lido.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _dialogAberto = false;
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
    });

    String? novoCodigo;
    String? etiquetaEscolhida;

    for (final barcode in barcodeCapture.barcodes) {
      final code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        if (validarCodigoEan && !validarEAN(code)) {
          setState(() {
            isScanning = false;
          });
          break;
        }

        if (!codigosLidos.any((e) => e.codigo == code)) {
          if (beepAtivado) await _playBeep();
          novoCodigo = code;
          etiquetaEscolhida = await mostrarEscolhaEtiqueta(code);
          break;
        } else {
          HapticFeedback.heavyImpact();
          await _mostrarAlertaCodigoRepetido(code);
          break;
        }
      }
    }

    if (novoCodigo != null && etiquetaEscolhida != null) {
      setState(() {
        codigosLidos.add(CodigoEtiqueta(codigo: novoCodigo!, etiqueta: etiquetaEscolhida!));
        _listKey.currentState?.insertItem(codigosLidos.length - 1);
      });
      HapticFeedback.mediumImpact();
    }

    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      isScanning = false;
    });
  }

  Future<void> salvarCodigos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = codigosLidos.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('codigosLidosEtiquetas', jsonList);
  }

  void _finalizar() async {
    if (codigosLidos.isEmpty) {
      Navigator.pop(context);
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Finalizar escaneamento?'),
          content: Text('Você leu ${codigosLidos.length} código(s). Deseja confirmar?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
          ],
        ),
      );

      if (confirm == true) {
        await salvarCodigos();
        Navigator.pop(context, codigosLidos);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scanner Cam',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 20, 121, 189),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(
              validarCodigoEan ? Icons.verified : Icons.cancel,
              color: validarCodigoEan ? Colors.greenAccent : Colors.redAccent,
            ),
            onPressed: () {
              setState(() {
                validarCodigoEan = !validarCodigoEan;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(validarCodigoEan
                      ? 'Validação de código EAN ativada.'
                      : 'Validação de código EAN desativada.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              beepAtivado ? Icons.volume_up : Icons.volume_off,
              color: beepAtivado ? Colors.lightGreenAccent : Colors.grey,
            ),
            tooltip: beepAtivado ? 'Beep ativado' : 'Beep desativado',
            onPressed: () {
              setState(() {
                beepAtivado = !beepAtivado;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(beepAtivado ? 'Som ativado.' : 'Som desativado.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            tooltip: 'Finalizar escaneamento',
            onPressed: _finalizar,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onBarcodeDetected,
                ),
                if (isScanning)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(
                            strokeWidth: 5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Escaneando...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (codigosLidos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de códigos lidos: ${codigosLidos.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: codigosLidos.length,
                      itemBuilder: (context, index, animation) {
                        final codigoEtiqueta = codigosLidos[index];
                        return SizeTransition(
                          sizeFactor: animation,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Text(
                                      '${codigoEtiqueta.codigo} - ${codigoEtiqueta.etiqueta}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _removerCodigo(codigoEtiqueta);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

bool validarEAN(String codigo) {
  // Verifica se só tem dígitos e tamanho 8 ou 13
  if (!RegExp(r'^\d+$').hasMatch(codigo)) return false;
  if (codigo.length != 8 && codigo.length != 13) return false;

  final digits = codigo.split('').map(int.parse).toList();
  final checkDigit = digits.removeLast();

  int sum = 0;
  for (int i = 0; i < digits.length; i++) {
    int weight;
    if (codigo.length == 13) {
      // Para EAN-13: posições pares ponderam 1, ímpares ponderam 3 (índice 0-based)
      weight = (i % 2 == 0) ? 1 : 3;
    } else {
      // Para EAN-8: posições pares ponderam 3, ímpares ponderam 1
      weight = (i % 2 == 0) ? 3 : 1;
    }
    sum += digits[i] * weight;
  }

  int expectedCheckDigit = (10 - (sum % 10)) % 10;

  return checkDigit == expectedCheckDigit;
}

