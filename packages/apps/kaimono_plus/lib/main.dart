import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/kaimono_list_page/kaimono_list_page_view_model.dart';
import 'pages/sign_in_page/sign_in_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KaimonoListPageViewModel()),
      ],
      child: MaterialApp(
        title: 'Kaimono Plus',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const SignInPage(),
      ),
    );
  }
}
