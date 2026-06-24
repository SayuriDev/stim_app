import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class FileEntry {
  final List<String> parts;

  FileEntry(this.parts);

  String get name => parts.last;

  String get path => parts.join("/");

  bool get isFile => parts.isNotEmpty;
}

List<FileEntry> parseFile(String data) {
  final List<dynamic> jsonArr = jsonDecode(data);

  return [
    FileEntry(List<String>.from(jsonArr))
  ];
}

