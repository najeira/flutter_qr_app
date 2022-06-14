import 'package:logger/logger.dart';

import 'env.dart';

const _level = Environment.isFlavorProd ? Level.warning : Level.verbose;

final Logger logger = Logger(
  level: _level,
  filter: ProductionFilter(),
  printer: SimplePrinter(
    printTime: false,
    colors: false,
  ),
);
