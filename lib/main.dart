import 'package:flutter/material.dart';
import 'Pages/employee_login_page.dart';
import 'Pages/request_form_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GatePass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const EmployeeLoginPage(),
        '/requestForm': (context) => const RequestFormPage(),
      },
    );
  }
}
