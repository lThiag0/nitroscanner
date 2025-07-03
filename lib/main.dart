import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // necessário para controlar orientação
import 'package:nitroscanner/ui/etiquetas.dart';
import 'package:nitroscanner/ui/homepage.dart';
import 'package:nitroscanner/ui/info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nitro Scanner',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/etiquetas': (context) => EtiquetasPage(),
        '/info': (context) => InfoPage(),
      },
    );
  }
}
