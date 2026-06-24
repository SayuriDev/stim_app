import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stim_app/pages/settings.dart';

class SDPage extends StatefulWidget {
  const SDPage({super.key});

  @override
  State<SDPage> createState() => _SDPageState();
}

class _SDPageState extends State<SDPage> {
  final List<String> _files = [];
  StreamSubscription<String>? _fileSubscription;
  bool _isRequesting = false;
  String _status = 'Press refresh to load SD files';

  @override
  void initState() {
    super.initState();
    _fileSubscription = ble.filePathStream.listen((path) {
      if (!mounted) return;
      setState(() {
        if (!_files.contains(path)) {
          _files.add(path);
        }
      });
    });
  }

  @override
  void dispose() {
    _fileSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshFiles() async {
    if (!ble.isConnected.value) {
      setState(() {
        _status = 'Not connected. Open Settings to connect.';
      });
      return;
    }

    setState(() {
      _files.clear();
      _status = 'Requesting file list...';
      _isRequesting = true;
    });

    await ble.requestFileList();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _status = _files.isEmpty
          ? 'Waiting for file notifications...'
          : 'Received ${_files.length} files';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff191724),
      appBar: AppBar(
        foregroundColor: const Color(0xffe0def4),
        title: const Text(
          'File selection',
          style: TextStyle(
            color: Color(0xffe0def4),
            fontSize: 19,
          ),
        ),
        backgroundColor: const Color(0xff191724),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1.0, color: Color(0xff232136)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isRequesting ? null : _refreshFiles,
                    child: const Text('Refresh SD List'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _status,
              style: const TextStyle(
                color: Color(0xffe0def4),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xff232136),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _files.isEmpty
                    ? const Center(
                        child: Text(
                          'No file entries yet',
                          style: TextStyle(color: Color(0xff7f8198)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _files.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xff2e2b45)),
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              _files[index],
                              style: const TextStyle(color: Color(0xffe0def4)),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
