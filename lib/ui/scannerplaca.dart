import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:nitroscanner/model/codigo_placa.dart';

class ScannerPlacaPage extends StatefulWidget {
  final String placa;

  const ScannerPlacaPage({super.key, required this.placa});

  @override
  // ignore: library_private_types_in_public_api
  _ScannerPlacaPageState createState() => _ScannerPlacaPageState();
}

class _ScannerPlacaPageState extends State<ScannerPlacaPage> {
  final MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );

  final List<CodigoPlaca> codigosLidos = [];
  late final AudioPlayer _player;
  bool isTorchOn = false;
  bool isScanning = false;
  late final GlobalKey<AnimatedListState> _listKey;
  bool _dialogAberto = false;

  bool beepAtivado = true;
  bool validarCodigoEan = true;

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
    final index = codigosLidos.indexOf(codigoPlaca);
    if (index >= 0) {
      setState(() => codigosLidos.removeAt(index));
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
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    _dialogAberto = false;
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) async {
    if (isScanning || _dialogAberto) return;

    setState(() => isScanning = true);

    for (final barcode in barcodeCapture.barcodes) {
      final code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        if (validarCodigoEan && !validarEAN(code)) {
          if (!mounted) return;
          setState(() => isScanning = false);
          break;
        }

        if (!codigosLidos.any((e) => e.codigo == code)) {
          await _playBeep();
          if (!mounted) return;
          setState(() {
            codigosLidos.add(CodigoPlaca(codigo: code, placa: widget.placa));
            _listKey.currentState?.insertItem(codigosLidos.length - 1);
          });
          HapticFeedback.mediumImpact();
          break;
        } else {
          HapticFeedback.heavyImpact();
          await _mostrarAlertaCodigoRepetido(code);
          break;
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => isScanning = false);
  }

  Future<void> _adicionarCodigoManualmente() async {
    final controller = TextEditingController();
    final codigoManual = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar código manualmente'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Código',
            hintText: 'Digite o código',
          ),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (codigoManual != null && codigoManual.isNotEmpty) {
      if (validarCodigoEan && !validarEAN(codigoManual)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido!')),
        );
        return;
      }

      if (codigosLidos.any((e) => e.codigo == codigoManual)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código já foi adicionado!')),
        );
        return;
      }

      await _playBeep();
      if (!mounted) return;
      setState(() {
        codigosLidos.add(CodigoPlaca(codigo: codigoManual, placa: widget.placa));
        _listKey.currentState?.insertItem(codigosLidos.length - 1);
      });
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _finalizar() async {
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
      if (!mounted) return;
      if (confirm == true) Navigator.pop(context, codigosLidos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scanner Cam ${widget.placa}',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color.fromARGB(255, 20, 121, 189),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white),
            onPressed: _toggleTorch,
          ),
          IconButton(
            icon: Icon(
              validarCodigoEan ? Icons.verified : Icons.cancel,
              color: validarCodigoEan ? Colors.white : Colors.white,
            ),
            tooltip: 'Validar código EAN',
            onPressed: () {
              setState(() => validarCodigoEan = !validarCodigoEan);
            },
          ),
          IconButton(
            icon: Icon(
              beepAtivado ? Icons.volume_up : Icons.volume_off,
              color: beepAtivado ? Colors.white : Colors.white,
            ),
            tooltip: 'Som de beep',
            onPressed: () {
              setState(() => beepAtivado = !beepAtivado);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Adicionar código manualmente',
            onPressed: _adicionarCodigoManualmente,
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
                        final codigoPlaca = codigosLidos[index];
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
                                      '${codigoPlaca.codigo} - ${codigoPlaca.placa}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removerCodigo(codigoPlaca),
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
