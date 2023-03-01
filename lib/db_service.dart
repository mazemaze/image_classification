// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBService {
  final String _dbName = 'image_database.db';
  final int _curVersion = 1;
  final String _imageTableName = 'image';
  final String _metaTableName = 'meta';
  final String _imageMetaTableName = 'image_meta';

  Future<Database> dbInit() async {
    return openDatabase(
      join(await getDatabasesPath(), _dbName),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE image(id INTEGER PRIMARY KEY, path TEXT) ',
        );
        await db.execute(
          'CREATE TABLE $_metaTableName(id INTEGER PRIMARY KEY, title UNIQUE TEXT)',
        );
        await db.execute(
          'CREATE TABLE $_imageMetaTableName(id INTEGER PRIMARY KEY, imageId INTEGER, metaId)',
        );
      },
      onUpgrade: (Database db, oldVersion, newVersion) async {},
      version: _curVersion,
    );
  }

  Future<int> insertImageData(ImageData data) async {
    final Database db = await dbInit();
    return await db.insert(
      _imageTableName,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ImageData>> getAllImageData() async {
    final Database db = await dbInit();
    final List<Map<String, dynamic>> maps = await db.query(_imageTableName);
    return maps.map((e) => ImageData.fromMap(e)).toList();
  }

  Future<void> deleteImageData(ImageData data) async {
    final Database db = await dbInit();
    await db.delete(_imageTableName, where: 'id = ?', whereArgs: [data.id]);
  }

  Future<List<ImageData>> queryImageData(int metaId) async {
    List<ImageData> imageDataList = [];
    final Database db = await dbInit();
    List<Map<String, dynamic>> data = await db.query(_imageMetaTableName, where: 'metaId = ?', whereArgs: [metaId]);
    final List<ImageMetaData> imageMetaList = data.map((e) => ImageMetaData.fromMap(e)).toList();
    print(await db.query(_metaTableName));
    for (var imageMeta in imageMetaList) {
      data = await db.query(_imageTableName, where: 'id = ?', whereArgs: [imageMeta.imageId]);
      imageDataList.add(ImageData.fromMap(data.first));
    }
    return imageDataList;
  }

  Future<ImageData> getImageData() async {
    final Database db = await dbInit();
    final List<Map<String, dynamic>> maps = await db.query(_imageTableName);
    return ImageData.fromMap(maps.first);
  }

  Future<List<MetaModel>> getAllMetaData() async {
    final Database db = await dbInit();
    final List<Map<String, dynamic>> maps = await db.query(_metaTableName);
    return maps.map((e) => MetaModel.fromMap(e)).toList();
  }

  Future<int> insertMetaData(MetaModel data) async {
    final id = DateTime.now().microsecondsSinceEpoch;
    final Database db = await dbInit();
    return await db.rawInsert(
      "INSERT INTO $_metaTableName (id, title) VALUES(?, ?) ON CONFLICT(title) DO NOTHING",
      [id, data.title],
    );
  }

  Future<MetaModel?> queryMetaData(String title) async {
    final Database db = await dbInit();
    final List<Map<String, dynamic>> maps = await db.query(_metaTableName, where: "title = ?", whereArgs: [title]);
    if (maps.isNotEmpty) {
      return maps.map((e) => MetaModel.fromMap(e)).toList().first;
    }
    return null;
  }

  Future<int> insertImageMetaData(ImageMetaData data) async {
    final Database db = await dbInit();
    print(data);
    return await db.insert(
      _imageMetaTableName,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class ImageMetaData {
  final int? id;
  final int? imageId;
  final int? metaId;

  ImageMetaData({
    this.id,
    this.imageId,
    this.metaId,
  });

  ImageMetaData copyWith({
    int? id,
    int? imageId,
    int? metaId,
  }) {
    return ImageMetaData(
      id: id ?? this.id,
      imageId: imageId ?? this.imageId,
      metaId: metaId ?? this.metaId,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'imageId': imageId,
      'metaId': metaId,
    };
  }

  factory ImageMetaData.fromMap(Map<String, dynamic> map) {
    return ImageMetaData(
      id: map['id'] != null ? map['id'] as int : null,
      imageId: map['imageId'] != null ? map['imageId'] as int : null,
      metaId: map['metaId'] != null ? map['metaId'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ImageMetaData.fromJson(String source) => ImageMetaData.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'ImageMetaData(id: $id, imageId: $imageId, metaId: $metaId)';

  @override
  bool operator ==(covariant ImageMetaData other) {
    if (identical(this, other)) return true;

    return other.id == id && other.imageId == imageId && other.metaId == metaId;
  }

  @override
  int get hashCode => id.hashCode ^ imageId.hashCode ^ metaId.hashCode;
}

class ImageData {
  final int? id;
  final String? path;

  ImageData({
    this.id,
    this.path,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'path': path,
    };
  }

  factory ImageData.fromMap(Map<String, dynamic> map) {
    return ImageData(
      id: map['id'] != null ? map['id'] as int : null,
      path: map['path'] != null ? map['path'] as String : null,
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
    );
  }

  @override
  String toString() => 'ImageData(id: $id, path: $path, meta: )';

  @override
  bool operator ==(covariant ImageData other) {
    if (identical(this, other)) return true;

    return other.id == id && other.path == path;
  }

  @override
  int get hashCode => id.hashCode ^ path.hashCode;
}

class MetaModel {
  final int? id;
  final String? title;

  MetaModel({
    this.id,
    required this.title,
  });

  MetaModel copyWith({
    int? id,
    String? title,
  }) {
    return MetaModel(
      id: id ?? this.id,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
    };
  }

  factory MetaModel.fromMap(Map<String, dynamic> map) {
    return MetaModel(
      id: map['id'] != null ? map['id'] as int : null,
      title: map['title'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory MetaModel.fromJson(String source) => MetaModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'MetaData(id: $id, title: $title)';

  @override
  bool operator ==(covariant MetaModel other) {
    if (identical(this, other)) return true;

    return other.id == id && other.title == title;
  }

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}
