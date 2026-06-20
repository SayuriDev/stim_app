import 'package:flutter/material.dart';
import 'package:stim_app/pages/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String batteryStatus = "Not Connected";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff191724),

      appBar: AppBar(
        centerTitle: true,
        title: Text(
          batteryStatus,
          style: TextStyle(
            color:Color(0xffe0def4),
            fontSize: 19
          )),
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
            children:[
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage(),
                      ),
                    );
                  },
                   child: Text("Settings"),
                   ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(

                    fixedSize: Size.square(75),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    backgroundColor: Color(0xffeb6f92),
                    foregroundColor: Color(0xffe0def4),
                  ),
                  child: Text(
                    "PANIC",
                    style: TextStyle(
                      color:Color(0xffe0def4),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        // overflow: TextOverflow.ellipsis,
                    ),
                  )
              ]
            ),
        ),
    );
  }
}