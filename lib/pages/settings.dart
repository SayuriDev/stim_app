import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stim_app/ble.dart';
import 'package:stim_app/pages/scan.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;

final controllerA = TextEditingController();
final controllerB = TextEditingController();

final Ble ble = Ble();

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    loadPrefs();
    ble.tryAutoConnect();
    // send saved data when ble is connected
    ble.isConnected.addListener(_sendSavedLimitsIfConnected);
  }

  @override
  void dispose() {
    ble.isConnected.removeListener(_sendSavedLimitsIfConnected);
    super.dispose();
  }

    void _sendSavedLimitsIfConnected() {
    if (ble.isConnected.value) {
      final a = int.tryParse(controllerA.text) ?? 0;
      final b = int.tryParse(controllerB.text) ?? 0;
      ble.writeArray([0, a]);
      ble.writeArray([1, b]);
    }
  }

  Future<void> loadPrefs() async {
    prefs = await SharedPreferences.getInstance();

    final a = prefs.getInt('a') ?? 0;
    final b = prefs.getInt('b') ?? 0;

    controllerA.text = a.toString();
    controllerB.text = b.toString();

    _sendSavedLimitsIfConnected();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        foregroundColor: Color(0xffe0def4),
        backgroundColor: Color(0xff191724),
      ),
      body: Container(
        margin: const EdgeInsets.only(left: 10.0, right: 10, top: 5.0),

        child: Column(
          children: [
            Text(
              "Bluetooth",
              style: TextStyle(
                color: Color(0xffe0def4),
                fontSize: 19,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: ble.isConnected,
              builder: (context, value, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (ble.isConnected.value) {
                          ble.disconnect();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ScanPage()),
                          );
                        }
                            },
                      child: Text(value ? "Disconnect" : "Connect"),
                    ),
                    Text(
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight(500),
                        color: value ? Color(0xff56949f) : Color(0xffeb6f92),
                      ),
                      value ? "Connected" : "Not Connected",
                    )
                  ],
                );
              },
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
                fontSize: 19,
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
                          final number = int.tryParse(value) ?? 0;
                          if (number > 255) {
                            controllerA.text = "255";
                            controllerA.selection = TextSelection.fromPosition(
                              TextPosition(offset: controllerA.text.length),
                            );
                          }
                          ble.writeArray([0, number]);
                            return;
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
              onPressed: () async {
                await prefs.setInt('a', int.tryParse(controllerA.text) ?? 0);
                await prefs.setInt('b', int.tryParse(controllerB.text) ?? 0);

                ble.writeArray([0, int.tryParse(controllerA.text) ?? 0]);
                ble.writeArray([1, int.tryParse(controllerB.text) ?? 0]);
              },
              child: Text("SAVE"))
          ],
        ),
      ),
      backgroundColor: Color(0xff191724)
    );
  }
}