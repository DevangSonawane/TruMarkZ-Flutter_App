import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/deep_link_service.dart';
import '../core/theme/theme_controller.dart';
import 'trumarkz_app.dart';

class TruMarkZBootstrapApp extends StatefulWidget {
  const TruMarkZBootstrapApp({super.key});

  @override
  State<TruMarkZBootstrapApp> createState() => _TruMarkZBootstrapAppState();
}

class _TruMarkZBootstrapAppState extends State<TruMarkZBootstrapApp> {
  late final Future<ThemeController> _controllerFuture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = ThemeController.create();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await DeepLinkService.init(ProviderScope.containerOf(context));
    });
  }

  @override
  void dispose() {
    DeepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ThemeController>(
      future: _controllerFuture,
      builder: (BuildContext context, AsyncSnapshot<ThemeController> snapshot) {
        final ThemeController? controller = snapshot.data;
        if (controller == null) {
          return const TrumarkzAppLoadingShell();
        }
        return TruMarkZApp(themeController: controller);
      },
    );
  }
}
