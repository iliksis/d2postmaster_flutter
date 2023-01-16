import 'dart:ffi';

import 'package:d2postmaster_flutter/bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<StatefulWidget> createState() => _LoginViewState();
}

const prefKey = "creds";

class _LoginViewState extends State<LoginView> {
  late final WebViewController _controller;
  var _finishedWeb = false;
  oauth2.Credentials? _credentials;

  final authorizationEndpoint =
      Uri.parse("https://www.bungie.net/en/OAuth/Authorize");
  final tokenEndpoint =
      Uri.parse("https://www.bungie.net/platform/app/oauth/token/");

  final identifier = dotenv.get("CLIENT_ID");
  final clientSecret = dotenv.get("CLIENT_SECRET");

  final redirectUrl = Uri.parse('https://localhost:5000/redirect');

  Future<bool> checkCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final String? creds = prefs.getString(prefKey);
    if (creds != null) {
      final credentials = oauth2.Credentials.fromJson(creds);
      final client = oauth2.Client(credentials,
          identifier: identifier, secret: clientSecret);
      setState(() {
        _credentials = client.credentials;
      });
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();

    final grant = oauth2.AuthorizationCodeGrant(
        identifier, authorizationEndpoint, tokenEndpoint,
        secret: clientSecret);
    final authorizationUrl = grant.getAuthorizationUrl(redirectUrl);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
          NavigationDelegate(onNavigationRequest: (request) async {
        if (request.url.startsWith(redirectUrl.toString())) {
          final prefs = await SharedPreferences.getInstance();
          final responseUrl = Uri.parse(request.url);
          final client = await grant
              .handleAuthorizationResponse(responseUrl.queryParameters);
          prefs.setString(prefKey, client.credentials.toJson().toString());

          setState(() {
            _finishedWeb = true;
            _credentials = client.credentials;
          });
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      }))
      ..loadRequest(authorizationUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Test")),
      body: FutureBuilder(
        future: checkCredentials(),
        builder: (context, snapshot) {
          Widget child;
          if (!snapshot.hasData) {
            child = const Center(
              child: Text("checking creds"),
            );
          } else {
            if (snapshot.data! || _finishedWeb) {
              child = const Center(
                child: BottomNavigation(title: "Home View"),
              );
            } else {
              child = WebViewWidget(controller: _controller);
            }
          }
          return child;
        },
      ),
    );
  }
}
