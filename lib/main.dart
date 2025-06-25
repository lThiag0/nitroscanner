import 'package:flutter/material.dart';
import 'package:nitroscanner/ui/etiquetas.dart';
import 'package:nitroscanner/ui/homepage.dart';
import 'package:nitroscanner/ui/info.dart';

void main() {
  runApp(MyApp());
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