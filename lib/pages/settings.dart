import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        foregroundColor: Color(0xffe0def4),
        backgroundColor: Color(0xff191724),
      ),
      body: Center(
        child: Column(
          children: [
            Text(
              "Bluetooth",
              style: TextStyle(
                color: Color(0xffe0def4),
                fontSize: 20,
              ),
            ),
            Row(
               children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2a273f),
                    foregroundColor: Color(0xffe0def4),
                  ),
                  child: Text("Pair device/pair again"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff2a273f),
                    foregroundColor: Color(0xffe0def4),
                  ),
                  child: Text("Connect"), // TODO: connect/disconnect/not paired
                ),
              ],
            ),
            SizedBox(height: 10),
            PreferredSize(
              preferredSize: Size.fromHeight(1.0),
              child: Container(
                height: 1.0,
                color: Color(0xff232136),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xff191724)
    );
  }
}