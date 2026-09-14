import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized(); // INIT MESIN VLC, BEBAS ERROR WINDOW MANAGER

  if (args.firstOrNull == 'multi_window') {
    final windowId = int.parse(args[1]);
    runApp(LedApp(windowId: windowId));
  } else {
    runApp(const OperatorApp());
  }
}

const List<String> fontChoices = [
  'Segoe UI', 'Impact', 'Arial Black', 'Arial', 'Tahoma', 'Verdana', 
  'Trebuchet MS', 'Georgia', 'Times New Roman', 'Comic Sans MS', 
  'Courier New', 'Consolas', 'Garamond', 'Palatino Linotype', 
  'Calibri', 'Cambria', 'Candara', 'Corbel', 'Constantia', 'Franklin Gothic Medium'
];

// ==========================================
// BAGIAN 1: APLIKASI OPERATOR
// ==========================================
class OperatorApp extends StatelessWidget {
  const OperatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAIRE CREATIVE STUDIO - Broadcast Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        dividerColor: Colors.white24,
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
  
  Player? _previewPlayer;
  VideoController? _previewVideoCtrl;
  bool isVideoError = false;
  
  Map<String, dynamic> standbyData = {};
  Map<String, dynamic> liveData = {};
  String liveAction = 'clear';
  bool showHadiah = true;

  // --- DATA INPUT ---
  final _mainTitleCtrl = TextEditingController(text: 'PEMENANG LOMBA');
  final _katCtrl = TextEditingController();
  final _j1noCtrl = TextEditingController(); final _j1namaCtrl = TextEditingController(); final _j1hadiahCtrl = TextEditingController();
  final _j2noCtrl = TextEditingController(); final _j2namaCtrl = TextEditingController(); final _j2hadiahCtrl = TextEditingController();
  final _j3noCtrl = TextEditingController(); final _j3namaCtrl = TextEditingController(); final _j3hadiahCtrl = TextEditingController();

  // --- SETTINGS ---
  String animStyle = 'bounce';
  String boxStyle = 'rounded_border'; 
  String fTitle = 'Impact'; String fKat = 'Segoe UI'; String fBox = 'Segoe UI';
  double sMainTitle = 80; double sMainTitleY = 0;
  Color cKat = Colors.black87; double opKat = 0.8;
  double sKat = 35; double sKatPad = 15; double sKatWidth = 250; double sKatY = 0;
  Color c1 = Colors.amber; Color c2 = Colors.blueGrey; Color c3 = Colors.deepOrange;
  double opBox = 0.95;
  double sTitleBox = 35; double sNo = 50; double sNama = 65; double sHadiah = 35;
  double sWidth = 450; double sPad = 40; double sScale = 100; double sPosY = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mainTitleCtrl.text = prefs.getString('mainTitle') ?? 'PEMENANG LOMBA';
      animStyle = prefs.getString('animStyle') ?? 'bounce';
      boxStyle = prefs.getString('boxStyle') ?? 'rounded_border';
      showHadiah = prefs.getBool('showHadiah') ?? true;
      fTitle = prefs.getString('fTitle') ?? 'Impact'; fKat = prefs.getString('fKat') ?? 'Segoe UI'; fBox = prefs.getString('fBox') ?? 'Segoe UI';
      sMainTitle = prefs.getDouble('sMainTitle') ?? 80; sMainTitleY = prefs.getDouble('sMainTitleY') ?? 0;
      cKat = Color(prefs.getInt('cKat') ?? Colors.black87.value); opKat = prefs.getDouble('opKat') ?? 0.8;
      sKat = prefs.getDouble('sKat') ?? 35; sKatPad = prefs.getDouble('sKatPad') ?? 15; sKatWidth = prefs.getDouble('sKatWidth') ?? 250; sKatY = prefs.getDouble('sKatY') ?? 0;
      c1 = Color(prefs.getInt('c1') ?? Colors.amber.value); c2 = Color(prefs.getInt('c2') ?? Colors.blueGrey.value); c3 = Color(prefs.getInt('c3') ?? Colors.deepOrange.value);
      opBox = prefs.getDouble('opBox') ?? 0.95;
      sTitleBox = prefs.getDouble('sTitleBox') ?? 35; sNo = prefs.getDouble('sNo') ?? 50; sNama = prefs.getDouble('sNama') ?? 65; sHadiah = prefs.getDouble('sHadiah') ?? 35;
      sWidth = prefs.getDouble('sWidth') ?? 450; sPad = prefs.getDouble('sPad') ?? 40; sScale = prefs.getDouble('sScale') ?? 100; sPosY = prefs.getDouble('sPosY') ?? 0;
      bgPath = prefs.getString('bgPath');
      if (bgPath != null) _initPreviewVideo(bgPath!);
    });
    _updateStandbyData();
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('mainTitle', _mainTitleCtrl.text); prefs.setString('animStyle', animStyle); 
    prefs.setString('boxStyle', boxStyle); prefs.setBool('showHadiah', showHadiah);
    prefs.setString('fTitle', fTitle); prefs.setString('fKat', fKat); prefs.setString('fBox', fBox);
    prefs.setDouble('sMainTitle', sMainTitle); prefs.setDouble('sMainTitleY', sMainTitleY);
    prefs.setInt('cKat', cKat.value); prefs.setDouble('opKat', opKat);
    prefs.setDouble('sKat', sKat); prefs.setDouble('sKatPad', sKatPad); prefs.setDouble('sKatWidth', sKatWidth); prefs.setDouble('sKatY', sKatY);
    prefs.setInt('c1', c1.value); prefs.setInt('c2', c2.value); prefs.setInt('c3', c3.value); prefs.setDouble('opBox', opBox);
    prefs.setDouble('sTitleBox', sTitleBox); prefs.setDouble('sNo', sNo); prefs.setDouble('sNama', sNama); prefs.setDouble('sHadiah', sHadiah);
    prefs.setDouble('sWidth', sWidth); prefs.setDouble('sPad', sPad); prefs.setDouble('sScale', sScale); prefs.setDouble('sPosY', sPosY);
    if(bgPath != null) prefs.setString('bgPath', bgPath!);
    _updateStandbyData();
    if(liveAction != 'clear') _sendToLed(liveAction); 
  }

  void _initPreviewVideo(String path) async {
    isVideoError = false;
    final ext = path.toLowerCase().split('.').last;
    if (['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'].contains(ext)) {
      _previewPlayer?.dispose();
      _previewPlayer = Player();
      _previewVideoCtrl = VideoController(_previewPlayer!);
      try {
        await _previewPlayer!.setVolume(0.0); 
        await _previewPlayer!.setPlaylistMode(PlaylistMode.single);
        await _previewPlayer!.open(Media(path));
        if(mounted) setState(() {});
      } catch (e) {
        isVideoError = true;
        if(mounted) setState(() {});
      }
    } else {
      _previewPlayer?.dispose(); _previewPlayer = null; _previewVideoCtrl = null;
      if(mounted) setState(() {});
    }
  }

  void _openLedWindow() async {
    if (ledWindowId != null) return; // Cegah membuka jendela berkali-kali

    final window = await DesktopMultiWindow.createWindow(jsonEncode({}));
    window
      ..setFrame(const Offset(100, 100) & const Size(1280, 720))
      ..setTitle('LAIRE CREATIVE STUDIO - DISPLAY LED')
      ..show();
      
    setState(() { ledWindowId = window.windowId; });
    Future.delayed(const Duration(milliseconds: 600), () => _sendToLed('clear'));
  }

  void _pickBackground() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['mp4', 'mov', 'avi', 'mkv', 'webm', 'jpg', 'jpeg', 'png']
    );
    if (result != null) {
      setState(() { bgPath = result.files.single.path; });
      _initPreviewVideo(bgPath!); _saveSettings();
    }
  }

  void _downloadTemplateExcel() async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Simpan Template Excel/CSV', 
      fileName: 'Template_Pemenang_Laire.csv', 
      type: FileType.custom, 
      allowedExtensions: ['csv'],
    );
    if (outputFile != null) {
      File f = File(outputFile);
      await f.writeAsString("Kategori,No J1,Nama J1,Hadiah J1,No J2,Nama J2,Hadiah J2,No J3,Nama J3,Hadiah J3\n10K PUTRA,001,Budi,Rp 10.000.000,002,Andi,Rp 7.000.000,003,Cipto,Rp 5.000.000");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template berhasil disimpan! Buka dengan Excel.'), backgroundColor: Colors.green));
      }
    }
  }

  void _importCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv', 'xlsx']);
    if (result != null) {
      try {
        String content = await File(result.files.single.path!).readAsString();
        for (var line in content.split('\n')) {
          List<String> cols = line.split(',');
          if (cols.length >= 10) {
            queue.add({'kat': cols[0].trim(), 'j1no': cols[1].trim(), 'j1nama': cols[2].trim(), 'j1hadiah': cols[3].trim(), 'j2no': cols[4].trim(), 'j2nama': cols[5].trim(), 'j2hadiah': cols[6].trim(), 'j3no': cols[7].trim(), 'j3nama': cols[8].trim(), 'j3hadiah': cols[9].trim()});
          } else if (cols.length >= 7) {
            queue.add({'kat': cols[0].trim(), 'j1no': cols[1].trim(), 'j1nama': cols[2].trim(), 'j1hadiah': '', 'j2no': cols[3].trim(), 'j2nama': cols[4].trim(), 'j2hadiah': '', 'j3no': cols[5].trim(), 'j3nama': cols[6].trim(), 'j3hadiah': ''});
          }
        }
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error baca file: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _updateStandbyData() {
    setState(() {
      standbyData = {
        'mainTitle': _mainTitleCtrl.text, 'animStyle': animStyle, 'boxStyle': boxStyle, 'showHadiah': showHadiah,
        'fTitle': fTitle, 'fKat': fKat, 'fBox': fBox,
        'kat': _katCtrl.text, 
        'j1no': _j1noCtrl.text, 'j1nama': _j1namaCtrl.text, 'j1hadiah': _j1hadiahCtrl.text,
        'j2no': _j2noCtrl.text, 'j2nama': _j2namaCtrl.text, 'j2hadiah': _j2hadiahCtrl.text,
        'j3no': _j3noCtrl.text, 'j3nama': _j3namaCtrl.text, 'j3hadiah': _j3hadiahCtrl.text,
        'sMainTitle': sMainTitle, 'sMainTitleY': sMainTitleY,
        'cKat': cKat.value, 'opKat': opKat, 'sKat': sKat, 'sKatPad': sKatPad, 'sKatWidth': sKatWidth, 'sKatY': sKatY,
        'c1': c1.value, 'c2': c2.value, 'c3': c3.value, 'opBox': opBox,
        'sTitleBox': sTitleBox, 'sNo': sNo, 'sNama': sNama, 'sHadiah': sHadiah, 'sWidth': sWidth, 'sPad': sPad, 'sScale': sScale, 'sPosY': sPosY,
        'bgPath': bgPath
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
        backgroundColor: const Color(0xFF0F172A), elevation: 5,
        title: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blueAccent)), child: const Icon(Icons.stars, color: Colors.blueAccent, size: 24)),
            const SizedBox(width: 15),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LAIRE CREATIVE STUDIO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2, color: Colors.white)),
              Text('Professional Broadcast System', style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1)),
            ]),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.open_in_new, color: Colors.white), 
            label: const Text('BUKA DISPLAY LED', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal), 
            onPressed: _openLedWindow
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
              padding: const EdgeInsets.all(15), decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white12))), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('1. DATA PEMENANG', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.file_upload, size: 18), label: const Text('Import CSV', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo), onPressed: _importCSV)),
                      const SizedBox(width: 5),
                      Expanded(child: ElevatedButton.icon(icon: const Icon(Icons.download, size: 18), label: const Text('Template', style: TextStyle(fontSize: 12)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: _downloadTemplateExcel)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Card(
                      color: const Color(0xFF1E293B),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: ListView(
                          children: [
                            TextField(controller: _katCtrl, decoration: const InputDecoration(labelText: 'Kategori (Msl: 10K Putra)', isDense: true, border: OutlineInputBorder()), onChanged: (_) => _updateStandbyData()),
                            const SizedBox(height: 15),
                            _buildInputRow('J1', Colors.amber, _j1noCtrl, _j1namaCtrl, _j1hadiahCtrl),
                            _buildInputRow('J2', Colors.blueGrey, _j2noCtrl, _j2namaCtrl, _j2hadiahCtrl),
                            _buildInputRow('J3', Colors.deepOrange, _j3noCtrl, _j3namaCtrl, _j3hadiahCtrl),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                if(_katCtrl.text.isEmpty) return;
                                setState(() { queue.add({'kat': _katCtrl.text, 'j1no': _j1noCtrl.text, 'j1nama': _j1namaCtrl.text, 'j1hadiah': _j1hadiahCtrl.text, 'j2no': _j2noCtrl.text, 'j2nama': _j2namaCtrl.text, 'j2hadiah': _j2hadiahCtrl.text, 'j3no': _j3noCtrl.text, 'j3nama': _j3namaCtrl.text, 'j3hadiah': _j3hadiahCtrl.text}); });
                                _katCtrl.clear(); _j1noCtrl.clear(); _j1namaCtrl.clear(); _j1hadiahCtrl.clear(); _j2noCtrl.clear(); _j2namaCtrl.clear(); _j2hadiahCtrl.clear(); _j3noCtrl.clear(); _j3namaCtrl.clear(); _j3hadiahCtrl.clear(); _updateStandbyData();
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 45)), child: const Text('SIMPAN KE ANTREAN', style: TextStyle(fontWeight: FontWeight.bold))
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text('Daftar Antrean:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      itemCount: queue.length,
                      itemBuilder: (c, i) => Card(
                        color: Colors.black26,
                        child: ListTile(
                          dense: true,
                          title: Text(queue[i]['kat']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 12)),
                          subtitle: Text('1:${queue[i]['j1nama']} | 2:${queue[i]['j2nama']}', style: const TextStyle(fontSize: 10)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.upload, color: Colors.blue, size: 18), onPressed: () {
                                setState(() { 
                                  _katCtrl.text = queue[i]['kat']!; 
                                  _j1noCtrl.text = queue[i]['j1no']!; _j1namaCtrl.text = queue[i]['j1nama']!; _j1hadiahCtrl.text = queue[i]['j1hadiah'] ?? '';
                                  _j2noCtrl.text = queue[i]['j2no']!; _j2namaCtrl.text = queue[i]['j2nama']!; _j2hadiahCtrl.text = queue[i]['j2hadiah'] ?? '';
                                  _j3noCtrl.text = queue[i]['j3no']!; _j3namaCtrl.text = queue[i]['j3nama']!; _j3hadiahCtrl.text = queue[i]['j3hadiah'] ?? '';
                                });
                                _updateStandbyData();
                              }),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 18), onPressed: () => setState(()=> queue.removeAt(i))),
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
          
          // ==================== KOLOM 2: LAYAR KONTROL & PREVIEW ====================
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(15), decoration: const BoxDecoration(border: Border(right: BorderSide(color: Colors.white12))), 
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('2. LIVE KONTROL', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      Row(
                        children: [
                          const Text('Tampilkan Hadiah:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Switch(value: showHadiah, activeColor: Colors.greenAccent, onChanged: (v) { setState(() { showHadiah = v; }); _saveSettings(); }),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),
                  const Align(alignment: Alignment.centerLeft, child: Text('LIVE OUTPUT (Preview Layar LED)', style: TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.redAccent, width: 3), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.2), blurRadius: 20)]),
                        child: _buildPreviewScreen(liveAction == 'clear' ? {} : liveData, liveAction),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // ==================== KOLOM 3: KUSTOMISASI ====================
          Expanded(
            flex: 3,
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Colors.amber, labelColor: Colors.amber, unselectedLabelColor: Colors.white54,
                    tabs: [Tab(icon: Icon(Icons.settings), text: 'Desain'), Tab(icon: Icon(Icons.text_fields), text: 'Font'), Tab(icon: Icon(Icons.format_shapes), text: 'Dimensi')]
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        // TAB 1: DESAIN & BACKGROUND
                        ListView(
                          padding: const EdgeInsets.all(15),
                          children: [
                            const Text('Background & Animasi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(icon: const Icon(Icons.wallpaper), label: const Text('Pilih Background Video/Img'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, minimumSize: const Size(double.infinity, 45)), onPressed: _pickBackground),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Text(isVideoError ? 'Format Video Ditolak' : (bgPath ?? 'Tidak ada background'), style: TextStyle(fontSize: 10, color: isVideoError ? Colors.red : Colors.grey), maxLines: 2)),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: animStyle, decoration: const InputDecoration(isDense: true, labelText: 'Gaya Animasi Masuk', border: OutlineInputBorder()),
                              items: const [DropdownMenuItem(value: 'bounce', child: Text('Zoom Membal (Bounce)')), DropdownMenuItem(value: 'slide', child: Text('Slide Terbang (Halus)')), DropdownMenuItem(value: 'fade', child: Text('Fade In (Sederhana)'))],
                              onChanged: (v) { setState(() { animStyle = v!; }); _saveSettings(); }
                            ),
                            const SizedBox(height: 15),
                            DropdownButtonFormField<String>(
                              value: boxStyle, decoration: const InputDecoration(isDense: true, labelText: 'Bentuk Kotak Pemenang', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: 'rounded_border', child: Text('Melengkung + Garis Tepi')), 
                                DropdownMenuItem(value: 'rounded_no_border', child: Text('Melengkung Polos')), 
                                DropdownMenuItem(value: 'square_border', child: Text('Persegi Tajam + Garis Tepi')),
                                DropdownMenuItem(value: 'square_no_border', child: Text('Persegi Tajam Polos')),
                                DropdownMenuItem(value: 'pill', child: Text('Kapsul Bulat (Pill Shape)'))
                              ],
                              onChanged: (v) { setState(() { boxStyle = v!; }); _saveSettings(); }
                            ),
                            const Divider(height: 30),
                            const Text('Palet Warna Kotak:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                            const SizedBox(height: 10),
                            _buildColorPicker('J3', c3, (c) => setState(() { c3 = c; _saveSettings(); })),
                            _buildColorPicker('J1', c1, (c) => setState(() { c1 = c; _saveSettings(); })),
                            _buildColorPicker('J2', c2, (c) => setState(() { c2 = c; _saveSettings(); })),
                          ],
                        ),
                        // TAB 2: TEKS & FONT
                        ListView(
                          padding: const EdgeInsets.all(15),
                          children: [
                            TextField(controller: _mainTitleCtrl, decoration: const InputDecoration(labelText: 'Teks Judul Utama', border: OutlineInputBorder(), isDense: true), onChanged: (_) => _saveSettings()),
                            const SizedBox(height: 15),
                            DropdownButtonFormField<String>(value: fTitle, decoration: const InputDecoration(isDense: true, labelText: 'Font Judul', border: OutlineInputBorder()), items: fontChoices.map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontFamily: f)))).toList(), onChanged: (v) { setState(() { fTitle = v!; }); _saveSettings(); }),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(value: fKat, decoration: const InputDecoration(isDense: true, labelText: 'Font Kategori', border: OutlineInputBorder()), items: fontChoices.map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontFamily: f)))).toList(), onChanged: (v) { setState(() { fKat = v!; }); _saveSettings(); }),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(value: fBox, decoration: const InputDecoration(isDense: true, labelText: 'Font Kotak Pemenang', border: OutlineInputBorder()), items: fontChoices.map((f) => DropdownMenuItem(value: f, child: Text(f, style: TextStyle(fontFamily: f)))).toList(), onChanged: (v) { setState(() { fBox = v!; }); _saveSettings(); }),
                            const Divider(height: 30),
                            _buildSlider('Ukuran Judul', sMainTitle, 30, 150, (v) => setState(() => sMainTitle = v)),
                            _buildSlider('Ukuran Kategori', sKat, 15, 80, (v) => setState(() => sKat = v)),
                            _buildSlider('Ukuran "JUARA"', sTitleBox, 15, 80, (v) => setState(() => sTitleBox = v)),
                            _buildSlider('Ukuran NOMOR', sNo, 20, 150, (v) => setState(() => sNo = v)),
                            _buildSlider('Ukuran NAMA', sNama, 30, 150, (v) => setState(() => sNama = v)),
                            _buildSlider('Ukuran HADIAH', sHadiah, 15, 100, (v) => setState(() => sHadiah = v)),
                          ],
                        ),
                        // TAB 3: DIMENSI & POSISI
                        ListView(
                          padding: const EdgeInsets.all(15),
                          children: [
                            const Text('Pengaturan Tata Letak:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                            const SizedBox(height: 10),
                            _buildSlider('Posisi Atas/Bawah JUDUL', sMainTitleY, -300, 300, (v) => setState(() => sMainTitleY = v)),
                            _buildSlider('Posisi Atas/Bawah KATEGORI', sKatY, -100, 300, (v) => setState(() => sKatY = v)),
                            _buildSlider('Posisi Y KOTAK KESELURUHAN', sPosY, -500, 500, (v) => setState(() => sPosY = v)),
                            const Divider(height: 30),
                            _buildSlider('Skala Kotak Keseluruhan', sScale, 50, 150, (v) => setState(() => sScale = v)),
                            _buildSlider('Lebar Kotak', sWidth, 200, 800, (v) => setState(() => sWidth = v)),
                            _buildSlider('Tinggi Kotak (Padding)', sPad, 10, 100, (v) => setState(() => sPad = v)),
                            _buildSlider('Transparansi Kotak (%)', opBox * 100, 10, 100, (v) => setState(() => opBox = v / 100)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow(String label, Color c, TextEditingController c1, TextEditingController c2, TextEditingController c3) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: c.withOpacity(0.5)), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 5),
          Row(children: [
            Expanded(flex: 1, child: TextField(controller: c1, decoration: const InputDecoration(labelText: 'No Dada', isDense: true, border: OutlineInputBorder()), onChanged: (_) => _updateStandbyData())),
            const SizedBox(width: 5),
            Expanded(flex: 2, child: TextField(controller: c2, decoration: const InputDecoration(labelText: 'Nama Pemenang', isDense: true, border: OutlineInputBorder()), onChanged: (_) => _updateStandbyData())),
          ]),
          const SizedBox(height: 5),
          TextField(controller: c3, decoration: const InputDecoration(labelText: 'Hadiah (Misal: Rp 10.000.000)', isDense: true, border: OutlineInputBorder(), prefixIcon: Icon(Icons.card_giftcard, size: 16)), onChanged: (_) => _updateStandbyData()),
        ],
      ),
    );
  }

  Widget _buildColorPicker(String label, Color current, ValueChanged<Color> onSelect) {
    List<Color> palette = [Colors.amber, Colors.orange, Colors.deepOrange, Colors.red, Colors.pink, Colors.purple, Colors.blue, Colors.teal, Colors.green, Colors.blueGrey, Colors.grey.shade800, Colors.black87];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(child: Wrap(spacing: 6, runSpacing: 6, children: palette.map((c) => InkWell(onTap: () => onSelect(c), child: Container(width: 24, height: 24, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: current == c ? Colors.white : Colors.transparent, width: 2))))).toList()))
        ],
      ),
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label (${val.toInt()})', style: const TextStyle(fontSize: 11, color: Colors.white70)),
        Slider(value: val, min: min, max: max, activeColor: Colors.amber, inactiveColor: Colors.white12, onChanged: (v) { onChanged(v); _saveSettings(); }),
      ],
    );
  }

  Widget _buildPreviewScreen(Map<String, dynamic> data, String action) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: FittedBox(
          fit: BoxFit.contain, 
          child: SizedBox(
            width: 1920, height: 1080,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bgPath != null)
                  (bgPath!.toLowerCase().endsWith('.mp4') || bgPath!.toLowerCase().endsWith('.mov') || bgPath!.toLowerCase().endsWith('.mkv') || bgPath!.toLowerCase().endsWith('.avi'))
                    ? (_previewVideoCtrl != null)
                      ? Video(controller: _previewVideoCtrl!, fit: BoxFit.cover, controls: (s) => const SizedBox.shrink())
                      : const Center(child: Icon(Icons.video_file, color: Colors.white24, size: 50))
                    : Image.file(File(bgPath!), key: ValueKey(bgPath), fit: BoxFit.cover)
                else
                  Container(color: Colors.black),
                
                if (data.isNotEmpty)
                  LedCanvasWidget(d: data, action: action)
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// BAGIAN 2: APLIKASI LED (MURNI TANPA ERROR)
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
  Player? _player;
  VideoController? _videoCtrl;
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
        if (['mp4', 'mov', 'avi', 'mkv', 'webm', 'flv'].contains(ext)) {
          isVideo = true;
          _player?.dispose();
          _player = Player();
          _videoCtrl = VideoController(_player!);
          try {
            await _player!.setPlaylistMode(PlaylistMode.single);
            await _player!.open(Media(activeBg!));
            if (mounted) setState(() {});
          } catch (e) {
            isVideo = false;
            if (mounted) setState(() {});
          }
        } else {
          isVideo = false; _player?.dispose(); _player = null; _videoCtrl = null;
          if (mounted) setState(() {}); 
        }
      }
      if (mounted) { setState(() { currentAction = newData['action']; d = newData; }); }
    }
  }

  @override
  void dispose() { 
    _player?.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // MEMAKAI VLC ENGINE
          if (isVideo && _videoCtrl != null)
            Video(controller: _videoCtrl!, fit: BoxFit.cover, controls: (s) => const SizedBox.shrink())
          else if (!isVideo && activeBg != null)
            Image.file(File(activeBg!), key: ValueKey(activeBg), fit: BoxFit.cover, errorBuilder: (c,e,s) => Container(color: Colors.black)),
          
          if (d.isNotEmpty)
            LedCanvasWidget(d: d, action: currentAction),
        ],
      ),
    );
  }
}

// ==========================================
// KANVAS PEMENANG
// ==========================================
class LedCanvasWidget extends StatelessWidget {
  final Map<String, dynamic> d;
  final String action;
  
  const LedCanvasWidget({Key? key, required this.d, required this.action}) : super(key: key);

  Color _parseColor(dynamic val, Color fallback) {
    if (val == null) return fallback;
    if (val is int) return Color(val);
    return fallback;
  }

  Widget _buildBox(String title, String no, String name, String hadiah, Color col, bool isCenter, bool isVisible) {
    String fontBox = d['fBox'] ?? 'Segoe UI';
    double opBox = d['opBox'] ?? 0.95;
    String anim = d['animStyle'] ?? 'bounce';
    String bStyle = d['boxStyle'] ?? 'rounded_border';
    bool showHadiah = d['showHadiah'] ?? true;

    String safeNo = (no.isEmpty) ? '-' : no;
    String safeName = (name.isEmpty) ? '...' : name;

    BorderRadius br = BorderRadius.circular(20);
    if (bStyle.contains('square')) br = BorderRadius.circular(0);
    if (bStyle.contains('pill')) br = BorderRadius.circular(100);

    Border b = Border.all(color: Colors.white, width: isCenter ? 6 : 3);
    if (bStyle.contains('no_border')) b = Border.all(color: Colors.transparent, width: 0);

    Widget boxContent = Container(
      margin: EdgeInsets.only(left: 10, right: 10, bottom: isCenter ? 40 : 0),
      padding: EdgeInsets.symmetric(vertical: d['sPad'] ?? 40, horizontal: 20),
      width: d['sWidth'] ?? 400,
      decoration: BoxDecoration(
        color: col.withOpacity(opBox),
        borderRadius: br,
        border: b,
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontFamily: fontBox, fontSize: d['sTitleBox'] ?? 35, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 2)),
          const SizedBox(height: 10),
          Text(safeNo, style: TextStyle(fontFamily: fontBox, fontSize: d['sNo'] ?? 50, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Text(safeName, textAlign: TextAlign.center, style: TextStyle(fontFamily: fontBox, fontSize: d['sNama'] ?? 65, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1, shadows: const [Shadow(color: Colors.black, blurRadius: 5)]), maxLines: 2, overflow: TextOverflow.ellipsis),
          
          if (showHadiah && hadiah.isNotEmpty) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.yellowAccent.withOpacity(0.5))),
              child: Text(hadiah, style: TextStyle(fontFamily: fontBox, fontSize: d['sHadiah'] ?? 35, fontWeight: FontWeight.w900, color: Colors.yellowAccent)),
            )
          ]
        ],
      ),
    );

    return TweenAnimationBuilder<double>(
      key: ValueKey('${action}_$title'), 
      tween: Tween(begin: 0.0, end: isVisible ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 800),
      curve: anim == 'bounce' ? Curves.elasticOut : (anim == 'slide' ? Curves.easeOutCubic : Curves.easeIn),
      builder: (context, val, child) {
        if (anim == 'bounce') { return Transform.scale(scale: val, child: Opacity(opacity: val.clamp(0.0, 1.0), child: child)); } 
        else if (anim == 'slide') { return Transform.translate(offset: Offset(0, 150 * (1 - val)), child: Opacity(opacity: val.clamp(0.0, 1.0), child: child)); } 
        else { return Opacity(opacity: val.clamp(0.0, 1.0), child: child); }
      },
      child: boxContent,
    );
  }

  Widget _buildBoxLayout() {
    if (action == 'clear') return const SizedBox.shrink();

    bool showAll = action == 'all';
    Color c1 = _parseColor(d['c1'], Colors.amber);
    Color c2 = _parseColor(d['c2'], Colors.blueGrey);
    Color c3 = _parseColor(d['c3'], Colors.deepOrange);

    if (showAll) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBox('JUARA 3', d['j3no'] ?? '', d['j3nama'] ?? '', d['j3hadiah'] ?? '', c3, false, true),
            _buildBox('JUARA 1', d['j1no'] ?? '', d['j1nama'] ?? '', d['j1hadiah'] ?? '', c1, true, true),
            _buildBox('JUARA 2', d['j2no'] ?? '', d['j2nama'] ?? '', d['j2hadiah'] ?? '', c2, false, true),
          ],
        ),
      );
    } else {
      String t = ''; String no = ''; String na = ''; String h = ''; Color c = Colors.black;
      if (action == 'j1') { t = 'JUARA 1'; no = d['j1no'] ?? ''; na = d['j1nama'] ?? ''; h = d['j1hadiah'] ?? ''; c = c1; }
      if (action == 'j2') { t = 'JUARA 2'; no = d['j2no'] ?? ''; na = d['j2nama'] ?? ''; h = d['j2hadiah'] ?? ''; c = c2; }
      if (action == 'j3') { t = 'JUARA 3'; no = d['j3no'] ?? ''; na = d['j3nama'] ?? ''; h = d['j3hadiah'] ?? ''; c = c3; }
      return FittedBox(fit: BoxFit.scaleDown, child: _buildBox(t, no, na, h, c, true, true));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (action == 'clear') return const SizedBox.shrink();

    String fTitle = d['fTitle'] ?? 'Impact';
    String fKat = d['fKat'] ?? 'Segoe UI';
    
    return Transform.scale(
      scale: (d['sScale'] ?? 100) / 100.0,
      child: Transform.translate(
        offset: Offset(0, d['sPosY'] ?? 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500), opacity: 1.0,
              child: Transform.translate(
                offset: Offset(0, d['sMainTitleY'] ?? 0),
                child: Text(d['mainTitle'] ?? 'PEMENANG LOMBA', textAlign: TextAlign.center, style: TextStyle(fontFamily: fTitle, fontSize: d['sMainTitle'] ?? 80, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 5, shadows: const [Shadow(color: Colors.black, blurRadius: 20)])),
              ),
            ),
            
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500), opacity: (d['kat'] != null && d['kat'].toString().isNotEmpty) ? 1.0 : 0.0,
              child: Transform.translate(
                offset: Offset(0, d['sKatY'] ?? 0),
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 40), 
                  width: d['sKatWidth'] ?? 250,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: d['sKatPad'] ?? 15),
                  decoration: BoxDecoration(
                    color: _parseColor(d['cKat'], Colors.black87).withOpacity(d['opKat'] ?? 0.8), 
                    borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.white30)
                  ),
                  child: Text(d['kat'] ?? '', textAlign: TextAlign.center, style: TextStyle(fontFamily: fKat, fontSize: d['sKat'] ?? 35, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 3)),
                ),
              ),
            ),

            if (d['kat'] == null || d['kat'].toString().isEmpty) const SizedBox(height: 100),

            _buildBoxLayout()
          ],
        ),
      ),
    );
  }
}
