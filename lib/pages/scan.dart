import 'package:flutter/material.dart';
import 'package:stim_app/ble.dart';
import 'package:stim_app/pages/settings.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';


class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}
class _ScanPageState extends State<ScanPage> {
@override
void initState() {
  super.initState();

ble.init().then((result) {
  if (!mounted) return;

  switch (result) {
    case BleInitResult.ok:
      break;

    case BleInitResult.notSupported:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bluetooth not supported")),
      );

      Future.microtask(() {
        if (mounted) Navigator.pop(context);
      });
      break;

    case BleInitResult.disabled:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enable Bluetooth")),
      );

      Future.microtask(() {
        if (mounted) Navigator.pop(context);
      });
      break;
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff191724),

      appBar: AppBar(
        centerTitle: true,
        title: Text("data")
        
      ),
      body: StreamBuilder<List<ScanResult>>(
        stream: ble.results,
        builder: (context, snapshot) {
          final devices = snapshot.data ?? [];

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, i) {
              final d = devices[i];

              return ListTile(
                title: Text(
                  d.device.platformName.isEmpty
                    ? "Unknown"
                    : d.device.platformName,
                  style: const TextStyle(color: Color(0xffe0def4) ),
                ),
                subtitle: Text(
                  d.device.remoteId.toString(),
                  style: const TextStyle(color: Color(0xff908caa) ),
                ),
                onTap: () async {
                  try {
                    await ble.connect(d.device);
                    setState(() {});

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Connected")),
                    );

                    Navigator.pop(context);
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Connection failed")),
                    );
                  }
                }
              );
            },
          );
        }
      ));
  }
}