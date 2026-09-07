import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:string_similarity/string_similarity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const IslamicSukunApp());
}

class IslamicSukunApp extends StatelessWidget {
  const IslamicSukunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NUR BY SAJIT',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.emerald,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const QuranVisualScreen(),
    const HadithScreen(),
    const TasbihScreen(),
    const AIAssistantScreen(),
    const GameAndSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.emeraldAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'কোরআন'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books), label: 'হাদিস'),
          BottomNavigationBarItem(icon: Icon(Icons.fingerprint), label: 'তসবিহ'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI হাদিস'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'গেম ও সেটিংস'),
        ],
      ),
    );
  }
}

class QuranVisualScreen extends StatefulWidget {
  const QuranVisualScreen({super.key});

  @override
  State<QuranVisualScreen> createState() => _QuranVisualScreenState();
}

class _QuranVisualScreenState extends State<QuranVisualScreen> {
  late VideoPlayerController _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentBgIndex = 0;
  Timer? _bgTimer;
  String _searchQuery = "";
  bool _isPlaying = false;

  final List<String> _videoUrls = [
    'https://assets.mixkit.co/videos/preview/mixkit-sea-waves-approaching-the-beach-40813-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-starry-sky-in-the-night-40342-large.mp4',
    'https://assets.mixkit.co/videos/preview/mixkit-clouds-and-blue-sky-2408-large.mp4',
  ];

  final List<Map<String, String>> _surahList = [
    {"num": "1", "name": "Al-Fatiha", "bangla": "আল-ফাতিহা", "audio": "https://server8.mp3quran.net/dosari/001.mp3"},
    {"num": "2", "name": "Al-Baqarah", "bangla": "আল-বাক্বারাহ", "audio": "https://server8.mp3quran.net/dosari/002.mp3"},
    {"num": "3", "name": "Ali 'Imran", "bangla": "আলে-ইমরান", "audio": "https://server8.mp3quran.net/dosari/003.mp3"},
    {"num": "255", "name": "Ayatul Kursi", "bangla": "আয়াতুল কুরসী", "audio": "https://server8.mp3quran.net/dosari/002255.mp3"},
  ];

  @override
  void initState() {
    super.initState();
    _initVideo(_videoUrls[0]);

    _bgTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _videoUrls.length;
        });
        _initVideo(_videoUrls[_currentBgIndex]);
      }
    });
  }

  void _initVideo(String url) {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        if (mounted) setState(() {});
      });
  }

  void _playSurahAudio(String audioUrl) async {
    await _audioPlayer.setUrl(audioUrl);
    _audioPlayer.play();
    setState(() => _isPlaying = true);
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    _videoController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var filteredList = _surahList.where((surah) {
      if (_searchQuery.isEmpty) return true;
      double simName = surah['name']!.toLowerCase().similarityTo(_searchQuery.toLowerCase());
      double simNum = surah['num']!.similarityTo(_searchQuery);
      return simName > 0.3 || simNum > 0.5 || surah['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Stack(
      children: [
        if (_videoController.value.isInitialized)
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            ),
          ),
        Container(color: Colors.black.withOpacity(0.55)),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'সূরা বা আয়াত সার্চ করুন (যেমন: Al Baqarah 255)...',
                    prefixIcon: const Icon(Icons.search, color: Colors.emeraldAccent),
                    filled: true,
                    fillColor: Colors.black87,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    var item = filteredList[index];
                    return Card(
                      color: Colors.black45,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.emerald,
                          child: Text(item['num']!, style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text(item['bangla']!),
                        trailing: IconButton(
                          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.emeraldAccent, size: 36),
                          onPressed: () => _playSurahAudio(item['audio']!),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  final List<String> _books = const [
    "সহীহ বুখারী", "সহীহ মুসলিম", "সূনানে আন-নাসায়ী", 
    "সুনানে আবু দাউদ", " জামে' আত-তিরমিজী", "সুনানে ইবনে মাজাহ"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('সিহাহ সিত্তাহ হাদিস গ্রন্থ'), backgroundColor: Colors.black),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'হাদিস সার্চ (যেমন: Sahih Bukhari 550)...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _books.length,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.grey[900],
                  child: ListTile(
                    leading: const Icon(Icons.menu_book, color: Colors.emeraldAccent),
                    title: Text(_books[index], style: const TextStyle(fontSize: 18)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${_books[index]} লোড হচ্ছে...')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _loadCounter();
  }

  void _loadCounter() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _counter = prefs.getInt('tasbih') ?? 0);
  }

  void _increment() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _counter++);
    prefs.setInt('tasbih', _counter);
  }

  void _reset() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _counter = 0);
    prefs.setInt('tasbih', 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ডিজিটাল তসবিহ'), backgroundColor: Colors.black),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('সুবহানআল্লাহ / আলহামদুলিল্লাহ', style: TextStyle(fontSize: 22, color: Colors.emeraldAccent)),
            const SizedBox(height: 30),
            Text('$_counter', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _increment,
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(color: Colors.emerald, shape: BoxShape.circle),
                child: const Center(child: Text('গণনা করুন', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              ),
            ),
            const SizedBox(height: 30),
            TextButton(onPressed: _reset, child: const Text('রিসেট করুন', style: TextStyle(color: Colors.redAccent))),
          ],
        ),
      ),
    );
  }
}

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    String userMsg = _controller.text;
    setState(() {
      _messages.add({"role": "user", "text": userMsg});
      _messages.add({"role": "ai", "text": "কোরআন ও সহীহ হাদিস অনুযায়ী: " + userMsg + " সম্পর্কে স্পষ্ট বর্ণনা রয়েছে।"});
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ইসলামিক AI অ্যাসিস্ট্যান্ট'), backgroundColor: Colors.black),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                bool isUser = _messages[i]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.emerald : Colors.grey[800],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(_messages[i]['text']!),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'ইসলামিক যেকোনো প্রশ্ন লিখুন...'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Colors.emeraldAccent), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class GameAndSettingsScreen extends StatelessWidget {
  const GameAndSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ইসলামিক গেম ও সেটিংস'), backgroundColor: Colors.black),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.extension, color: Colors.emeraldAccent),
            title: Text('ইসলামিক কুইজ গেম'),
            subtitle: Text('জ্ঞান বৃদ্ধি করতে কুইজ খেলুন'),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('অটো আযান নোটিফিকেশন'),
            subtitle: const Text('ওয়াক্ত হলে স্বয়ংক্রিয় আযান দেবে'),
            value: true,
            onChanged: (val) {},
          ),
          const ListTile(
            leading: Icon(Icons.download, color: Colors.blue),
            title: Text('ডাউনলোডকৃত অফলাইন সুরা'),
          ),
          const ListTile(
            leading: Icon(Icons.favorite, color: Colors.red),
            title: Text('প্রিয় আয়াত ও ফোল্ডার'),
          ),
        ],
      ),
    );
  }
}
