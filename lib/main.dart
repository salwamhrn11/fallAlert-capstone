import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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
      home: const HealthOverviewScreen(),
    );
  }
}

// Page to connect to hardware
class ConnectPage extends StatelessWidget {
  const ConnectPage({Key? key}) : super(key: key);

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
                        color: Colors.grey, // Border color when inactive
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color when active
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
                const SizedBox(height: 16), // Add spacing
                TextField(
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
                        color: Colors.grey, // Border color when inactive
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color when active
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
                const SizedBox(height: 16), // Add spacing
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Action when "Connect" button is pressed
                print("Connecting to server...");
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
                backgroundColor: const Color(0xFF1E7A8F), // Button background color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                minimumSize: const Size(327, 56), // Button size
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Health overview dashboard page
class HealthOverviewScreen extends StatelessWidget {
  final int heartRate;
  final int oxygenSaturation;

  const HealthOverviewScreen({
    Key? key,
    this.heartRate = 70,
    this.oxygenSaturation = 98,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String currentDate = DateFormat.yMMMMEEEEd('id').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hi, Salwa!', style: TextStyle(fontSize: 40, fontFamily: 'Inter', fontWeight: FontWeight.bold, )),
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
                        color: Colors.black, // Warna hitam untuk tanggal
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            Container(
              width: double.infinity, // Panjang garis mengikuti lebar parent
              height: 0.5, // Ketebalan garis
              color: Color(0xE2E5EF)),// Warna garis abu-abu
              const SizedBox(height: 24),
            const Text('Health Overview', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
            const SizedBox(height: 16),
        const Text('You’re connected with your device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal, fontFamily: 'Inter', color: Color(0xFF1E7A8F))),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    HealthCard(
                      title: 'Heart rate',
                      value: heartRate.toString(),
                      unit: 'beats/min',
                      normalRange: 'Normal: 60 to 100 beats/min',
                      imagePath: 'images/heart_background.png',
                    ),
                    const SizedBox(height: 16),
                    HealthCard(
                      title: 'Oxygen Saturation',
                      value: '$oxygenSaturation%',
                      unit: '',
                      normalRange: 'Normal: more than equal to 95%',
                      imagePath: 'images/oxygen_background.png',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'View Health Analytics',
                  style: TextStyle(color: Colors.teal, fontSize: 16, decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 16), // Ensure there is some bottom padding
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
      padding: const EdgeInsets.all(12), // Set padding to 25 pixels
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',// SemiBold
              ),
            ),
            const SizedBox(height: 2), // Space between title and value
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',// ExtraBold
              ),
            ),
            const SizedBox(height: 1), // Space between value and normal range
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',// SemiBold
              ),
            ),
            const SizedBox(height: 1),
            Text(
              normalRange,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                  color: Color(0xFF1E7A8F)
              ),
            ),
          ],
        ),
      ),
    );
  }
}