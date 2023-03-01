import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:image_classification/db_service.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'home_page.dart';

late List<CameraDescription> _cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        GalleryPage.routeName: (ctx) => const GalleryPage(),
        CameraPage.routeName: (ctx) => const CameraPage(),
        CollectionPage.routeName: (ctx) => const CollectionPage(),
      },
      home: const HomePage(),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  static const routeName = 'gallery';

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<ImageData>? _data;

  @override
  void initState() {
    super.initState();
  }

  void insertData(int? id) async {
    if (id == null) {
      _data = await DBService().getAllImageData();
      setState(() {});
      return;
    }
    _data = await DBService().queryImageData(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as int?;
    if (_data == null) {
      insertData(id);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("ギャラリー"),
      ),
      body: _data != null
          ? GridView.count(
              crossAxisCount: 3,
              children: _data!
                  .map(
                    (e) => Container(
                      child: Image.file(File(e.path!)),
                    ),
                  )
                  .toList(),
            )
          : Center(
              child: Container(
                child: const Text("データが存在しません"),
              ),
            ),
    );
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  static const routeName = 'camera_view';
  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController controller;
  late File? takenPhoto;

  @override
  void initState() {
    controller = CameraController(
      _cameras[0],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            break;
          default:
            break;
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future takePhoto() async {
    final photo = await controller.takePicture();
    final directory = await getLibraryDirectory();
    String path = "";

    path = join(directory.path, '${DateTime.now()}.png');
    await photo.saveTo(path);
    takenPhoto = File(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CameraPreview(
            controller,
          ),
          ElevatedButton(
            onPressed: () async {
              final text = await takePhoto();
              if (takenPhoto != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (builder) => PreviewPage(
                      imageFile: takenPhoto!,
                    ),
                  ),
                );
              }
            },
            child: const Icon(
              Icons.photo,
            ),
          )
        ],
      ),
    );
  }
}

class CollectionPage extends StatefulWidget {
  const CollectionPage({super.key});

  static const routeName = 'collections';

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  List<MetaModel>? _data;
  List<Widget>? _widgets;

  @override
  void initState() {
    super.initState();
  }

  void insertData(BuildContext context) async {
    List<Widget> temp = [];
    final db = DBService();
    _data = await DBService().getAllMetaData();
    final allThumbnail = await DBService().getImageData();
    temp.add(GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(GalleryPage.routeName),
      child: Column(
        children: [
          Expanded(
            child: Image.file(
              File(allThumbnail.path!),
              fit: BoxFit.cover,
            ),
          ),
          const Text("全ての画像")
        ],
      ),
    ));
    for (var e in _data!) {
      final result = await db.queryImageData(e.id!);
      temp.add(
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(GalleryPage.routeName, arguments: e.id),
          child: Column(
            children: [
              Expanded(
                child: Image.file(
                  File(result.first.path!),
                  fit: BoxFit.cover,
                ),
              ),
              Text(e.title ?? "")
            ],
          ),
        ),
      );
    }

    setState(() {
      _widgets = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_widgets == null) {
      insertData(context);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("ギャラリー"),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        children: _widgets ?? [],
      ),
    );
  }
}

class PreviewPage extends StatelessWidget {
  const PreviewPage({
    super.key,
    required this.imageFile,
  });

  final File imageFile;

  static const routeName = 'preview';

  Future processImage(String path, int id) async {
    if (id == 0) {
      return;
    }
    final InputImage imageFile = InputImage.fromFilePath(path);
    final ImageLabelerOptions options = ImageLabelerOptions(confidenceThreshold: 0.7);
    final ImageLabeler imageLabeler = ImageLabeler(options: options);
    final List<ImageLabel> labels = await imageLabeler.processImage(imageFile);
    for (ImageLabel label in labels) {
      final meta = MetaModel(title: label.label);
      await DBService().insertMetaData(meta);
      final metaId = await DBService().queryMetaData(label.label);
      if (metaId == null) {
        continue;
      }
      final imageMeta = ImageMetaData(imageId: id, metaId: metaId.id);
      print(imageMeta);
      await DBService().insertImageMetaData(imageMeta);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Container(
            child: Image.file(imageFile),
          ),
          ElevatedButton(
            onPressed: () async {
              final imageData = ImageData(
                path: imageFile.path,
              );
              final insertedId = await DBService().insertImageData(imageData);
              await processImage(imageFile.path, insertedId);
              Navigator.of(context)
                ..pop()
                ..pop();
            },
            child: const Text("保存"),
          )
        ],
      ),
    );
  }
}
