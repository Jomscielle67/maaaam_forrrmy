import 'package:daddies_store/admin/views/admin_main_screen.dart';
import 'package:daddies_store/provider/product_provider.dart';
import 'package:daddies_store/providers/theme_provider.dart';
import 'package:daddies_store/vendor/views/auth/vendor_registration_screen.dart';
import 'package:daddies_store/vendor/views/screens/main_vendor_screen.dart';
import 'package:daddies_store/views/buyers/main_screen.dart';
import 'package:daddies_store/views/buyers/auth/login_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/cart_screen.dart';
import 'package:daddies_store/views/buyers/nav_screens/search_screen.dart';
import 'package:daddies_store/delivery/delivery_views/courier_dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:daddies_store/models/cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBPLEmCd-X2H96lYXIu3pJq0czAko-gwhs",
        projectId: "daddy-ecom-store",
        storageBucket: "daddy-ecom-store.firebasestorage.app",
        messagingSenderId: "327933117316",
        appId: "1:327933117316:web:34990266d2c722fd3793d1",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // Initialize Firebase App Check with debug provider for development
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      );
    }
    
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Daddies Store',
          theme: themeProvider.theme,
          home: const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/cart': (context) => const CartScreen(),
            '/search': (context) => const SearchScreen(),
            '/courier': (context) => const CourierDashboard(),
          },
          builder: EasyLoading.init(),
        );
      },
    );
  }
}
