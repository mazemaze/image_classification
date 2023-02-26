import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
        AlbumPage.routeName: (ctx) => const AlbumPage(),
        CameraPage.routeName: (ctx) => const CameraPage(),
      },
      home: const HomePage(),
    );
  }
}

class AlbumPage extends StatefulWidget {
  const AlbumPage({super.key});

  static const routeName = 'gallery';

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  List<ImageData>? _data;

  @override
  void initState() {
    insertData();
    super.initState();
  }

  void insertData() async {
    _data = await DBService().getAllImageData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _data != null
          ? GridView.count(
              crossAxisCount: _data!.length,
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
    controller = CameraController(_cameras[0], ResolutionPreset.max);
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
    final directory = await getApplicationSupportDirectory();
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
              await takePhoto();
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

class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key, required this.imageFile});
  final File imageFile;
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
                meta: "nothing",
              );
              await DBService().insertImageData(imageData);
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
