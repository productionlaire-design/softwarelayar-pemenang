import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  runApp(const MainRouter());
}

class MainRouter extends StatelessWidget {
  const MainRouter({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengumuman Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

// ==========================================
// MENU PEMILIHAN PERAN AWAL
// ==========================================
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('PILIH PERAN JENDELA INI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  ),
                  onPressed: () {
                    windowManager.setTitle('Operator - Panel Kontrol');
                    windowManager.setSize(const Size(1000, 700));
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OperatorScreen()));
                  },
                  child: const Text('MASUK SEBAGAI OPERATOR', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                  ),
                  onPressed: () {
                    windowManager.setTitle('Layar LED Utama');
                    windowManager.setFullScreen(true);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LedScreen()));
                  },
                  child: const Text('MASUK SEBAGAI LAYAR LED', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// APLIKASI OPERATOR (MENGIRIM DATA)
// ==========================================
class OperatorScreen extends StatefulWidget {
  const OperatorScreen({Key? key}) : super(key: key);
  @override
  State<OperatorScreen> createState() => _OperatorScreenState();
}

class _OperatorScreenState extends State<OperatorScreen> {
  String? bgPath;
  final _j1Nama = TextEditingController(); final _j1No = TextEditingController();
  final _j2Nama = TextEditingController(); final _j2No = TextEditingController();
  final _j3Nama = TextEditingController(); final _j3No = TextEditingController();
  final _kat = TextEditingController();

  // FUNGSI MENGIRIM DATA KE LAYAR LED VIA LOCALHOST
  Future<void> sendToLed(Map<String, dynamic> data) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('http://127.0.0.1:49200'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
      await request.close();
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim! Pastikan Jendela Layar LED sudah dibuka.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
      }
    }
  }

  void _pickBackground() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media);
    if (result != null) {
      setState(() => bgPath = result.files.single.path);
      sendToLed({'action': 'update_bg', 'path': bgPath});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Operator Kontrol'), backgroundColor: const Color(0xFF1E293B)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.folder), label: const Text('PILIH BACKGROUND (VIDEO/GAMBAR)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(20)),
              onPressed: _pickBackground,
            ),
            const SizedBox(height: 10),
            Text(bgPath != null ? 'Background Aktif: $bgPath' : 'Belum ada background', style: const TextStyle(color: Colors.amber)),
            const Divider(height: 40, color: Colors.grey),
            
            TextField(controller: _kat, decoration: const InputDecoration(labelText: 'Kategori Lomba (Opsional)', border: OutlineInputBorder()), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            _buildInputRow('JUARA 1', _j1No, _j1Nama, Colors.amber, 'show_j1'),
            const SizedBox(height: 15),
            _buildInputRow('JUARA 2', _j2No, _j2Nama, Colors.blueGrey, 'show_j2'),
            const SizedBox(height: 15),
            _buildInputRow('JUARA 3', _j3No, _j3Nama, Colors.deepOrange, 'show_j3'),
            
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.all(20)),
                  onPressed: () => sendToLed({
                    'action': 'show_all', 'kat': _kat.text,
                    'j1no': _j1No.text, 'j1nama': _j1Nama.text,
                    'j2no': _j2No.text, 'j2nama': _j2Nama.text,
                    'j3no': _j3No.text, 'j3nama': _j3Nama.text,
                  }),
                  child: const Text('TAYANGKAN SEMUA (PODIUM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.all(20)),
                  onPressed: () => sendToLed({'action': 'clear'}),
                  child: const Text('BERSIHKAN LAYAR (CLEAR)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                )),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputRow(String title, TextEditingController noCtrl, TextEditingController namaCtrl, Color col, String action) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(title, style: TextStyle(color: col, fontWeight: FontWeight.bold, fontSize: 16))),
        Expanded(child: TextField(controller: noCtrl, decoration: const InputDecoration(labelText: 'No. Dada', border: OutlineInputBorder()))),
        const SizedBox(width: 10),
        Expanded(flex: 3, child: TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Pemenang', border: OutlineInputBorder()))),
        const SizedBox(width: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: col, padding: const EdgeInsets.all(20)),
          onPressed: () => sendToLed({'action': action, 'kat': _kat.text, 'no': noCtrl.text, 'nama': namaCtrl.text}),
          child: Text('TAYANG $title', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

// ==========================================
// APLIKASI LAYAR LED (MENERIMA DATA)
// ==========================================
class LedScreen extends StatefulWidget {
  const LedScreen({Key? key}) : super(key: key);
  @override
  State<LedScreen> createState() => _LedScreenState();
}

class _LedScreenState extends State<LedScreen> {
  HttpServer? _server;
  VideoPlayerController? _videoCtrl;
  String imagePath = "";
  Map<String, dynamic> _data = {'action': 'clear'};

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  // MENJALANKAN SERVER LOKAL DI PORT 49200
  void _startServer() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 49200);
    _server!.listen((HttpRequest request) async {
      final content = await utf8.decoder.bind(request).join();
      final data = jsonDecode(content);
      
      if (data['action'] == 'update_bg') {
        _updateMedia(data['path']);
      } else {
        setState(() { _data = data; });
      }
      request.response.write('OK');
      request.response.close();
    });
  }

  void _updateMedia(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (['mp4', 'webm', 'mov', 'avi'].contains(ext)) {
      setState(() => imagePath = "");
      _videoCtrl?.dispose();
      _videoCtrl = VideoPlayerController.file(File(path))..initialize().then((_) {
        _videoCtrl!.setLooping(true); _videoCtrl!.play(); setState(() {});
      });
    } else {
      setState(() { imagePath = path; _videoCtrl?.dispose(); _videoCtrl = null; });
    }
  }

  @override
  void dispose() { _server?.close(); _videoCtrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final act = _data['action'] ?? 'clear';
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // BACKGROUND MEDIA
          if (imagePath.isEmpty && _videoCtrl != null && _videoCtrl!.value.isInitialized)
            FittedBox(fit: BoxFit.cover, child: SizedBox(width: _videoCtrl!.value.size.width, height: _videoCtrl!.value.size.height, child: VideoPlayer(_videoCtrl!))),
          if (imagePath.isNotEmpty) Image.file(File(imagePath), fit: BoxFit.cover),
          
          // FOREGROUND UI
          if (act != 'clear') 
            Center(
              child: act == 'show_all' ? _buildAll() : _buildSingle(act),
            )
        ],
      ),
    );
  }

  Widget _buildSingle(String act) {
    String title = act == 'show_j1' ? 'JUARA 1' : (act == 'show_j2' ? 'JUARA 2' : 'JUARA 3');
    Color col = act == 'show_j1' ? Colors.amber : (act == 'show_j2' ? Colors.blueGrey : Colors.deepOrange);
    return _buildCard(title, _data['no'] ?? '-', _data['nama'] ?? '-', col, 1.2);
  }

  Widget _buildAll() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildCard('JUARA 3', _data['j3no'], _data['j3nama'], Colors.deepOrange, 0.8),
        const SizedBox(width: 20),
        Padding(padding: const EdgeInsets.only(bottom: 40), child: _buildCard('JUARA 1', _data['j1no'], _data['j1nama'], Colors.amber, 1.1)),
        const SizedBox(width: 20),
        _buildCard('JUARA 2', _data['j2no'], _data['j2nama'], Colors.blueGrey, 0.8),
      ],
    );
  }

  Widget _buildCard(String title, String? no, String? nama, Color color, double scale) {
    return Transform.scale(
      scale: scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        decoration: BoxDecoration(
          color: color.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if(_data['kat'] != null && _data['kat'].toString().isNotEmpty)
               Text(_data['kat'], style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87)),
            Text(no ?? '-', style: const TextStyle(fontSize: 40, fontFamily: 'monospace', color: Colors.white)),
            Text(nama ?? '-', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
          ],
        ),
      ),
    );
  }
}
