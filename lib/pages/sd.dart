import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stim_app/pages/settings.dart';

class SDPage extends StatefulWidget {
  const SDPage({super.key});

  @override
  State<SDPage> createState() => _SDPageState();
}

class FolderNode {
  final String name;
  final String path;
  final Map<String, FolderNode> children = {};
  final List<String> files = [];

  FolderNode(this.name, [this.path = '']);

  int get folderCount {
    int count = children.length;
    for (final child in children.values) {
      count += child.folderCount;
    }
    return count;
  }
}

class _SDPageState extends State<SDPage> {
  FolderNode _rootFolder = FolderNode('');
  StreamSubscription<String>? _fileSubscription;
  bool _isRequesting = false;
  String _status = 'Press refresh to load SD folders';

  @override
  void initState() {
    super.initState();
    _fileSubscription = ble.filePathStream.listen((path) {
      if (!mounted) return;

      final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
      final segments = normalizedPath.split('/');
      if (segments.isEmpty) return;

      if (segments.length > 1 && segments.first.toLowerCase() == 'sd') {
        segments.removeAt(0);
      }
      if (segments.isEmpty) return;

      final fileName = segments.removeLast();
      FolderNode node = _rootFolder;
      for (final segment in segments) {
        node = node.children.putIfAbsent(
          segment,
          () => FolderNode(segment, node.path.isEmpty ? segment : '${node.path}/$segment'),
        );
      }

      setState(() {
        if (!node.files.contains(fileName)) {
          node.files.add(fileName);
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
      _rootFolder = FolderNode('');
      _status = 'Requesting file list...';
      _isRequesting = true;
    });

    await ble.requestFileList();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _status = _rootFolder.folderCount == 0
          ? 'Waiting for folder notifications...'
          : 'Received ${_rootFolder.folderCount} folders';
    });
  }

  Widget _buildFolderTile(FolderNode node) {
    final sortedChildren = node.children.keys.toList()..sort();
    final sortedFiles = node.files.toList()..sort();

    final childWidgets = <Widget>[];
    for (final childName in sortedChildren) {
      childWidgets.add(_buildFolderTile(node.children[childName]!));
    }
    childWidgets.addAll(sortedFiles.map((fileName) {
      return Material(
        color: Colors.transparent,
        child: ListTile(
          title: Text(
            fileName,
            style: const TextStyle(color: Color(0xffe0def4)),
          ),
          onTap: () {
            // TODO: implement file open/download action
          },
        ),
      );
    }));

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
        title: Text(
          node.name.isEmpty ? '(root)' : node.name,
          style: const TextStyle(color: Color(0xffe0def4)),
        ),
        backgroundColor: const Color(0xff232136),
        children: childWidgets.isEmpty
            ? [
                const ListTile(
                  title: Text(
                    'No files',
                    style: TextStyle(color: Color(0xff7f8198)),
                  ),
                )
              ]
            : childWidgets,
      ),
    );
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
                child: _rootFolder.children.isEmpty && _rootFolder.files.isEmpty
                    ? const Center(
                        child: Text(
                          'No folder entries yet',
                          style: TextStyle(color: Color(0xff7f8198)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _rootFolder.children.length + (_rootFolder.files.isNotEmpty ? 1 : 0),
                        separatorBuilder: (_, _) => const Divider(color: Color(0xff2e2b45)),
                        itemBuilder: (context, index) {
                          final rootChildren = _rootFolder.children.keys.toList()..sort();
                          if (index < rootChildren.length) {
                            final node = _rootFolder.children[rootChildren[index]]!;
                            return _buildFolderTile(node);
                          }

                          final files = _rootFolder.files..sort();
                          return Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
                              title: const Text(
                                '(root)',
                                style: TextStyle(color: Color(0xffe0def4)),
                              ),
                              backgroundColor: const Color(0xff232136),
                              children: files.isEmpty
                                  ? [
                                      const ListTile(
                                        title: Text(
                                          'No files',
                                          style: TextStyle(color: Color(0xff7f8198)),
                                        ),
                                      )
                                    ]
                                  : files.map((f) {
                                      return Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          title: Text(
                                            f,
                                            style: const TextStyle(color: Color(0xffe0def4)),
                                          ),
                                          onTap: () {
                                            // TODO: implement file open/download action
                                          },
                                        ),
                                      );
                                    }).toList(),
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
