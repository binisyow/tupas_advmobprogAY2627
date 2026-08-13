import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
 
// This is where the app starts.
// We use ChangeNotifierProvider para ma-share yung ThemeModel
// sa buong app.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const MyApp(),
    ), // ChangeNotifierProvider
  );
}
 
// Main widget ng app.
// Dito chine-check kung light mode or dark mode
// ang current theme ng app.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);
 
    return MaterialApp(
      theme: themeModel.isDark ? ThemeData.dark() : ThemeData.light(),
      home: const MyHomePage(), // First page na makikita pag-open ng app.
    ); // MaterialApp
  }
}
 
// ThemeModel stores the current theme of the app.
// Since Provider ang gamit, pwede itong ma-access
// ng kahit anong screen.
class ThemeModel with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;
 
  // This function changes the theme
  // then updates all widgets na gumagamit ng ThemeModel.
  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
 
// First screen ng app.
// Counter lang ang feature dito using setState().
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
 
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
 
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; // Counter value for this page only.
 
  // Every click sa button,
  // madadagdagan ng 1 yung counter.
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral State Example'),
        actions: [
          // Button para pumunta sa Theme page.
          IconButton(
            icon: const Icon(Icons.settings_brightness),
            tooltip: 'Go to theme settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyHome()),
              );
            },
          ), // IconButton
        ],
      ), // AppBar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ), // Displays the current counter value.
          ], // Widgets
        ), // Column
      ), // Center
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // Button to increase the counter.
    ); // Scaffold
  }
}
 
// Second screen ng app.
// Dito tine-test yung Provider
// by changing the app theme.
class MyHome extends StatelessWidget {
  const MyHome({super.key});
 
  @override
  Widget build(BuildContext context) {
    final themeModel = Provider.of<ThemeModel>(context);
 
    return Scaffold(
      appBar: AppBar(
        title: const Text('App State Example'),
        actions: [
          // Switch for changing
          // between Light Mode and Dark Mode.
          Switch(
            value: themeModel.isDark,
            onChanged: (_) => themeModel.toggleTheme(),
          ), // Switch
        ],
      ), // AppBar
      body: const Center(
        child: Text('Toggle the theme using the switch in the app bar.'),
      ), // Center
    ); // Scaffold
  }
}
 
// setState
//vs
// Provider
// setState()
// - Ginamit sa counter page.
// - Local lang yung state.
// - Best gamitin for simple features tulad ng counter.
// - Hindi siya shared sa ibang screens.
//
// Provider
// - Ginamit sa theme page.
// - Shared yung state sa buong app.
// - Any screen can read or update the theme.
// - Useful kapag maraming widgets ang gumagamit ng same data.