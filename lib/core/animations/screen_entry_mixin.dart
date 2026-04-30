import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

mixin ScreenEntryMixin {
  Widget entry(
    Widget child, {
    int delayMs = 0,
    int fadeMs = 220,
    int slideMs = 220,
    double slideBegin = 0.04,
  }) {
    return child
        .animate(delay: delayMs.ms)
        .fadeIn(duration: fadeMs.ms, curve: Curves.easeOut)
        .slideY(
          begin: slideBegin,
          duration: slideMs.ms,
          curve: Curves.easeOutCubic,
        );
  }

  List<Widget> staggerChildren(
    List<Widget> children, {
    int startDelayMs = 0,
    int stepMs = 50,
    int maxDelayMs = 200,
  }) {
    return <Widget>[
      for (int i = 0; i < children.length; i++)
        entry(
          children[i],
          delayMs: startDelayMs + (i * stepMs).clamp(0, maxDelayMs),
        ),
    ];
  }
}
