import 'package:flutter/material.dart';
import 'package:flutter_qr_app/clipboard.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'logger.dart';
import 'strings.dart';
import 'url_launcher.dart';

const kAppTitle = "QR Reader";
const kAppBarTitle = "QR Reader";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppTitle,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      facing: CameraFacing.back,
      ratio: null,
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(kAppBarTitle),
      ),
      body: _Scanner(controller),
    );
  }
}

class _Scanner extends StatefulWidget {
  const _Scanner(this.controller, {
    Key? key,
  }) : super(key: key);

  final MobileScannerController controller;

  @override
  _ScannerState createState() => _ScannerState();
}

class _ScannerState extends State<_Scanner> {
  Future<void>? _scanning;

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      onDetect: (barcode, args) {
        if (_scanning == null) {
          _scanning = _onDetect(context, barcode, args);
          _scanning?.whenComplete(() => _scanning = null);
        }
      },
      controller: widget.controller,
      fit: BoxFit.cover,
      allowDuplicates: true,
    );
  }

  Future<void> _onDetect(
    BuildContext context,
    Barcode barcode,
    MobileScannerArguments? args,
  ) async {
    final value = barcode.rawValue;
    if (value == null) {
      logger.d("Failed to scan code");
      return;
    }

    logger.d("Barcode found: ${value}");

    widget.controller.stop();
    try {
      final kind = await showDialog<_DialogOptionKind>(
        context: context,
        builder: (context) {
          return _Dialog(value);
        },
      );
      _handleMenu(context, value, kind);
    } finally {
      if (widget.controller.isStarting == false) {
        widget.controller.start();
      }
    }
  }

  Future<void> _handleMenu(
    BuildContext context,
    String value,
    _DialogOptionKind? kind,
  ) async {
    if (kind == null) {
      return;
    }

    switch (kind) {
      case _DialogOptionKind.open:
        final result = await launchUrl(value);
        if (!result) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
            content: Text("Failed to launch"),
          ));
        }
        break;
      case _DialogOptionKind.copy:
        await clipboardPaste(value);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(
          content: Text("Copied"),
        ));
        break;
    }
  }
}

enum _DialogOptionKind {
  open,
  copy,
}

class _Dialog extends StatelessWidget {
  _Dialog(
    String value, {
    Key? key,
  })  : value = breakWord(value),
        super(key: key);

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(24.0),
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall,
        ),
        const Divider(),
        _DialogOption(
          onPressed: () {
            _pop(context, _DialogOptionKind.open);
          },
          title: "Open in browser",
        ),
        _DialogOption(
          onPressed: () {
            _pop(context, _DialogOptionKind.copy);
          },
          title: "Copy",
        ),
      ],
    );
  }

  void _pop(BuildContext context, _DialogOptionKind kind) {
    Navigator.maybeOf(context)?.pop(kind);
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
    return TextButton(
      onPressed: onPressed,
      child: Text(title),
    );
  }
}
