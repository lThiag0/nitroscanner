  import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nitroscanner/model/codigo_placa.dart';

class ScannerCamPage extends StatefulWidget {
  const ScannerCamPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ScannerCamPageState createState() => _ScannerCamPageState();
}

class _ScannerCamPageState extends State<ScannerCamPage> {
  final MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );

  final List<CodigoPlaca> codigosLidosPlacas = [];
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

  void _removerCodigo(CodigoPlaca codigoPlaca) {
    final index = codigosLidosPlacas.indexOf(codigoPlaca);
    if (index >= 0) {
      setState(() {
        codigosLidosPlacas.removeAt(index);
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
                '${codigoPlaca.codigo} - ${codigoPlaca.placa}',
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<String?> mostrarEscolhaPlaca(String codigo) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Escolha a placa para o código: $codigo',
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
              onPressed: () => Navigator.pop(context, 'Pequena'),
              child: const Text('Placa Pequena',
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
              onPressed: () => Navigator.pop(context, 'Grande'),
              child: const Text('Placa Grande',
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
              child: const Text('Placa Duplicada',
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

  Future<void> _mostrarAlertaCodigoRepetido(String codigo, String placa) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Código já escaneado'),
        content: Text('O código $codigo já foi lido com placa "$placa".'),
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

    final placa = await mostrarEscolhaPlaca(code);

    if (!mounted || placa == null) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) setState(() => isScanning = false);
      return;
    }

    final existe = codigosLidosPlacas.any((e) => e.codigo == code && e.placa == placa);

    if (existe) {
      await _mostrarAlertaCodigoRepetido(code, placa);
    } else {
      HapticFeedback.mediumImpact();

      setState(() {
        codigosLidosPlacas.add(CodigoPlaca(codigo: code, placa: placa));
        _listKey.currentState?.insertItem(codigosLidosPlacas.length - 1);
      });

    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => isScanning = false);
  }

  Future<void> salvarCodigos() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = codigosLidosPlacas.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('codigosLidosPlacasPlacas', jsonList);
  }

  void _finalizar() async {
    if (codigosLidosPlacas.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar escaneamento?'),
        content: Text('Você leu ${codigosLidosPlacas.length} código(s). Deseja confirmar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm == true) {
      await salvarCodigos();
      // ignore: use_build_context_synchronously
      Navigator.pop(context, codigosLidosPlacas);
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
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.3),
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
          if (codigosLidosPlacas.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de códigos lidos: ${codigosLidosPlacas.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: codigosLidosPlacas.length,
                      itemBuilder: (context, index, animation) {
                        final codigo = codigosLidosPlacas[index];
                        return SizeTransition(
                          sizeFactor: animation,
                          child: Card(
                            child: ListTile(
                              title: Text('${codigo.codigo} - ${codigo.placa}'),
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