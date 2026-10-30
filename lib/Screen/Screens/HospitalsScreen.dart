import 'package:flutter/material.dart';

class HospitalsScreen extends StatefulWidget {
  @override
  _HospitalsScreenState createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Hospitals'),
      ),
      body: Center(
        child: Text('Find Hospitals'),
      ),
    );
  }
}
