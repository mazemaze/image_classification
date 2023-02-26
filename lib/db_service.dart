// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBService {
  final String _dbName = 'image_database.db';
  final int _curVersion = 1;
  final String _tableName = 'image';
  Future<Database> dbInit() async {
    return openDatabase(
      join(await getDatabasesPath(), _dbName),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE image(id INTEGER PRIMARY KEY, path TEXT, meta TEXT)',
        );
      },
      version: _curVersion,
    );
  }

  Future<void> insertImageData(ImageData data) async {
    final Database db = await dbInit();
    await db.insert(
      _tableName,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ImageData>> getAllImageData() async {
    final Database db = await dbInit();
    final List<Map<String, dynamic>> maps = await db.query(_tableName);
    return maps.map((e) => ImageData.fromMap(e)).toList();
  }
}

class ImageData {
  final int? id;
  final String? path;
  final String? meta;

  ImageData({
    this.id,
    this.path,
    required this.meta,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'path': path,
      'meta': meta,
    };
  }

  factory ImageData.fromMap(Map<String, dynamic> map) {
    return ImageData(
      id: map['id'] != null ? map['id'] as int : null,
      path: map['path'] != null ? map['path'] as String : null,
      meta: map['meta'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory ImageData.fromJson(String source) => ImageData.fromMap(json.decode(source) as Map<String, dynamic>);

  ImageData copyWith({
    int? id,
    String? path,
    String? meta,
  }) {
    return ImageData(
      id: id ?? this.id,
      path: path ?? this.path,
      meta: meta ?? this.meta,
    );
  }

  @override
  String toString() => 'ImageData(id: $id, path: $path, meta: $meta)';

  @override
  bool operator ==(covariant ImageData other) {
    if (identical(this, other)) return true;

    return other.id == id && other.path == path && other.meta == meta;
  }

  @override
  int get hashCode => id.hashCode ^ path.hashCode ^ meta.hashCode;
}
