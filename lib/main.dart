import 'package:flutter/material.dart';
import 'package:flutter_qr_app/clipboard.dart';
import 'package:qr_mobile_vision/qr_camera.dart';
import 'package:qr_mobile_vision/qr_mobile_vision.dart';

import 'logger.dart';
import 'navigator.dart';
import 'strings.dart';
import 'url_launcher.dart';

const kAppTitle = "QR Reader";
const kAppBarTitle = "QR Reader";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppTitle,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(72.0, 56.0),
          ),
        ),
      ),
      home: const CameraPage(),
    );
  }
}

class CameraPage extends StatelessWidget {
  const CameraPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppBarTitle),
      ),
      body: const _Scanner(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (int index) {
          logger.d("BottomNavigationBar: ${index}");
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: "Scan",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "History",
          ),
        ],
      ),
    );
  }
}

class _Scanner extends StatefulWidget {
  const _Scanner({
    Key? key,
  }) : super(key: key);

  @override
  _ScannerState createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner> {
  Future<void>? _handling;

  @override
  Widget build(BuildContext context) {
    if (_handling != null) {
      logger.d("handlingBuilder");
      return const Center(child: Text("Camera Paused"));
    }

    return QrCamera(
      // key: cameraKey,
      // formats: const [BarcodeFormats.QR_CODE],
      qrCodeCallback: qrCodeCallback,
      notStartedBuilder: (context) {
        logger.d("notStartedBuilder");
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      offscreenBuilder: (context) {
        logger.d("offscreenBuilder");
        return const Center(child: Text("Camera Paused"));
      },
      onError: (context, error) {
        logger.d("onError: ${error}");
        return const Center(child: Text("Camera Error"));
      },
    );
  }

  Future<void> qrCodeCallback(String? value) async {
    if (!mounted) {
      logger.d("not mounted");
      return;
    }
    if (_handling != null) {
      logger.d("now handling");
      return;
    }
    if (value == null) {
      logger.d("no value");
      return;
    }
    logger.d("detected: ${value}");

    final future = handleCode(value);
    _setHandling(future);
    return future.whenComplete(_clearHandling);
  }

  void _setHandling(Future<void>? future) {
    setState(() {
      _handling = future;
    });
  }

  void _clearHandling() {
    _setHandling(null);
  }

  Future<void> handleCode(String value) async {
    await pushDialog(context, (context) {
      return _ValuePage(value);
    });

    await Future.delayed(const Duration(seconds: 3));
  }
}

class _ValuePage extends StatelessWidget {
  _ValuePage(
    String value, {
    Key? key,
  })  : value = breakWord(value),
        super(key: key);

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detected"),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              value,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const Divider(),
          _DialogOption(
            onPressed: () async {
              final result = await launchUrl(value);
              if (!result) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
                  content: Text("Failed to launch"),
                ));
              }
            },
            title: "Open in browser",
          ),
          _DialogOption(
            onPressed: () async {
              await clipboardPaste(value);
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
                content: Text("Copied"),
              ));
            },
            title: "Copy",
          ),
        ],
      ),
    );
  }
}

class _DialogOption extends StatelessWidget {
  const _DialogOption({
    required this.onPressed,
    required this.title,
    Key? key,
  }) : super(key: key);

  final VoidCallback? onPressed;

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(title),
      ),
    );
  }
}
