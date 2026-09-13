import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <--- INI BARIS YANG SAYA LUPA (BIANG KEROKNYA)
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    runApp(LedApp(windowId: windowId));
  } else {
    runApp(const OperatorApp());
  }
}

// ==========================================
// BAGIAN 1: APLIKASI OPERATOR
// ==========================================
class OperatorApp extends StatelessWidget {
  const OperatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Operator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const OperatorScreen(),
    );
  }
}

class OperatorScreen extends StatefulWidget {
  const OperatorScreen({Key? key}) : super(key: key);

  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  int? ledWindowId;
  String? bgPath;
  
  final TextEditingController _juara1Controller = TextEditingController();
  final TextEditingController _no1Controller = TextEditingController();

  void _openLedWindow() async {
    final window = await DesktopMultiWindow.createWindow(jsonEncode({}));
    window
      ..setFrame(const Offset(0, 0) & const Size(1280, 720))
      ..center()
      ..setTitle('Layar LED')
      ..show();
    setState(() {
      ledWindowId = window.windowId;
    });
  }

  void _pickBackground() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.media,
    );

    if (result != null) {
      setState(() {
        bgPath = result.files.single.path;
      });
      _sendDataToLed('update_bg', {'path': bgPath});
    }
  }

  void _sendDataToLed(String action, Map<String, dynamic> data) {
    if (ledWindowId != null) {
      data['action'] = action;
      DesktopMultiWindow.invokeMethod(ledWindowId!, 'onReceiveData', jsonEncode(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operator - Pengumuman Pemenang', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.monitor),
                  label: const Text('BUKA LAYAR 2 (LED)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(20)),
                  onPressed: _openLedWindow,
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.video_library),
                  label: const Text('PILIH BACKGROUND'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(20)),
                  onPressed: _pickBackground,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(bgPath != null ? '✅ Tersimpan: $bgPath' : '❌ Background belum dipilih', style: const TextStyle(color: Colors.grey)),
            const Divider(height: 40, color: Colors.grey),
            
            const Text('Panel Tayang:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _no1Controller,
                    decoration: const InputDecoration(labelText: 'Nomor Dada', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _juara1Controller,
                    decoration: const InputDecoration(labelText: 'Nama Juara 1', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _sendDataToLed('show_winner', {
                      'juara1': _juara1Controller.text,
                      'nomor': _no1Controller.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.all(20)),
                  child: const Text('TAYANG JUARA 1', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// BAGIAN 2: APLIKASI LED
// ==========================================
class LedApp extends StatelessWidget {
  final int windowId;
  const LedApp({Key? key, required this.windowId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LedScreen(windowId: windowId),
    );
  }
}

class LedScreen extends StatefulWidget {
  final int windowId;
  const LedScreen({Key? key, required this.windowId}) : super(key: key);

  @override
  State<LedScreen> createState() => _LedScreenState();
}

class _LedScreenState extends State<LedScreen> {
  VideoPlayerController? _videoController;
  String winnerName = "-";
  String winnerNo = "-";
  bool isImage = false;
  String imagePath = "";

  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.setMethodHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call, int fromWindowId) async {
    if (call.method == 'onReceiveData') {
      final data = jsonDecode(call.arguments.toString());
      
      if (data['action'] == 'update_bg') {
        _playMedia(data['path']);
      } else if (data['action'] == 'show_winner') {
        setState(() {
          winnerName = data['juara1'];
          winnerNo = data['nomor'];
        });
      }
    }
  }

  void _playMedia(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['mp4', 'webm', 'mov'].contains(ext)) {
      setState(() => isImage = false);
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(File(path))
        ..initialize().then((_) {
          _videoController!.setLooping(true);
          _videoController!.play();
          setState(() {});
        });
    } else {
      setState(() {
        isImage = true;
        imagePath = path;
        _videoController?.dispose();
        _videoController = null;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!isImage && _videoController != null && _videoController!.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          if (isImage && imagePath.isNotEmpty)
            Image.file(File(imagePath), fit: BoxFit.cover),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('JUARA 1', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.black87)),
                  Text(winnerNo, style: const TextStyle(fontSize: 50, fontFamily: 'monospace', color: Colors.white)),
                  Text(winnerName, style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 5)])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
