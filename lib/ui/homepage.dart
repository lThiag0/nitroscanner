import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nitroscanner/ui/etiquetas.dart';
import 'package:nitroscanner/ui/faixa.dart';
import 'package:nitroscanner/ui/info.dart';
import 'package:nitroscanner/ui/placas.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          FaixasDecorativas(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                              'assets/logo.png',
                              width: 370,
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          const Text(
                            'Leitor inteligente de códigos',
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          _GradientButton(
                            label: 'Escanear Etiquetas',
                            icon: Icons.camera_alt,
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final codigosJson = prefs.getString('codigos_etiquetas');
                              List<dynamic> codigosSalvos = [];

                              if (codigosJson != null) {
                                try {
                                  codigosSalvos = jsonDecode(codigosJson) as List<dynamic>;
                                } catch (e) {
                                  codigosSalvos = [];
                                }
                              }

                              if (codigosSalvos.isNotEmpty) {
                                final escolha = await showDialog<bool>(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Códigos já existem'),
                                    content: const Text(
                                      'Existem códigos escaneados salvos. Deseja continuar com eles ou limpar antes de prosseguir?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Limpar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Continuar'),
                                      ),
                                    ],
                                  ),
                                );

                                if (escolha == null) return;

                                if (!escolha) {
                                  await prefs.remove('codigos_etiquetas');
                                }
                              }

                              Navigator.push(
                                // ignore: use_build_context_synchronously
                                context,
                                MaterialPageRoute(builder: (context) => const EtiquetasPage()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _GradientButton(
                            label: 'Escanear Placas',
                            icon: Icons.document_scanner,
                            onTap: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final codigosJson = prefs.getString('codigos_placas');
                              List<dynamic> codigosSalvos = [];

                              if (codigosJson != null) {
                                try {
                                  codigosSalvos = jsonDecode(codigosJson) as List<dynamic>;
                                } catch (e) {
                                  codigosSalvos = [];
                                }
                              }

                              if (codigosSalvos.isNotEmpty) {
                                final escolha = await showDialog<bool>(
                                  // ignore: use_build_context_synchronously
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Códigos já existem'),
                                    content: const Text(
                                      'Existem códigos escaneados salvos. Deseja continuar com eles ou limpar antes de prosseguir?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Limpar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Continuar'),
                                      ),
                                    ],
                                  ),
                                );

                                if (escolha == null) return;

                                if (!escolha) {
                                  await prefs.remove('codigos_placas');
                                }
                              }

                              Navigator.push(
                                // ignore: use_build_context_synchronously
                                context,
                                MaterialPageRoute(builder: (context) => const PlacasPage()),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _GradientButton(
                            label: 'Informações',
                            icon: Icons.info_outline,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const InfoPage()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: 120),
                  child: Text(
                    'Desenvolvido por Thiago Araújo - Matrícula 6099',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
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

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF3AA0FF), Color(0xFF6ECBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
