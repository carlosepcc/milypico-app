import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/pos_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(const MilypicoApp());
}

class MilypicoApp extends StatelessWidget {
  const MilypicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => POSProvider()),
      ],
      child: Consumer<POSProvider>(
        builder: (context, pos, _) {
          const seed = Color(0xFF006C4C); // Material 3 Emerald/Teal seed

          ThemeMode themeMode = ThemeMode.system;
          if (pos.settings.theme == 'dark') {
            themeMode = ThemeMode.dark;
          } else if (pos.settings.theme == 'light') {
            themeMode = ThemeMode.light;
          }

          return MaterialApp(
            title: 'Milypico POS',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                scrolledUnderElevation: 2.0,
              ),
              cardTheme: CardTheme(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                showDragHandle: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              navigationBarTheme: const NavigationBarThemeData(
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                scrolledUnderElevation: 2.0,
              ),
              cardTheme: CardTheme(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                showDragHandle: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
              ),
              snackBarTheme: SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              navigationBarTheme: const NavigationBarThemeData(
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
