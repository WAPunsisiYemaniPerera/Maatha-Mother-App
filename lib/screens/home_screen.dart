import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/matha_background.dart'; 
import '../services/sos_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- සති ගණන අනුව Emoji සහ විස්තර ලබා ගැනීමේ Logic එක ---
  Map<String, String> getBabyGrowthInfo(int week) {
    if (week <= 4) return {
      "fruit": "බීජයක් / Tiny Seed", 
      "emoji": "🌱", 
      "desc": "දරුවා දැන් කුඩා බීජයක් මෙන් වේ. අනාගතයේ ලොකු ගසක් වීමට පදනම වැටේ.\nBaby is like a tiny seed."
    };
    if (week <= 8) return {
      "fruit": "මුද්‍රප්පලම් / Raspberry", 
      "emoji": "🍇", 
      "desc": "දරුවා මුද්‍රප්පලම් ගෙඩියක් තරම් වේ. දැන් හෘද ස්පන්දනය ඇරඹී ඇත.\nBaby is the size of a raspberry."
    };
    if (week <= 12) return {
      "fruit": "දෙහි ගෙඩියක් / Lime", 
      "emoji": "🍋", 
      "desc": "දරුවා දැන් දෙහි ගෙඩියක් තරම් වේ. දරුවාගේ මුහුණේ අවයව සෑදී ඇත.\nBaby is the size of a lime."
    };
    if (week <= 24) return {
      "fruit": "පැපොල් ගෙඩියක් / Papaya", 
      "emoji": "🥭", 
      "desc": "දරුවා දැන් පැපොල් ගෙඩියක් තරම් වේ. ඇස් ඇරීමට හා පියවීමට හැකිය.\nBaby is the size of a papaya."
    };
    return {
      "fruit": "පුංචි බබෙක් / Fully Formed Baby", 
      "emoji": "👶", 
      "desc": "දරුවා දැන් මෙලොවට ඒමට සූදානම්! ඔබ සැමට සුබ ගමන්!\nBaby is now ready to meet the world!"
    };
  }

  // --- දිනපතා වෙනස් වන සෞඛ්‍ය උපදෙස් ---
  String getDailyTip() {
    int day = DateTime.now().weekday;
    List<String> tips = [
      "අද ප්‍රමාණවත් තරම් ජලය පානය කළාද? (Drink enough water)",
      "ගුණදායක පලතුරු ආහාරයට එක් කරගන්න. (Eat fresh fruits)",
      "මද වේලාවක් ඇවිදීම ඔබට සුවදායක වේවි. (Go for a small walk)",
      "අද දින විටමින් පෙති ලබාගැනීමට අමතක නොකරන්න. (Take your vitamins)",
      "ප්‍රමාණවත් තරම් විවේකයක් ලබාගන්න. (Get plenty of rest)",
      "මනස සන්සුන්ව තබා ගැනීමට සංගීතයට සවන් දෙන්න. (Listen to calm music)",
      "දරුවා සමඟ කතා කරන්න, ඔහු ඔබට සවන් දෙනවා. (Talk to your baby)"
    ];
    return tips[day - 1];
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    String? currentNic = currentUser?.email?.split('@').first;

    return MathaBackground(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mothers')
            .where('nic', isEqualTo: currentNic)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFF06292)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("දත්ත සොයාගත නොහැක / Data Not Found"));
          }

          var d = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          String fullName = d['fullName'] ?? "Mother";
          String midwife = d['assignedMidwife'] ?? "Mrs. Priyanka Perera";
          String riskStatus = d['riskStatus'] ?? "Normal";
          String? emergencyContact = d['phone'];

          DateTime lmpDate = (d['lmp'] as Timestamp).toDate();
          DateTime eddDate = (d['edd'] as Timestamp).toDate();
          int totalDays = DateTime.now().difference(lmpDate).inDays;
          int weeks = totalDays ~/ 7;
          int days = totalDays % 7;
          int daysToEdd = eddDate.difference(DateTime.now()).inDays;

          var growthInfo = getBabyGrowthInfo(weeks);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildHeader(fullName),
                _buildEmergencySOS(context, midwife, emergencyContact),
                const SizedBox(height: 20),
                _buildProgressCard(weeks, days, daysToEdd),
                _buildSectionTitle("Daily Health Tip | අද දවසේ උපදෙස්"),
                _buildDailyTipCard(),
                _buildSectionTitle("Baby's Growth | දරුවාගේ වර්ධනය"),
                _buildBabyGrowthCard(weeks, growthInfo),
                _buildSectionTitle("Health Status | සෞඛ්‍ය තත්ත්වය"),
                _buildRiskStatus(riskStatus),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- SOS Button (Emphasized) ---
  Widget _buildEmergencySOS(BuildContext context, String midwife, String? contact) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onLongPress: () async {
            await SOSService().triggerSOS(midwife, contact);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("හදිසි පණිවිඩය සහ ඇමතුම යොමු කළා!")),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.emergency_share, color: Colors.red, size: 45),
                SizedBox(height: 10),
                Text("EMERGENCY SOS", style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                Text(
                  "හදිසි අවස්ථාවකදී තද කර අල්ලාගෙන සිටින්න\n(Call Midwife & Emergency Number)",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Baby Growth Card with Animated Emoji ---
  Widget _buildBabyGrowthCard(int week, Map<String, String> info) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          // Emoji එකක් භාවිතා කිරීම (Cute Animation effect එකක් සමඟ)
          TweenAnimationBuilder(
            tween: Tween<double>(begin: 0.8, end: 1.1),
            duration: const Duration(seconds: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: value,
                child: Text(info['emoji']!, style: const TextStyle(fontSize: 60)),
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("සතිය $week - ${info['fruit']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1565C0))),
                const SizedBox(height: 5),
                Text(info['desc']!, style: const TextStyle(fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Daily Tip Card ---
  Widget _buildDailyTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.lightBlue.shade100, Colors.white]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.orangeAccent, size: 35),
          const SizedBox(width: 15),
          Expanded(child: Text(getDailyTip(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
        ],
      ),
    );
  }

  // --- Header, Progress, Risk Widgets (වෙනස් කර නැත) ---
  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("ආයුබෝවන්, ${name.split(' ').first}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1565C0))),
            const Text("නිරෝගී දවසක්! 🌸", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ]),
          const CircleAvatar(backgroundColor: Color(0xFFF06292), radius: 25, child: Icon(Icons.person, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int weeks, int days, int daysToEdd) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFF06292), Color(0xFFE91E63)]),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Text("ගැබ් කාලය / Progress", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _timeBox(weeks, "සති"),
            const SizedBox(width: 30),
            _timeBox(days, "දින"),
          ]),
          const Divider(color: Colors.white24, height: 30),
          Text("ප්‍රසූතියට තව දින $daysToEdd කි / Days left: $daysToEdd", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _timeBox(int val, String unit) {
    return Column(children: [
      Text("$val", style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900)),
      Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 14)),
    ]);
  }

  Widget _buildRiskStatus(String status) {
    Color color = status == "High-Risk" ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [
        Icon(Icons.shield_moon_rounded, color: color),
        const SizedBox(width: 15),
        Text("තත්ත්වය: $status / Status: $status", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 15), child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45))));
  }
}