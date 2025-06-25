import 'package:flutter/material.dart';
import 'package:nitroscanner/ui/faixa.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  Future<Map<String, String>> _getAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    return {
      'name': info.appName,
      'version': info.version,
      'build': info.buildNumber,
      'package': info.packageName,
    };
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o GitHub')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sobre o Aplicativo',
          style: TextStyle(color: Colors.white),
        ),
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
            child: FutureBuilder<Map<String, String>>(
              future: _getAppInfo(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final appInfo = snapshot.data!;
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(appInfo['name'] ?? '',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("Versão ${appInfo['version']} (build ${appInfo['build']})",
                          style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 24),
                      const Text(
                        'O Nitro Scanner é um aplicativo desenvolvido para agilizar o processo de precificação de etiquetas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      const SizedBox(height: 24),
                      const Text("Desenvolvido por Thiago Araujo",
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 16),
                      const Text("Matricula: 6099",
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _launchURL(
                          context,
                          'https://github.com/lThiag0/nitroscanner/', 
                        ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ver no GitHub'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF747474),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
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
