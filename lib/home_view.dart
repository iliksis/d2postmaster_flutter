import 'package:d2postmaster_flutter/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart' as oauth2;

class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.client});

  final oauth2.Client client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Home View")),
        body: const Text("Home"));
  }
}
