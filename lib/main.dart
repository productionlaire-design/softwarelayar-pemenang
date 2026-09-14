import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
// BAGIAN 1: APLIKASI OPERATOR (KONTROL PANEL)
// ==========================================
class OperatorApp extends StatelessWidget {
  const OperatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agasta Pro Operator',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
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
  List<Map<String, String>> queue = [];
  
  // State Input Manual
  final _katCtrl = TextEditingController();
  final _j1noCtrl = TextEditingController(); final _j1namaCtrl = TextEditingController();
  final _j2noCtrl = TextEditingController(); final _j2namaCtrl = TextEditingController();
  final _j3noCtrl = TextEditingController(); final _j3namaCtrl = TextEditingController();

  // State Ukuran & Warna
  double sTitle = 80; double sKat = 30; 
  double sBoxTitle = 35; double sBoxNo = 45; double sBoxName = 55;
  Color c1 = Colors.amber; Color c2 = Colors.blueGrey; Color c3 = Colors.deepOrange;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sTitle = prefs.getDouble('sTitle') ?? 80; sKat = prefs.getDouble('sKat') ?? 30;
      sBoxTitle = prefs.getDouble('sBoxTitle') ?? 35; sBoxNo = prefs.getDouble('sBoxNo') ?? 45; sBoxName = prefs.getDouble('sBoxName') ?? 55;
      c1 = Color(prefs.getInt('c1') ?? Colors.amber.value); c2 = Color(prefs.getInt('c2') ?? Colors.blueGrey.value); c3 = Color(prefs.getInt('c3') ?? Colors.deepOrange.value);
      bgPath = prefs.getString('bgPath');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('sTitle', sTitle); prefs.setDouble('sKat', sKat);
    prefs.setDouble('sBoxTitle', sBoxTitle); prefs.setDouble('sBoxNo', sBoxNo); prefs.setDouble('sBoxName', sBoxName);
    prefs.setInt('c1', c1.value); prefs.setInt('c2', c2.value); prefs.setInt('c3', c3.value);
    if(bgPath != null) prefs.setString('bgPath', bgPath!);
    _updateLedPreview();
  }

  void _openLedWindow() async {
    final window = await DesktopMultiWindow.createWindow(jsonEncode({}));
    window..setFrame(const Offset(0, 0) & const Size(1280, 720))..center()..setTitle('Layar LED')..show();
    setState(() { ledWindowId = window.windowId; });
    Future.delayed(const Duration(milliseconds: 500), _updateLedPreview);
  }

  void _pickBackground() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.media);
    if (result != null) {
      setState(() { bgPath = result.files.single.path; });
      _saveSettings();
    }
  }

  void _importCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['csv'],
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      List<String> lines = content.split('\n');
      for (var line in lines) {
        List<String> cols = line.split(',');
        if (cols.length >= 7) {
          queue.add({
            'kat': cols[0].trim(), 'j1no': cols[1].trim(), 'j1nama': cols[2].trim(),
            'j2no': cols[3].trim(), 'j2nama': cols[4].trim(), 'j3no': cols[5].trim(), 'j3nama': cols[6].trim(),
          });
        }
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data CSV Berhasil Diimpor!')));
    }
  }

  void _addToQueue() {
    if(_katCtrl.text.isEmpty && _j1namaCtrl.text.isEmpty) return;
    setState(() {
      queue.add({
        'kat': _katCtrl.text, 'j1no': _j1noCtrl.text, 'j1nama': _j1namaCtrl.text,
        'j2no': _j2noCtrl.text, 'j2nama': _j2namaCtrl.text, 'j3no': _j3noCtrl.text, 'j3nama': _j3namaCtrl.text,
      });
      _katCtrl.clear(); _j1noCtrl.clear(); _j1namaCtrl.clear(); _j2noCtrl.clear(); _j2namaCtrl.clear(); _j3noCtrl.clear(); _j3namaCtrl.clear();
    });
  }

  void _loadToStandby(Map<String, String> q) {
    setState(() {
      _katCtrl.text = q['kat']!; _j1noCtrl.text = q['j1no']!; _j1namaCtrl.text = q['j1nama']!;
      _j2noCtrl.text = q['j2no']!; _j2namaCtrl.text = q['j2nama']!; _j3noCtrl.text = q['j3no']!; _j3namaCtrl.text = q['j3nama']!;
    });
    _updateLedPreview();
  }

  void _updateLedPreview() => _sendToLed('standby');

  void _sendToLed(String action) {
    if (ledWindowId != null) {
      final data = {
        'action': action, 'bgPath': bgPath,
        'kat': _katCtrl.text,
        'j1no': _j1noCtrl.text, 'j1nama': _j1namaCtrl.text,
        'j2no': _j2noCtrl.text, 'j2nama': _j2namaCtrl.text,
        'j3no': _j3noCtrl.text, 'j3nama': _j3namaCtrl.text,
        'sTitle': sTitle, 'sKat': sKat, 'sBoxTitle': sBoxTitle, 'sBoxNo': sBoxNo, 'sBoxName': sBoxName,
        'c1': c1.value, 'c2': c2.value, 'c3': c3.value,
      };
      DesktopMultiWindow.invokeMethod(ledWindowId!, 'onReceiveData', jsonEncode(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
            const SizedBox(width: 10),
            const Text('AGASTA CREATIVE STUDIO - WINNER PRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.monitor), label: const Text('BUKA LAYAR LED'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: _openLedWindow,
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Row(
        children: [
          // KOLOM 1: ANTREAN & INPUT
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(15), border: const Border(right: BorderSide(color: Colors.white12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. DATA & ANTREAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file), label: const Text('Import Data (.CSV)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, minimumSize: const Size(double.infinity, 40)),
                    onPressed: _importCSV,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          TextField(controller: _katCtrl, decoration: const InputDecoration(labelText: 'Kategori (Msl: 10K Putra)', isDense: true)),
                          Row(children: [Expanded(child: TextField(controller: _j1noCtrl, decoration: const InputDecoration(labelText: 'No J1', isDense: true))), const SizedBox(width:10), Expanded(flex:2, child: TextField(controller: _j1namaCtrl, decoration: const InputDecoration(labelText: 'Nama J1', isDense: true)))]),
                          Row(children: [Expanded(child: TextField(controller: _j2noCtrl, decoration: const InputDecoration(labelText: 'No J2', isDense: true))), const SizedBox(width:10), Expanded(flex:2, child: TextField(controller: _j2namaCtrl, decoration: const InputDecoration(labelText: 'Nama J2', isDense: true)))]),
                          Row(children: [Expanded(child: TextField(controller: _j3noCtrl, decoration: const InputDecoration(labelText: 'No J3', isDense: true))), const SizedBox(width:10), Expanded(flex:2, child: TextField(controller: _j3namaCtrl, decoration: const InputDecoration(labelText: 'Nama J3', isDense: true)))]),
                          const SizedBox(height: 10),
                          ElevatedButton(onPressed: _addToQueue, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)), child: const Text('Masukkan Ke Antrean')),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  const Text('Daftar Tunggu:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: queue.length,
                      itemBuilder: (c, i) => Card(
                        color: Colors.black26,
                        child: ListTile(
                          title: Text(queue[i]['kat']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                          subtitle: Text('1: ${queue[i]['j1nama']} | 2: ${queue[i]['j2nama']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.upload, color: Colors.blue), onPressed: () => _loadToStandby(queue[i])),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(()=> queue.removeAt(i))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          // KOLOM 2: KONTROL TAYANG
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(15), border: const Border(right: BorderSide(color: Colors.white12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2. KONTROL TAYANG LED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () => _sendToLed('j3'), style: ElevatedButton.styleFrom(backgroundColor: c3, minimumSize: const Size(double.infinity, 50)), child: const Text('TAYANGKAN JUARA 3', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: () => _sendToLed('j1'), style: ElevatedButton.styleFrom(backgroundColor: c1, minimumSize: const Size(double.infinity, 70)), child: const Text('TAYANGKAN JUARA 1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18))),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: () => _sendToLed('j2'), style: ElevatedButton.styleFrom(backgroundColor: c2, minimumSize: const Size(double.infinity, 50)), child: const Text('TAYANGKAN JUARA 2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: () => _sendToLed('all'), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, minimumSize: const Size(double.infinity, 60)), child: const Text('🌟 TAYANGKAN SEMUA (PODIUM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                  const Spacer(),
                  ElevatedButton(onPressed: () => _sendToLed('clear'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 50)), child: const Text('✖ BERSIHKAN LAYAR (CLEAR)')),
                ],
              ),
            ),
          ),

          // KOLOM 3: KUSTOMISASI VISUAL
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(15),
              child: ListView(
                children: [
                  const Text('3. KUSTOMISASI VISUAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.video_library), label: const Text('Pilih Background (Video/Img)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, minimumSize: const Size(double.infinity, 50)),
                    onPressed: _pickBackground,
                  ),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(bgPath ?? 'Belum ada background', style: const TextStyle(fontSize: 10, color: Colors.grey))),
                  
                  const Divider(),
                  const Text('Warna Kotak:'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(onTap: () { setState(()=> c3 = Colors.deepOrange); _saveSettings(); }, child: CircleAvatar(backgroundColor: Colors.deepOrange, child: Text('J3'))),
                      InkWell(onTap: () { setState(()=> c1 = Colors.amber); _saveSettings(); }, child: CircleAvatar(backgroundColor: Colors.amber, child: Text('J1', style: TextStyle(color: Colors.black)))),
                      InkWell(onTap: () { setState(()=> c2 = Colors.blueGrey); _saveSettings(); }, child: CircleAvatar(backgroundColor: Colors.blueGrey, child: Text('J2'))),
                      InkWell(onTap: () { setState(() { c1=Colors.green; c2=Colors.teal; c3=Colors.lightGreen; }); _saveSettings(); }, child: CircleAvatar(backgroundColor: Colors.green, child: Text('Alt'))),
                    ],
                  ),
                  const Divider(),
                  
                  _buildSlider('Ukuran Judul Utama', sTitle, 30, 150, (v) => setState(() => sTitle = v)),
                  _buildSlider('Ukuran Teks Kategori', sKat, 15, 80, (v) => setState(() => sKat = v)),
                  _buildSlider('Ukuran Tulisan "JUARA"', sBoxTitle, 20, 80, (v) => setState(() => sBoxTitle = v)),
                  _buildSlider('Ukuran Teks NOMOR', sBoxNo, 20, 150, (v) => setState(() => sBoxNo = v)),
                  _buildSlider('Ukuran Teks NAMA', sBoxName, 30, 200, (v) => setState(() => sBoxName = v)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label (${val.toInt()})', style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Slider(value: val, min: min, max: max, onChanged: (v) { onChanged(v); _saveSettings(); }),
      ],
    );
  }
}

// ==========================================
// BAGIAN 2: APLIKASI LED (PENAMPIL)
// ==========================================
class LedApp extends StatelessWidget {
  final int windowId;
  const LedApp({Key? key, required this.windowId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Segoe UI'), // Font bawaan Windows yang rapi
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
  VideoPlayerController? _videoCtrl;
  Map<String, dynamic> d = {}; // Data dari operator
  String currentAction = 'clear';
  String? activeBg;
  bool isVideo = false;

  @override
  void initState() {
    super.initState();
    DesktopMultiWindow.setMethodHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call, int fromWindowId) async {
    if (call.method == 'onReceiveData') {
      final newData = jsonDecode(call.arguments.toString());
      
      // Update Background
      if (newData['bgPath'] != null && newData['bgPath'] != activeBg) {
        activeBg = newData['bgPath'];
        final ext = activeBg!.split('.').last.toLowerCase();
        if (['mp4', 'webm', 'mov', 'avi'].contains(ext)) {
          isVideo = true;
          _videoCtrl?.dispose();
          _videoCtrl = VideoPlayerController.file(File(activeBg!))
            ..initialize().then((_) {
              _videoCtrl!.setLooping(true);
              _videoCtrl!.play();
              setState(() {});
            });
        } else {
          isVideo = false;
          _videoCtrl?.dispose();
          _videoCtrl = null;
        }
      }

      setState(() {
        if (newData['action'] != 'standby') {
          currentAction = newData['action'];
        }
        d = newData;
      });
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  // Desain KOTAK PEMENANG (3 Baris Persis Permintaan Anda)
  Widget _buildBox(String title, String no, String name, Color col, bool isCenter) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: EdgeInsets.symmetric(vertical: isCenter ? 60 : 40, horizontal: 30),
      width: isCenter ? 500 : 400,
      decoration: BoxDecoration(
        color: col.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: isCenter ? 6 : 3),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 30, spreadRadius: 5)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris 1: JUARA
          Text(title, style: TextStyle(fontSize: d['sBoxTitle'] ?? 35, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 2)),
          const SizedBox(height: 15),
          // Baris 2: NOMOR DADA
          Text(no.isEmpty ? '-' : no, style: TextStyle(fontSize: d['sBoxNo'] ?? 45, fontFamily: 'Courier New', fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),
          // Baris 3: NAMA
          Text(name.isEmpty ? '-' : name, textAlign: TextAlign.center, style: TextStyle(fontSize: d['sBoxName'] ?? 55, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, shadows: const [Shadow(color: Colors.black, blurRadius: 10)])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (d.isEmpty) return const Scaffold(backgroundColor: Colors.black);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. BACKGROUND
          if (isVideo && _videoCtrl != null && _videoCtrl!.value.isInitialized)
            FittedBox(fit: BoxFit.cover, child: SizedBox(width: _videoCtrl!.value.size.width, height: _videoCtrl!.value.size.height, child: VideoPlayer(_videoCtrl!)))
          else if (!isVideo && activeBg != null)
            Image.file(File(activeBg!), fit: BoxFit.cover),
          
          // Overlay Gelap Sedikit
          Container(color: Colors.black.withOpacity(0.3)),

          // 2. KONTEN UTAMA
          if (currentAction != 'clear')
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // JUDUL UTAMA
                  Text('PEMENANG LOMBA', style: TextStyle(fontSize: d['sTitle'] ?? 80, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 5, shadows: const [Shadow(color: Colors.black, blurRadius: 20)])),
                  
                  // KATEGORI (Di Bawah Judul)
                  if (d['kat'] != null && d['kat'].toString().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 50),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.white30)),
                      child: Text(d['kat'], style: TextStyle(fontSize: d['sKat'] ?? 30, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)),
                    )
                  else
                    const SizedBox(height: 60),

                  // BARISAN KOTAK
                  if (currentAction == 'all')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBox('JUARA 3', d['j3no'], d['j3nama'], Color(d['c3']), false),
                        _buildBox('JUARA 1', d['j1no'], d['j1nama'], Color(d['c1']), true),
                        _buildBox('JUARA 2', d['j2no'], d['j2nama'], Color(d['c2']), false),
                      ],
                    )
                  else if (currentAction == 'j1')
                    _buildBox('JUARA 1', d['j1no'], d['j1nama'], Color(d['c1']), true)
                  else if (currentAction == 'j2')
                    _buildBox('JUARA 2', d['j2no'], d['j2nama'], Color(d['c2']), true)
                  else if (currentAction == 'j3')
                    _buildBox('JUARA 3', d['j3no'], d['j3nama'], Color(d['c3']), true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
