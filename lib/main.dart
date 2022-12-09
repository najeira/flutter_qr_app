import 'package:flutter/material.dart';
import 'package:flutter_qr_app/clipboard.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
  String? _lastValue;
  MobileScannerController? _controller;
  bool _stop = false;

  @override
  void initState() {
    super.initState();
    _controller?.dispose();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = _stop || (_controller?.isStarting == true);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        children: [
          MobileScanner(
            onDetect: (barcode, args) {
              _onNewCode(context, barcode.rawValue);
            },
            controller: _controller,
            fit: BoxFit.cover,
            allowDuplicates: false,
          ),
          if (loading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _onNewCode(BuildContext context, String? value) {
    if (!mounted) {
      logger.d("not mounted");
      return;
    }

    if (value == _lastValue) {
      logger.d("duplicate: ${value}");
      return;
    }
    _lastValue = value;

    if (value == null || value.isEmpty) {
      logger.d("no value");
      return;
    }
    logger.d("detected: ${value}");
    _handleCode(value);
  }

  Future<void> _handleCode(String value) async {
    setState(() {
      _stop = true;
    });
    _controller?.stop();

    try {
      await pushDialog(context, (context) {
        return _ValuePage(value);
      });
      await Future.delayed(const Duration(seconds: 1));
    } finally {
      await _controller?.start();
      setState(() {
        _stop = false;
      });
    }
  }
}

class _ValuePage extends StatelessWidget {
  _ValuePage(
    this.value, {
    Key? key,
  })  : textValue = breakWord(value),
        super(key: key);

  final String value;

  final String textValue;

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
              textValue,
              style: theme.textTheme.headlineSmall,
            ),
          ),
          const Divider(),
          _DialogOption(
            onPressed: () async {
              try {
                await launchUrl(value);
              } catch (ex) {
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                  content: Text("Error: ${ex}"),
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
