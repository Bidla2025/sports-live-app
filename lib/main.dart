import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const SportsLiveApp());
}

class SportsLiveApp extends StatelessWidget {
  const SportsLiveApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Live Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F111A), // اللون الداكن للموقع
        primaryColor: const Color(0xFF1E2235),
      ),
      home: const HomeScreen(),
    );
  }
}

// شاشة جدول المباريات الرئيسية
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> matches = [];
  bool isLoading = true;
  String selectedSport = "All"; // الرياضة المختارة: الكل، كرة القدم، NBA

  @override
  void initState() {
    super.initState();
    fetchMatches();
  }

  // دالة جلب البيانات من الـ API الخاص بالودجت
  async fetchMatches() {
    final url = Uri.parse('https://backend.streamcenter.live/api/Parties?pageNumber=1&pageSize=500');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          matches = data['items'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
      print("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // تصفية المباريات بناءً على التبويب المختار (كرة قدم أو كرة سلة/NBA)
    List<dynamic> filteredMatches = matches.where((match) {
      if (selectedSport == "All") return true;
      if (selectedSport == "Basketball") {
        return match['categoryName'].toString().toLowerCase().contains('basket') || 
               match['categoryName'].toString().toLowerCase().contains('nba');
      }
      if (selectedSport == "Football") {
        return match['categoryName'].toString().toLowerCase().contains('foot');
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiveScore Hub', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141824),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            setState(() { isLoading = true; });
            fetchMatches();
          }),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              // شريط اختيار الرياضة (Tabs) كما في التصميم
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: const Color(0xFF141824),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    sportTab("الكل", "All", Icons.sports_handball),
                    sportTab("كرة القدم", "Football", Icons.sports_soccer),
                    sportTab("NBA / السلة", "Basketball", Icons.sports_basketball),
                  ],
                ),
              ),
              // قائمة مباريات اليوم
              Expanded(
                child: filteredMatches.isEmpty 
                  ? const Center(child: Text("لا توجد مباريات مباشرة حالياً"))
                  : ListView.builder(
                      itemCount: filteredMatches.length,
                      itemBuilder: (context, index) {
                        final match = filteredMatches[index];
                        return MatchCard(match: match);
                      },
                    ),
              ),
            ],
          ),
    );
  }

  Widget sportTab(String title, String value, IconData icon) {
    bool isSelected = selectedSport == value;
    return GestureDetector(
      onTap: () {
        setState(() { selectedSport = value; });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF246BFD) : Colors.transparent, // الأزرق الجميل من القالب
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// تصميم بطاقة المباراة (Match Card)
class MatchCard extends StatelessWidget {
  final dynamic match;
  const MatchCard({Key? key, required this.match}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2235), // ألوان القالب الداكنة
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(match['categoryName'] ?? 'بطولة رياضية', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الفريق الأول
              Expanded(
                child: Column(
                  children: [
                    Image.network(match['team1Logo'] ?? '', height: 40, errorBuilder: (_,__,___) => const Icon(Icons.sports)),
                    const SizedBox(height: 6),
                    Text(match['team1Name'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              // التوقيت أو كلمة LIVE
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Text("LIVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(match['time'] ?? '00:00', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              // الفريق الثاني
              Expanded(
                child: Column(
                  children: [
                    Image.network(match['team2Logo'] ?? '', height: 40, errorBuilder: (_,__,___) => const Icon(Icons.sports)),
                    const SizedBox(height: 6),
                    Text(match['team2Name'] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // زر الانتقال للبث المباشر المباشر
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF246BFD),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // الانتقال لصفحة المشغل الذكي المحمية ضد الإعلانات
              String matchId = match['id'].toString();
              String streamUrl = "https://streams.center/embed/ch$matchId.php"; // توليد رابط البث التلقائي لكل مباراة
              Navigator.push(
                context,
                MaterialAppRoute(builder: (context) => StreamPlayerScreen(streamUrl: streamUrl)),
              );
            },
            child: const Text("شاهد البث المباشر الآن", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
class StreamPlayerScreen extends StatelessWidget {
  final String streamUrl;
  const StreamPlayerScreen({Key? key, required this.streamUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("مشغل البث المباشر"), backgroundColor: const Color(0xFF141824)),
      body: Column(
        children: [
          // 1. مساحة مشغل الفيديو الذكي (تم تكبير الارتفاع ليناسب المشاهدة المريحة 16:9)
          Container(
            height: MediaQuery.of(context).size.height * 0.32, // يأخذ 32% من حجم الشاشة بالكامل
            color: Colors.black,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(streamUrl)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true, // تشغيل الفيديو بجافا سكربت
                supportMultipleWindows: false, // حظر الإعلانات التي تحاول فتح نوافذ جديدة منبثقة
                javaScriptCanOpenWindowsAutomatically: false,
                useShouldOverrideUrlLoading: true,
              ),
              onWebViewCreated: (controller) {
                // تفعيل الفلاتر البرمجية لحظر شركات الإعلانات المزعجة تلقائياً
                controller.contentBlockerHandler = ContentBlockerHandler(
                  blockers: [
                    ContentBlocker(
                      trigger: ContentBlockerTrigger(
                        urlFilter: ".*(popads|onclickads|adsterra|exoclick|popcash|juicyads|propellerads).*",
                      ),
                      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // 2. مساحة مخصصة لعرض أرباحك وإعلاناتك أنت!
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("تفاصيل المباراة مستمرة الآن...", style: TextStyle(color: Colors.grey)),
                  const Spacer(),
                  // هنا نضع كود إعلان البنر الخاص بك (مثلاً Google AdMob)
                  Container(
                    width: double.infinity,
                    height: 100,
                    color: const Color(0xFF1E2235), // يظهر في نفس مساحة الملعب المحذوف
                    child: const Center(
                      child: Text(
                        "مساحة إعلاناتك الخاصة هنا (للربح 100%)",
                        style: TextStyle(color: Color(0xFF246BFD), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
