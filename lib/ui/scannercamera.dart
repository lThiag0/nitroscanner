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
  // ignore: library_private_types_in_public_api
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
    if (!beepAtivado) return;
    try {
      await _player.play(AssetSource('beepscan.mp3'));
    } catch (e) {
      debugPrint('Erro ao tocar o beep: ${e.toString()}');
    }
  }

  void _toggleTorch() {
    setState(() => isTorchOn = !isTorchOn);
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

  Future<void> _mostrarAlertaCodigoRepetido(String codigo, String etiqueta) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código já escaneado'),
        content: Text('O código $codigo já foi lido com etiqueta "$etiqueta".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) async {
    if (isScanning) return;

    final barcode = barcodeCapture.barcodes.firstOrNull;
    final code = barcode?.rawValue;

    if (code == null || code.isEmpty) return;

    setState(() => isScanning = true);

    if (validarCodigoEan && !validarEAN(code)) {
      setState(() => isScanning = false);
      return;
    }

    if (beepAtivado) await _playBeep();

    final etiqueta = await mostrarEscolhaEtiqueta(code);

    if (!mounted || etiqueta == null) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) setState(() => isScanning = false);
      return;
    }

    final existe = codigosLidos.any((e) => e.codigo == code && e.etiqueta == etiqueta);

    if (existe) {
      await _mostrarAlertaCodigoRepetido(code, etiqueta);
    } else {
      HapticFeedback.mediumImpact();

      setState(() {
        codigosLidos.add(CodigoEtiqueta(codigo: code, etiqueta: etiqueta));
        _listKey.currentState?.insertItem(codigosLidos.length - 1);
      });

    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => isScanning = false);
  }

  Future<void> salvarCodigos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = codigosLidos.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('codigosLidosEtiquetas', jsonList);
  }

  void _finalizar() async {
    if (codigosLidos.isEmpty) {
      Navigator.pop(context);
      return;
    }

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
      // ignore: use_build_context_synchronously
      Navigator.pop(context, codigosLidos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner Cam', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 20, 121, 189),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
          ),
          IconButton(
            icon: Icon(validarCodigoEan ? Icons.verified : Icons.cancel, color: Colors.white),
            onPressed: () => setState(() => validarCodigoEan = !validarCodigoEan),
          ),
          IconButton(
            icon: Icon(beepAtivado ? Icons.volume_up : Icons.volume_off, color: Colors.white),
            onPressed: () => setState(() => beepAtivado = !beepAtivado),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
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
                    color: Colors.black.withAlpha((0.3 * 255).round()),
                    child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: codigosLidos.length,
                      itemBuilder: (context, index, animation) {
                        final codigo = codigosLidos[index];
                        return SizeTransition(
                          sizeFactor: animation,
                          child: Card(
                            child: ListTile(
                              title: Text('${codigo.codigo} - ${codigo.etiqueta}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removerCodigo(codigo),
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
  if (!RegExp(r'^\d+$').hasMatch(codigo)) return false;
  if (codigo.length != 8 && codigo.length != 13) return false;

  final digits = codigo.split('').map(int.parse).toList();
  final checkDigit = digits.removeLast();

  int sum = 0;
  for (int i = 0; i < digits.length; i++) {
    int weight = (codigo.length == 13) ? (i % 2 == 0 ? 1 : 3) : (i % 2 == 0 ? 3 : 1);
    sum += digits[i] * weight;
  }

  int expectedCheckDigit = (10 - (sum % 10)) % 10;
  return checkDigit == expectedCheckDigit;
}