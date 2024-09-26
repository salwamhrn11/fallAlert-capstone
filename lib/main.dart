import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:math';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the date formatting for the 'id' locale (Indonesian)
  await initializeDateFormatting('id', null);

  // Run the app after initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Inter',
          ),
        ),
      ),
      home: const ConnectPage(),
    );
  }
}

// Page to connect to hardware
class ConnectPage extends StatefulWidget {
  const ConnectPage({Key? key}) : super(key: key);

  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  final TextEditingController serverController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Connect to Your Device',
          style: TextStyle(
              fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HealthOverviewScreen()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                TextField(
                  controller: serverController, // Mengambil input dari user
                  decoration: InputDecoration(
                    labelText: 'Enter your server',
                    prefixIcon: Image.asset(
                      'images/iconserver.png',
                      width: 24,
                      height: 24,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA1A8B0),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: portController, // Mengambil input dari user
                  decoration: InputDecoration(
                    labelText: 'Enter your port',
                    prefixIcon: Image.asset(
                      'images/iconport.png',
                      width: 24,
                      height: 24,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFA1A8B0),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Validasi input
                if (serverController.text.isNotEmpty && portController.text.isNotEmpty) {
                  // Jika valid, arahkan ke halaman HealthOverviewScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HealthOverviewScreen()),
                  );
                } else {
                  // Jika tidak valid, tampilkan pesan error
                  setState(() {
                    errorMessage = 'Both server and port must be filled!';
                  });
                }
              },
              child: const SizedBox(
                width: 327,
                height: 56,
                child: Center(
                  child: Text(
                    'Connect',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E7A8F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                minimumSize: const Size(327, 56),
              ),
            ),
            const SizedBox(height: 16),
            // Menampilkan pesan error jika ada
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

// Health overview dashboard page
class HealthOverviewScreen extends StatefulWidget {
  const HealthOverviewScreen({Key? key}) : super(key: key);

  @override
  _HealthOverviewScreenState createState() => _HealthOverviewScreenState();
}

class _HealthOverviewScreenState extends State<HealthOverviewScreen> {
  late Timer _timer;
  int heartRate = 75;
  int oxygenSaturation = 98;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        heartRate = _generateRandomHeartRate();
        oxygenSaturation = _generateRandomOxygenSaturation();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  int _generateRandomHeartRate() {
    final random = Random();
    return 60 + random.nextInt(41);
  }

  int _generateRandomOxygenSaturation() {
    final random = Random();
    return 95 + random.nextInt(6);
  }

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat.yMMMMEEEEd('id').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hi, Salwa!',
                style: TextStyle(
                  fontSize: 40,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Hari ini: ',
                      style: TextStyle(
                        color: Color(0xFF1E7A8F),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                    TextSpan(
                      text: '$currentDate',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'You’re connected with your device',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  color: Color(0xFF1E7A8F),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Navigating back to the ConnectPage
                  Navigator.pop(context);
                },
                child: const SizedBox(
                  height: 25,
                  child: Center(
                    child: Text(
                      'Disconnect Your Device',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB0000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 25),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                height: 2.0,
                color: Color(0xFFE2E5EF),
              ),
              const SizedBox(height: 16),
              const Text(
                'Health Overview',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    HealthCard(
                      title: 'Heart rate',
                      value: heartRate.toString(), // Nilai heart rate
                      unit: 'beats/min',
                      normalRange: 'Normal: 60 to 100 beats/min',
                      imagePath: 'images/heart_background.png',
                    ),
                    const SizedBox(height: 16),
                    HealthCard(
                      title: 'Oxygen Saturation',
                      value: '$oxygenSaturation%', // Nilai oxygen saturation
                      unit: '',
                      normalRange: 'Normal: more than equal to 95%',
                      imagePath: 'images/oxygen_background.png',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HealthAnalyticsPage()),
                  );
                },
                child: const Center(
                  child: Text(
                    'View Health Analytics',
                    style: TextStyle(color: Color(0xFF1E7A8F), fontSize: 18, decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class HealthCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String normalRange;
  final String imagePath;

  const HealthCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.normalRange,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12), // Set padding
      width: 309, // Width of the card
      height: 128, // Height of the card
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover, // Ensures the image covers the background fully
        ),
        borderRadius: BorderRadius.circular(12), // Rounded corners
      ),
      child: Center( // Center the column inside the container
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use the minimum space for the column
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
          children: [
            // Row for Icon and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Align horizontally in the center
              crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical alignment
              children: [
                Image.asset(
                  title == 'Heart rate' ? 'images/1.png' : 'images/2.png',
                  width: 24, // Adjust the size of the image
                  height: 24, // Adjust the size of the image
                ),
                const SizedBox(width: 8), // Space between icon and text
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter', // SemiBold
                  ),
                  overflow: TextOverflow.ellipsis, // Prevent text overflow
                ),
              ],
            ),
            const SizedBox(height: 2), // Space between title and value
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter', // ExtraBold
              ),
            ),
            const SizedBox(height: 1), // Space between value and normal range
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter', // SemiBold
              ),
            ),
            const SizedBox(height: 1),
            Text(
              normalRange,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
                color: Color(0xFF1E7A8F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page Health Analytics
class HealthAnalyticsPage extends StatelessWidget {
  const HealthAnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Analytics'),
        backgroundColor: const Color(0xFF1E7A8F), // Use your desired color
      ),
      body: Center(
        child: const Text(
          'Health Analytics Page',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}