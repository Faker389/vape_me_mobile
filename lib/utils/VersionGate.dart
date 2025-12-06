import 'package:flutter/material.dart';
import 'package:vape_me/screens/UpdateScreen.dart';
import 'package:vape_me/screens/auth/welcome_screen.dart';
import 'package:vape_me/screens/main_screen.dart';
import 'package:vape_me/utils/AppVersionHolder.dart';

class VersionGate extends StatefulWidget {
  final int index;
  const VersionGate({super.key, required this.index});
  @override
  _VersionGateState createState() => _VersionGateState();
}

class _VersionGateState extends State<VersionGate> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkVersion();
  });  
  }

  Future<void> _checkVersion() async {
    // get current version from Firestore
     if (AppVersionHolder.firestoreVersion > AppVersionHolder.appVersion) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => UpdateScreen()),
      );
    }else{
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.index==1?MainScreen():WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}