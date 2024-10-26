import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
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

class MQTTService {
  MqttServerClient? client;
  String broker = 'test.mosquitto.org'; // Use your broker's address
  String clientId = 'capstone';
  String topic = 'fall-detection/readings/1234'; // Use your topic
  String debugTopic = 'fall-detection/readings/1234/debug'; 
  int port = 1883;
  // ValueNotifier<bool> isFall = ValueNotifier<bool>(true); 

  // Timer for tracking new messages
  Timer? _messageTimer;
  final int messageTimeout = 30; // Time in seconds to wait for new messages

  // Add a reference to flutter_local_notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Request notification permission
  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ specific permission request
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        bool? granted = await androidImplementation.requestNotificationsPermission();
        if (granted == true) {
          print('Notification permission granted');
        } else {
          print('Notification permission denied');
        }
      }
    }
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Ensure this icon exists

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> connect(BuildContext context) async {
    await _requestNotificationPermission();
    await _initializeNotifications();

    client = MqttServerClient.withPort(broker, clientId, port);

    client!.logging(on: true); // Enable logging
    client!.keepAlivePeriod = 60; // Set the keep-alive period for the connection
    client!.onDisconnected = onDisconnected;
    client!.onConnected = onConnected;
    client!.onSubscribed = onSubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .startClean() // Start a clean session
        .withWillQos(MqttQos.atLeastOnce);
    client!.connectionMessage = connMess;

    try {
      print('Connecting to broker...');
      await client!.connect();
    } catch (e) {
      print('Connection failed: $e');
      client!.disconnect();
    }

    // Check the connection status
    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('Connected to the broker!');
    } else {
      print('Connection failed. Status: ${client!.connectionStatus!.state}');
      client!.disconnect();
    }

    // Subscribe to a topic
    client!.subscribe(topic, MqttQos.atLeastOnce);
    print('Subscribed to $topic');

    _startMessageTimer(context); // Start the timer

    // Listen for incoming messages
    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> messages) {
      final MqttPublishMessage recMess = messages[0].payload as MqttPublishMessage;
      final String message = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      // print('Received message: $message from topic: ${messages[0].topic}');
      _handleMessage(message, context); // Handle the boolean message
      _resetMessageTimer(context); // Reset timer
    });
  }

  void onDisconnected() {
    print('Disconnected from the broker');
  }

  void onConnected() {
    print('Connected to the broker');
  }

  void onSubscribed(String topic) {
    print('Subscribed to $topic');
  }

  void disconnect() {
    client!.disconnect();
  }

  void _handleMessage(String message, BuildContext context) {
    try {
      // Parse the JSON string into a Dart Map
      var data = jsonDecode(message);
      var isFall = data['fall']; // Assuming 0 = no fall, 1 = fall detected
      print('Fall status: ${isFall == 1 ? "Fall detected" : "No fall"}');

      // Check for fall detection
      if (isFall == 1) {
        _showPopup(context); // Show the popup when a fall is detected
        _showNotification(); // Show a notification
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

   void _showPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Alert"),
          content: Text("Your beloved person is fallen!"),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to show notification
  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channel_id', 'Channel Name',
            importance: Importance.max, priority: Priority.high, showWhen: false);
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Fall Alert',
      'Your beloved person is fallen!',
      platformChannelSpecifics,
    );
  }

  // Start the timer to monitor for new messages
  void _startMessageTimer(BuildContext context) {
    _messageTimer = Timer(Duration(seconds: messageTimeout), () {
      // No message was received within the timeout period, publish to a new topic
      publishMessage(debugTopic, '{"alert": "No new data received"}');
      print('No new message received in $messageTimeout seconds. Alert message published.');
    });
  }

  // Reset the message timer when a new message is received
  void _resetMessageTimer(BuildContext context) {
    _messageTimer?.cancel(); // Cancel the previous timer
    _startMessageTimer(context); // Start a new timer
  }

  // Publish a message to a new topic
  void publishMessage(String topic, String message) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    
    client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    print('Message published to $topic: $message');
  }
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
  final MQTTService _mqttService = MQTTService();

  @override
  void initState() {
    super.initState();
    _mqttService.connect(context);
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
    return 58 + Random().nextInt(64);
  }

  int _generateRandomOxygenSaturation() {
    return 94 + Random().nextInt(6);
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
  bool historyState = false;
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
    _dbRef.child('healthOverview').limitToLast(100).onChildAdded.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> value = event.snapshot.value as Map<dynamic, dynamic>;

        double heartRate = double.tryParse(value['heart_rate'].toString()) ?? 0;
        double oxygenSaturation = double.tryParse(value['oxygen_saturation'].toString()) ?? 0;

        DateTime? timestamp = DateTime.tryParse(event.snapshot.key ?? '') ?? DateTime.now();
        double xValue = _indexCounter.toDouble(); // Convert index to double for chart
        _indexCounter++; // Increment index

        setState(() {
          heartRateData.add(FlSpot(xValue, heartRate));
          oxygenSaturationData.add(FlSpot(xValue, oxygenSaturation));
          timeLabels.add(DateFormat.Hms().format(timestamp));
        });
      }
    });
  }

  List<FlSpot> getDataForRange(int range, List<FlSpot> data) {
    // Only display a fixed window of 50 data points, but allow scrolling
    return data.length > range ? data.sublist(data.length - range) : data;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildHistoryButton()],
            ),
          const SizedBox(height: 16),
          // Conditional rendering based on historyState
          historyState == false
              ? Column(
                  children: [
                    _buildDataSection('Heart Rate Analytics', heartRateData, Colors.red),
                    const SizedBox(height: 16),
                    _buildDataSection('Oxygen Saturation Analytics', oxygenSaturationData, Colors.blue),
                  ],
                )
              : _buildHistoryStats(), // Show history stats when historyState is true
        ],
        ),
      ),
    );
  }

  Widget _buildHistoryStats() {
    List<Map<String, dynamic>> lowOxySaturation = _getLowOxygenSaturationAnomalies();
    List<Map<String, dynamic>> highHeartRate = _getHighHeartRateAnomalies();
    List<Map<String, dynamic>> lowHeartRate = _getLowHeartRateAnomalies();
    int abnormalHighHeartRateCount = highHeartRate.length;
    int abnormalLowHeartRateCount = lowHeartRate.length;
    int abnormalOxygenSaturationCount = lowOxySaturation.length;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showAnomalyDialog("High Heart Rate Alerts", highHeartRate),
          child: _buildStatCard(
            'High Heart Rate Alerts',
            'Heart rate > 120',
            abnormalHighHeartRateCount,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showAnomalyDialog("Low Heart Rate Alerts", lowHeartRate),
          child: _buildStatCard(
            'Low Heart Rate Alerts',
            'Heart rate < 60',
            abnormalLowHeartRateCount,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _showAnomalyDialog("Low Oxygen Saturation Alerts", lowOxySaturation),
          child: _buildStatCard(
            'Low Oxygen Saturation Alerts',
            'Oxygen saturation < 95%',
            abnormalOxygenSaturationCount,
          ),
        ),
      ],
    );
  }

  // Method to show the pop-up Detail
  void _showAnomalyDialog(String title, List<Map<String, dynamic>> anomalies) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: anomalies.length,
              itemBuilder: (context, index) {
                final anomaly = anomalies[index];
                return ListTile(
                  title: Text('Value: ${anomaly['value']}'),
                  subtitle: Text('Datetime: ${anomaly['timestamp']}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String subtitle, int count) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 8),
          Text(
            'Count: $count',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getHighHeartRateAnomalies() {
    DateTime now = DateTime.now();
    return heartRateData
        .asMap()
        .entries
        .where((entry) =>
            entry.value.y > 120)
        .map((entry) => {
              'timestamp': timeLabels[entry.key],
              'value': entry.value.y,
            })
        .toList();
  }

  List<Map<String, dynamic>> _getLowHeartRateAnomalies() {
    return heartRateData
        .asMap()
        .entries
        .where((entry) =>
            entry.value.y < 60)
        .map((entry) => {
              'timestamp': timeLabels[entry.key],
              'value': entry.value.y,
            })
        .toList();
  }

  List<Map<String, dynamic>> _getLowOxygenSaturationAnomalies() {
    DateTime now = DateTime.now();
    return oxygenSaturationData
        .asMap()
        .entries
        .where((entry) =>
            entry.value.y < 95)
        .map((entry) => {
              'timestamp': timeLabels[entry.key],
              'value': entry.value.y,
            })
        .toList();
  }


  Widget _buildDataSection(String title, List<FlSpot> data, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal, // Enable horizontal scrolling
            child: SizedBox(
              width: 327, // Dynamically calculate width based on data length
              child: LineChart(
                _buildLineChartData(data, color),
              ),
            ),
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(List<FlSpot> data, Color color) {
    return LineChartData(
      minY: _getMinValue(data) - 10,
      maxY: _getMaxValue(data) + 10,
      lineBarsData: [
        LineChartBarData(
          spots: getDataForRange(30, data),
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
              if (index < timeLabels.length) {
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

  Widget _buildHistoryButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          historyState = !historyState;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: historyState == true ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "History",
          style: TextStyle(
            fontSize: 16,
            color: historyState == true ? Colors.white : Colors.black,
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