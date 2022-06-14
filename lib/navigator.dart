import 'package:flutter/material.dart';

Future<T?> pushDialog<T>(BuildContext context, WidgetBuilder builder) {
  final nav = Navigator.of(context, rootNavigator: true);
  return pushDialogToNavigator(nav, builder);
}

Future<T?> pushDialogToNavigator<T>(NavigatorState nav, WidgetBuilder builder) {
  return nav.push(MaterialPageRoute<T>(
    builder: builder,
    fullscreenDialog: true,
  ));
}
