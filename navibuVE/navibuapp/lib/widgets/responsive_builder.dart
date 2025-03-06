import 'package:flutter/material.dart';
import '../utils/size_config.dart';

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, SizeConfig config) builder;

  const ResponsiveBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return builder(context, SizeConfig());
  }
} 