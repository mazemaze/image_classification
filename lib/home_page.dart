import 'package:flutter/material.dart';
import 'package:image_classification/main.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(CollectionPage.routeName),
              child: const Text("ギャラリー"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed(CameraPage.routeName),
              child: const Text("写真を撮る"),
            ),
          ],
        ),
      ),
    );
  }
}
