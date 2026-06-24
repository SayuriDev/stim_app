import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stim_app/pages/settings.dart';

const Color _backgroundColor = Color(0xff191724);
const Color _surfaceColor = Color(0xff232136);
const Color _surfaceAltColor = Color(0xff2e2b45);
const Color _textColor = Color(0xffe0def4);
const Color _mutedTextColor = Color(0xff7f8198);

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
  late final ScrollController _scrollController;
  bool _isRequesting = false;
  String _status = 'Press refresh to load SD folders';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fileSubscription = ble.filePathStream.listen((path) {
      try {
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
            () => FolderNode(
              segment,
              node.path.isEmpty ? segment : '${node.path}/$segment',
            ),
          );
        }

        setState(() {
          if (!node.files.contains(fileName)) {
            node.files.add(fileName);
          }
        });
      } catch (e, st) {
        // Prevent a parsing/runtime error in the listener from crashing the app.
        // Log the error for troubleshooting.
        // ignore: avoid_print
        print('SD file stream handler error: $e\n$st');
      }
    });
  }

  @override
  void dispose() {
    _fileSubscription?.cancel();
    _scrollController.dispose();
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
    childWidgets.addAll(
      sortedFiles.map((fileName) {
        return Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            leading: const Icon(
              Icons.insert_drive_file,
              size: 20,
              color: _mutedTextColor,
            ),
            title: Text(fileName, style: const TextStyle(color: _textColor)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
            onTap: () {
              // TODO: implement file open/download action
            },
          ),
        );
      }),
    );

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
        childrenPadding: const EdgeInsets.only(bottom: 8.0),
        collapsedBackgroundColor: _surfaceColor,
        backgroundColor: _surfaceColor,
        collapsedIconColor: _textColor,
        iconColor: _textColor,
        leading: Icon(
          node.name.isEmpty ? Icons.storage : Icons.folder,
          color: _textColor,
        ),
        title: Text(
          node.name.isEmpty ? '(root)' : node.name,
          style: const TextStyle(
            color: _textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: node.name.isEmpty
            ? null
            : Text(
                '${node.children.length} folders · ${node.files.length} files',
                style: const TextStyle(color: _mutedTextColor, fontSize: 12),
              ),
        children: childWidgets.isEmpty
            ? [
                const ListTile(
                  title: Text(
                    'No files',
                    style: TextStyle(color: _mutedTextColor),
                  ),
                ),
              ]
            : childWidgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        foregroundColor: _textColor,
        title: const Text(
          'Select File',
          style: TextStyle(
            color: _textColor,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _backgroundColor,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _textColor,
                      foregroundColor: _backgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: _isRequesting ? null : _refreshFiles,
                    child: const Text('Refresh SD List'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _status,
              style: const TextStyle(color: Color(0xffe0def4), fontSize: 14),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: _rootFolder.children.isEmpty &&
                          _rootFolder.files.isEmpty
                      ? const Center(
                          child: Text(
                            'No folder entries yet',
                            style: TextStyle(color: _mutedTextColor),
                          ),
                        )
                      : Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          radius: Radius.circular(10),
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            itemCount: _rootFolder.children.length +
                                (_rootFolder.files.isNotEmpty ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(
                              color: _surfaceAltColor,
                              height: 1,
                            ),
                            itemBuilder: (context, index) {
                              final rootChildren =
                                  _rootFolder.children.keys.toList()..sort();
                              if (index < rootChildren.length) {
                                final node =
                                    _rootFolder.children[rootChildren[index]]!;
                                return _buildFolderTile(node);
                              }

                              final files = _rootFolder.files.toList()..sort();
                              return Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  childrenPadding: const EdgeInsets.only(
                                    bottom: 8.0,
                                  ),
                                  collapsedBackgroundColor: _surfaceColor,
                                  backgroundColor: _surfaceColor,
                                  collapsedIconColor: _textColor,
                                  iconColor: _textColor,
                                  leading: const Icon(
                                    Icons.storage,
                                    color: _textColor,
                                  ),
                                  title: const Text(
                                    '(root)',
                                    style: TextStyle(
                                      color: _textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${files.length} files',
                                    style: const TextStyle(
                                      color: _mutedTextColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  children: files.isEmpty
                                      ? [
                                          const ListTile(
                                            title: Text(
                                              'No files',
                                              style: TextStyle(
                                                color: _mutedTextColor,
                                              ),
                                            ),
                                          ),
                                        ]
                                      : files.map((f) {
                                          return Material(
                                            color: Colors.transparent,
                                            child: ListTile(
                                              dense: true,
                                              leading: const Icon(
                                                Icons.insert_drive_file,
                                                size: 20,
                                                color: _mutedTextColor,
                                              ),
                                              title: Text(
                                                f,
                                                style: const TextStyle(
                                                  color: _textColor,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24.0,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
