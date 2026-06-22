import 'package:flutter/material.dart';
import 'package:stim_app/pages/settings.dart';

class SDPage extends StatefulWidget {
  const SDPage({super.key});

  @override
  State<SDPage> createState() => _SDPageState();
}

class _SDPageState extends State<SDPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff191724),
      appBar: AppBar(
        foregroundColor: Color(0xffe0def4),
        title: Text(
          'File selection',
          style: TextStyle(
            color: Color(0xffe0def4),
            fontSize: 19,
          ),
        ),
        backgroundColor: Color(0xff191724),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
           child: Container(
            height: 1.0,
            color: Color(0xff232136),
           )),
        
      ),
      body: Container(
          margin: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textBaseline:TextBaseline.alphabetic,
            children: [
              
            ]
            ),
        ),
    );
  }
}