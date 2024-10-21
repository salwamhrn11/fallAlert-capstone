import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the date formatting for the 'id' locale (Indonesian)
  await initializeDateFormatting('id', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  // Run the app after initialization
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const ConnectPage({super.key});

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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E7A8F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                minimumSize: const Size(327, 56),
              ),
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
  const HealthOverviewScreen({super.key});

  @override
  _HealthOverviewScreenState createState() => _HealthOverviewScreenState();
}


class _HealthOverviewScreenState extends State<HealthOverviewScreen> {
  late Timer _timer;
  int heartRate = 75;
  int oxygenSaturation = 98;

  // Reference to the Firebase database
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        heartRate = _generateRandomHeartRate();
        oxygenSaturation = _generateRandomOxygenSaturation();
      });
      // Push the data to Firebase
      _pushHealthData(heartRate, oxygenSaturation);
    });
  }


  // Function to push data to Firebase
  void _pushHealthData(int heartRate, int oxygenSaturation) {
    // Define the structure of the data
    Map<String, dynamic> healthData = {
      'heart_rate': heartRate,
      'oxygen_saturation': oxygenSaturation,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Push the data to Firebase under "healthOverview" node
    _dbRef.child('healthOverview').push().set(healthData).then((_) {
      print("Data saved successfully!");
    }).catchError((error) {
      print("Failed to save data: $error");
    });
  }

  @override
  void dispose() {
    // Ensure timer is canceled when the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  int _generateRandomHeartRate() {
    return 60 + Random().nextInt(41);
  }

  int _generateRandomOxygenSaturation() {
    return 95 + Random().nextInt(6);
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
                    const TextSpan(
                      text: 'Hari ini: ',
                      style: TextStyle(
                        color: Color(0xFF1E7A8F),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                    TextSpan(
                      text: currentDate,
                      style: const TextStyle(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBB0000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(double.infinity, 25),
                ),
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
              ),
              const SizedBox(height: 10),
              Divider(color: const Color(0xFFE2E5EF), thickness: 2),
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
                    MaterialPageRoute(builder: (context) => HealthAnalyticsPage()),
                  );
                },
                child: const Center(
                  child: Text(
                    'View Health Analytics',
                    style: TextStyle(
                      color: Color(0xFF1E7A8F),
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
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
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.normalRange,
    required this.imagePath,
  });

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

// Health Analytics Page
//kode perdetik tp masih patah2 + blm 5 detik
class HealthAnalyticsPage extends StatefulWidget {
  const HealthAnalyticsPage({super.key});

  @override
  _HealthAnalyticsPageState createState() => _HealthAnalyticsPageState();
}

class _HealthAnalyticsPageState extends State<HealthAnalyticsPage> {
  String selectedRange = 'Second';
  List<FlSpot> heartRateData = [];
  List<FlSpot> oxygenSaturationData = [];
  List<String> timeLabels = [];

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  int _indexCounter = 0; // Auto-increment index for X

  @override
  void initState() {
    super.initState();
    _fetchDataFromFirebase();
  }

  void _fetchDataFromFirebase() {
    _dbRef.child('healthOverview').limitToLast(20).onChildAdded.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> value = event.snapshot.value as Map<dynamic, dynamic>;

        double heartRate = double.tryParse(value['heart_rate'].toString()) ?? 0;
        double oxygenSaturation = double.tryParse(value['oxygen_saturation'].toString()) ?? 0;

        // Ambil timestamp atau gunakan index counter
        DateTime? timestamp = DateTime.tryParse(event.snapshot.key ?? '') ?? DateTime.now();
        double xValue = _indexCounter.toDouble(); // Konversi ke double
        _indexCounter++; // Increment counter

        setState(() {
          heartRateData.add(FlSpot(xValue, heartRate));
          oxygenSaturationData.add(FlSpot(xValue, oxygenSaturation));
          timeLabels.add(DateFormat.Hms().format(timestamp));
        });
      }
    });
  }

  List<FlSpot> getDataForRange(String range, List<FlSpot> data) {
    int limit = 20;
    return data.length > limit ? data.sublist(data.length - limit) : data;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Analytics',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildRangeButton('Second')],
            ),
            const SizedBox(height: 16),
            const Text(
              'Heart Rate Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                _buildLineChartData(heartRateData, Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oxygen Saturation Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(
              height: 200,
              child: LineChart(
                _buildLineChartData(oxygenSaturationData, Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildLineChartData(List<FlSpot> data, Color color) {
    return LineChartData(
      minY: _getMinValue(data) - 10,
      maxY: _getMaxValue(data) + 10,
      lineBarsData: [
        LineChartBarData(
          spots: getDataForRange(selectedRange, data),
          isCurved: true,
          color: color,
          belowBarData: BarAreaData(show: false),
          dotData: FlDotData(show: false),
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: 5, // Adjust interval for X-axis
            getTitlesWidget: (value, _) {
              int index = value.toInt();
              if (index % 5 == 0 && index < timeLabels.length) {
                return Text(
                  timeLabels[index],
                  style: const TextStyle(fontSize: 8),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRangeButton(String range) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRange = range;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedRange == range ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          range,
          style: TextStyle(
            fontSize: 16,
            color: selectedRange == range ? Colors.white : Colors.black,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  double _getMinValue(List<FlSpot> data) =>
      data.isEmpty ? 0 : data.map((e) => e.y).reduce((a, b) => a < b ? a : b);

  double _getMaxValue(List<FlSpot> data) =>
      data.isEmpty ? 100 : data.map((e) => e.y).reduce((a, b) => a > b ? a : b);
}