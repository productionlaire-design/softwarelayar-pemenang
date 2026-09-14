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
// BAGIAN 1: APLIKASI OPERATOR
// ==========================================
class OperatorApp extends StatelessWidget {
  const OperatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAIRE CREATIVE STUDIO - Broadcast Pro',
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
  VideoPlayerController? _previewVideoCtrl;
  
  Map<String, dynamic> standbyData = {};
  Map<String, dynamic> liveData = {};
  String liveAction = 'clear';

  // State Input
  final _katCtrl = TextEditingController();
  final _j1noCtrl = TextEditingController(); final _j1namaCtrl = TextEditingController();
  final _j2noCtrl = TextEditingController(); final _j2namaCtrl = TextEditingController();
  final _j3noCtrl = TextEditingController(); final _j3namaCtrl = TextEditingController();

  // Settings
  double sScale = 100; double sPosY = 0;
  double sKat = 35; double sTitleBox = 30; double sNo = 50; double sNama = 65;
  double sWidth = 400; double sPad = 50;
  Color c1 = Colors.amber; Color c2 = Colors.blueGrey; Color c3 = Colors.deepOrange;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      sScale = prefs.getDouble('sScale') ?? 100; sPosY = prefs.getDouble('sPosY') ?? 0;
      sKat = prefs.getDouble('sKat') ?? 35; sTitleBox = prefs.getDouble('sTitleBox') ?? 30;
      sNo = prefs.getDouble('sNo') ?? 50; sNama = prefs.getDouble('sNama') ?? 65;
      sWidth = prefs.getDouble('sWidth') ?? 400; sPad = prefs.getDouble('sPad') ?? 50;
      c1 = Color(prefs.getInt('c1') ?? Colors.amber.value); c2 = Color(prefs.getInt('c2') ?? Colors.blueGrey.value); c3 = Color(prefs.getInt('c3') ?? Colors.deepOrange.value);
      bgPath = prefs.getString('bgPath');
      if (bgPath != null) _initPreviewVideo(bgPath!);
    });
    _updateStandbyData();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('sScale', sScale); prefs.setDouble('sPosY', sPosY);
    prefs.setDouble('sKat', sKat); prefs.setDouble('sTitleBox', sTitleBox);
    prefs.setDouble('sNo', sNo); prefs.setDouble('sNama', sNama);
    prefs.setDouble('sWidth', sWidth); prefs.setDouble('sPad', sPad);
    prefs.setInt('c1', c1.value); prefs.setInt('c2', c2.value); prefs.setInt('c3', c3.value);
    if(bgPath != null) prefs.setString('bgPath', bgPath!);
    _updateStandbyData();
    if(liveAction != 'clear') _sendToLed(liveAction); 
  }

  void _initPreviewVideo(String path) {
    if (path.toLowerCase().endsWith('.mp4') || path.toLowerCase().endsWith('.mov')) {
      _previewVideoCtrl?.dispose();
      _previewVideoCtrl = VideoPlayerController.file(File(path))..initialize().then((_) {
        _previewVideoCtrl!.setLooping(true);
        _previewVideoCtrl!.play();
        setState(() {});
      });
    } else {
      _previewVideoCtrl?.dispose();
      _previewVideoCtrl = null;
    }
  }

  void _openLedWindow() async {
    final window = await DesktopMultiWindow.createWindow(jsonEncode({}));
    window..setFrame(const Offset(0, 0) & const Size(1280, 720))..center()..setTitle('Layar LED Utama')..show();
    setState(() { ledWindowId = window.windowId; });
    Future.delayed(const Duration(milliseconds: 500), () => _sendToLed('clear'));
  }

  void _pickBackground() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['mp4', 'mov', 'avi', 'jpg', 'jpeg', 'png']
    );
    if (result != null) {
      setState(() { bgPath = result.files.single.path; });
      _initPreviewVideo(bgPath!);
      _saveSettings();
    }
  }

  void _importCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
    if (result != null) {
      String content = await File(result.files.single.path!).readAsString();
      for (var line in content.split('\n')) {
        List<String> cols = line.split(',');
        if (cols.length >= 7) {
          queue.add({'kat': cols[0].trim(), 'j1no': cols[1].trim(), 'j1nama': cols[2].trim(), 'j2no': cols[3].trim(), 'j2nama': cols[4].trim(), 'j3no': cols[5].trim(), 'j3nama': cols[6].trim()});
        }
      }
      setState(() {});
    }
  }

  void _updateStandbyData() {
    setState(() {
      standbyData = {
        'kat': _katCtrl.text, 'j1no': _j1noCtrl.text, 'j1nama': _j1namaCtrl.text,
        'j2no': _j2noCtrl.text, 'j2nama': _j2namaCtrl.text, 'j3no': _j3noCtrl.text, 'j3nama': _j3namaCtrl.text,
        'sScale': sScale, 'sPosY': sPosY, 'sKat': sKat, 'sTitleBox': sTitleBox, 'sNo': sNo, 'sNama': sNama, 'sWidth': sWidth, 'sPad': sPad,
        'c1': c1.value, 'c2': c2.value, 'c3': c3.value, 'bgPath': bgPath
      };
    });
  }

  void _sendToLed(String action) {
    setState(() {
      liveAction = action;
      if (action != 'clear') liveData = Map.from(standbyData);
    });
    if (ledWindowId != null) {
      final payload = Map<String, dynamic>.from(liveAction == 'clear' ? standbyData : liveData);
      payload['action'] = action;
      DesktopMultiWindow.invokeMethod(ledWindowId!, 'onReceiveData', jsonEncode(payload));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 5,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent)),
              child: const Icon(Icons.stars, color: Colors.blueAccent, size: 24),
            ),
            const SizedBox(width: 15),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAIRE CREATIVE STUDIO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Colors.white)),
                Text('Professional Broadcast System', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.monitor, color: Colors.white), label: const Text('BUKA LAYAR LED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: _openLedWindow,
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: Row(
        children: [
          // ==================== KOLOM 1: DATA ====================
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(15), border: const Border(right: BorderSide(color: Colors.white12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. DATA & ANTREAN', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(icon: const Icon(Icons.file_upload), label: const Text('Import CSV'), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, minimumSize: const Size(double.infinity, 40)), onPressed: _importCSV),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          TextField(controller: _katCtrl, decoration: const InputDecoration(labelText: 'Kategori (Msl: 10K Putra)', isDense: true), onChanged: (_) => _updateStandbyData()),
                          Row(children: [Expanded(child: TextField(controller: _j1noCtrl, decoration: const InputDecoration(labelText: 'No J1', isDense: true), onChanged: (_) => _updateStandbyData())), const SizedBox(width:10), Expanded(flex:2, child: TextField(controller: _j1namaCtrl, decoration: const InputDecoration(labelText: 'Nama J1', isDense: true), onChanged: (_) => _updateStandbyData()))]),
                          Row(children: [Expanded(child: TextField(controller: _j2noCtrl, decoration: const InputDecoration(labelText: 'No J2', isDense: true), onChanged: (_) => _updateStandbyData())), const SizedBox(width:10), Expanded(flex:2, child: TextField(controller: _j2namaCtrl, decoration: const InputDecoration(labelText: 'Nama J2', isDense: true), onChanged: (_) => _updateStandbyData()))]),
                          Row(children: [Expanded(child: TextField(controller: _j3noCtrl, decoration: const InputDecoration(labelText: 'No J3', isDense: true), onChanged: (_) => _updateStandbyData())), const SizedBox(width:10), Expanded(flex:2, child: TextField(controller: _j3namaCtrl, decoration: const InputDecoration(labelText: 'Nama J3', isDense: true), onChanged: (_) => _updateStandbyData()))]),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              if(_katCtrl.text.isEmpty) return;
                              setState(() { queue.add({'kat': _katCtrl.text, 'j1no': _j1noCtrl.text, 'j1nama': _j1namaCtrl.text, 'j2no': _j2noCtrl.text, 'j2nama': _j2namaCtrl.text, 'j3no': _j3noCtrl.text, 'j3nama': _j3namaCtrl.text}); });
                              _katCtrl.clear(); _j1noCtrl.clear(); _j1namaCtrl.clear(); _j2noCtrl.clear(); _j2namaCtrl.clear(); _j3noCtrl.clear(); _j3namaCtrl.clear(); _updateStandbyData();
                            },
                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 40)), child: const Text('Masukkan Ke Antrean')
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: queue.length,
                      itemBuilder: (c, i) => Card(
                        color: Colors.black26,
                        child: ListTile(
                          title: Text(queue[i]['kat']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 13)),
                          subtitle: Text('1:${queue[i]['j1nama']} | 2:${queue[i]['j2nama']}', style: const TextStyle(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.upload, color: Colors.blue, size: 20), onPressed: () {
                                setState(() { _katCtrl.text = queue[i]['kat']!; _j1noCtrl.text = queue[i]['j1no']!; _j1namaCtrl.text = queue[i]['j1nama']!; _j2noCtrl.text = queue[i]['j2no']!; _j2namaCtrl.text = queue[i]['j2nama']!; _j3noCtrl.text = queue[i]['j3no']!; _j3namaCtrl.text = queue[i]['j3nama']!; });
                                _updateStandbyData();
                              }),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => setState(()=> queue.removeAt(i))),
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
          
          // ==================== KOLOM 2: LAYAR PREVIEW & KONTROL ====================
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(15), border: const Border(right: BorderSide(color: Colors.white12)),
              child: Column(
                children: [
                  const Text('2. PREVIEW & KONTROL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  const SizedBox(height: 10),
                  // PREVIEW STANDBY
                  const Align(alignment: Alignment.centerLeft, child: Text('PREVIEW STANDBY (Persiapan)', style: TextStyle(fontSize: 10, color: Colors.grey))),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: _buildPreviewScreen(standbyData, 'all'),
                  ),
                  
                  const SizedBox(height: 15),
                  // TOMBOL BROADCAST
                  Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: () => _sendToLed('j3'), style: ElevatedButton.styleFrom(backgroundColor: c3, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('TAYANG J3', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton(onPressed: () => _sendToLed('j1'), style: ElevatedButton.styleFrom(backgroundColor: c1, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('TAYANG J1', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton(onPressed: () => _sendToLed('j2'), style: ElevatedButton.styleFrom(backgroundColor: c2, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('TAYANG J2', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(flex: 2, child: ElevatedButton(onPressed: () => _sendToLed('all'), style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('🌟 TAYANGKAN SEMUA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
                      const SizedBox(width: 10),
                      Expanded(flex: 1, child: ElevatedButton(onPressed: () => _sendToLed('clear'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text('✖ CLEAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
                    ],
                  ),

                  const SizedBox(height: 15),
                  // PREVIEW LIVE
                  const Align(alignment: Alignment.centerLeft, child: Text('LIVE OUTPUT (Layar Asli)', style: TextStyle(fontSize: 10, color: Colors.redAccent))),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 2), borderRadius: BorderRadius.circular(8)),
                    child: _buildPreviewScreen(liveAction == 'clear' ? {} : liveData, liveAction),
                  ),
                ],
              ),
            ),
          ),

          // ==================== KOLOM 3: KUSTOMISASI ====================
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(15),
              child: ListView(
                children: [
                  const Text('3. KUSTOMISASI VISUAL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.wallpaper), label: const Text('Pilih Background (Video/Img)'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, minimumSize: const Size(double.infinity, 45)),
                    onPressed: _pickBackground,
                  ),
                  Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(bgPath ?? 'Tidak ada background', style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  
                  const Divider(),
                  const Text('Palet Warna Kotak (Klik untuk Ubah):', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 5),
                  _buildColorPicker('Warna J3', c3, (c) => setState(() { c3 = c; _saveSettings(); })),
                  _buildColorPicker('Warna J1', c1, (c) => setState(() { c1 = c; _saveSettings(); })),
                  _buildColorPicker('Warna J2', c2, (c) => setState(() { c2 = c; _saveSettings(); })),
                  
                  const Divider(),
                  const Text('Dimensi & Posisi Kotak:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  _buildSlider('Skala (Besar/Kecil)', sScale, 50, 150, (v) => setState(() => sScale = v)),
                  _buildSlider('Posisi (Atas/Bawah)', sPosY, -500, 500, (v) => setState(() => sPosY = v)),
                  _buildSlider('Lebar Kotak', sWidth, 200, 800, (v) => setState(() => sWidth = v)),
                  _buildSlider('Tinggi Kotak (Padding)', sPad, 10, 100, (v) => setState(() => sPad = v)),
                  
                  const Divider(),
                  const Text('Ukuran Teks:', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  _buildSlider('Teks Kategori', sKat, 15, 80, (v) => setState(() => sKat = v)),
                  _buildSlider('Teks "JUARA"', sTitleBox, 15, 80, (v) => setState(() => sTitleBox = v)),
                  _buildSlider('Teks NOMOR', sNo, 20, 150, (v) => setState(() => sNo = v)),
                  _buildSlider('Teks NAMA', sNama, 30, 150, (v) => setState(() => sNama = v)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String label, Color current, ValueChanged<Color> onSelect) {
    List<Color> palette = [Colors.amber, Colors.orange, Colors.deepOrange, Colors.red, Colors.pink, Colors.purple, Colors.blue, Colors.teal, Colors.green, Colors.blueGrey, Colors.grey.shade800, Colors.black87];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(
            child: Wrap(
              spacing: 4, runSpacing: 4,
              children: palette.map((c) => InkWell(
                onTap: () => onSelect(c),
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: current == c ? Colors.white : Colors.transparent, width: 2)),
                ),
              )).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label (${val.toInt()})', style: const TextStyle(fontSize: 10, color: Colors.white70)),
        Slider(value: val, min: min, max: max, activeColor: Colors.blueAccent, inactiveColor: Colors.white12, onChanged: (v) { onChanged(v); _saveSettings(); }),
      ],
    );
  }

  // WIDGET MAGIC: Men-scale UI asli menjadi Preview 16:9
  Widget _buildPreviewScreen(Map<String, dynamic> data, String action) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double scale = constraints.maxWidth / 1280.0;
            return Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 1280, height: 720,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Tampilkan Gambar/Video di Preview
                    if (bgPath != null)
                      (bgPath!.toLowerCase().endsWith('.mp4') || bgPath!.toLowerCase().endsWith('.mov'))
                        ? (_previewVideoCtrl != null && _previewVideoCtrl!.value.isInitialized)
                          ? FittedBox(fit: BoxFit.cover, child: SizedBox(width: _previewVideoCtrl!.value.size.width, height: _previewVideoCtrl!.value.size.height, child: VideoPlayer(_previewVideoCtrl!)))
                          : const Center(child: Icon(Icons.video_file, color: Colors.white24, size: 50))
                        : Image.file(File(bgPath!), fit: BoxFit.cover)
                    else
                      Container(color: Colors.black),
                    
                    if (data.isNotEmpty)
                      LedCanvasWidget(d: data, action: action)
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// BAGIAN 2: APLIKASI LED & KOMPONEN CANVAS
// ==========================================
class LedApp extends StatelessWidget {
  final int windowId;
  const LedApp({Key? key, required this.windowId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Segoe UI'),
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
  Map<String, dynamic> d = {}; 
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
      
      if (newData['bgPath'] != null && newData['bgPath'] != activeBg) {
        activeBg = newData['bgPath'];
        final ext = activeBg!.split('.').last.toLowerCase();
        if (['mp4', 'mov', 'avi'].contains(ext)) {
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
        currentAction = newData['action'];
        d = newData;
      });
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideo && _videoCtrl != null && _videoCtrl!.value.isInitialized)
            FittedBox(fit: BoxFit.cover, child: SizedBox(width: _videoCtrl!.value.size.width, height: _videoCtrl!.value.size.height, child: VideoPlayer(_videoCtrl!)))
          else if (!isVideo && activeBg != null)
            Image.file(File(activeBg!), fit: BoxFit.cover),
          
          if (d.isNotEmpty)
            LedCanvasWidget(d: d, action: currentAction)
        ],
      ),
    );
  }
}

// ==========================================
// KANVAS PEMENANG (Bisa dipakai di Preview & Layar Asli)
// Memiliki Animasi Kemunculan
// ==========================================
class LedCanvasWidget extends StatelessWidget {
  final Map<String, dynamic> d;
  final String action;
  
  const LedCanvasWidget({Key? key, required this.d, required this.action}) : super(key: key);

  Widget _buildBox(String title, String no, String name, Color col, bool isCenter, bool isVisible) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      opacity: isVisible ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        transform: Matrix4.translationValues(0, isVisible ? (isCenter ? -30 : 30) : 150, 0),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: EdgeInsets.symmetric(vertical: d['sPad'] ?? 50, horizontal: 20),
        width: d['sWidth'] ?? 400,
        decoration: BoxDecoration(
          color: col.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: isCenter ? 6 : 3),
          boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 20, spreadRadius: 2)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: d['sTitleBox'] ?? 30, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 2)),
            const SizedBox(height: 10),
            Text(no.isEmpty ? '-' : no, style: TextStyle(fontSize: d['sNo'] ?? 50, fontFamily: 'Courier New', fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text(name.isEmpty ? '-' : name, textAlign: TextAlign.center, style: TextStyle(fontSize: d['sNama'] ?? 65, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, shadows: const [Shadow(color: Colors.black, blurRadius: 5)])),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool showAll = action == 'all';
    bool showTitle = action != 'clear';
    
    return Transform.scale(
      scale: (d['sScale'] ?? 100) / 100.0,
      child: Transform.translate(
        offset: Offset(0, d['sPosY'] ?? 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500), opacity: showTitle ? 1.0 : 0.0,
              child: const Text('PEMENANG LOMBA', style: TextStyle(fontSize: 70, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 5, shadows: [Shadow(color: Colors.black, blurRadius: 20)])),
            ),
            
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500), opacity: (showTitle && d['kat'] != null && d['kat'].toString().isNotEmpty) ? 1.0 : 0.0,
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 40), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.white30)),
                child: Text(d['kat'] ?? '', style: TextStyle(fontSize: d['sKat'] ?? 35, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)),
              ),
            ),

            if (!showTitle && d['kat'] == null) const SizedBox(height: 100),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBox('JUARA 3', d['j3no'], d['j3nama'], Color(d['c3'] ?? Colors.deepOrange.value), false, showAll || action == 'j3'),
                _buildBox('JUARA 1', d['j1no'], d['j1nama'], Color(d['c1'] ?? Colors.amber.value), true, showAll || action == 'j1'),
                _buildBox('JUARA 2', d['j2no'], d['j2nama'], Color(d['c2'] ?? Colors.blueGrey.value), false, showAll || action == 'j2'),
              ],
            )
          ],
        ),
      ),
    );
  }
}
