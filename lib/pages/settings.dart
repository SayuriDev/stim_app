import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final controllerA = TextEditingController();
final controllerB = TextEditingController();


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
                  child: Text("Pair device/pair again"),
                ),
                ElevatedButton(
                  onPressed: () {},
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
            SizedBox(height: 10),
            Text(
              "Limits",
              style: TextStyle(
                color: Color(0xffe0def4),
                fontSize: 20,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "CHANNEL A",
                      style: TextStyle(
                        color: Color(0xff797593),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                        keyboardType: TextInputType.numberWithOptions(decimal: false),
                        controller: controllerA,
                        // TODO: initialValue
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xffe0def4)),
                        cursorColor: Color(0xffe0def4),
                        onChanged: (value) {
                          // make sure that the value cannot exceed 255
                          final number = int.tryParse(value);
                          if (number != null && number > 255) {
                            controllerA.text = "255";
                            controllerA.selection = TextSelection.fromPosition(
                              TextPosition(offset: controllerA.text.length),
                              );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "CHANNEL B",
                      style: TextStyle(
                        color: Color(0xff797593),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                        keyboardType: TextInputType.numberWithOptions(decimal: false),
                        controller: controllerB,
                        // TODO: initialValue
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xffe0def4)),
                        cursorColor: Color(0xffe0def4),
                        onChanged: (value) {
                          // make sure that the value cannot exceed 255
                          final number = int.tryParse(value);
                          if (number != null && number > 255) {
                            controllerB.text = "255";
                            controllerB.selection = TextSelection.fromPosition(
                              TextPosition(offset: controllerB.text.length),
                              );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                // ElevatedButton(onPressed: () {}, child: Text("Limits"))
              ],
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {} /* TODO: add save functionality */,
              child: Text("SAVE"))
          ],
        ),
      ),
      backgroundColor: Color(0xff191724)
    );
  }
}