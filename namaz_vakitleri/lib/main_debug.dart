import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/providers/app_settings.dart';
import 'lib/providers/prayer_provider.dart';
import 'lib/screens/home_screen.dart';
import 'lib/config/color_system.dart';
import 'lib/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 App starting...');
  
  // Initialize timezone
  tz.initializeTimeZones();
  print('✅ Timezone initialized');
  
  // Initialize notifications
  await NotificationService.initialize();
  print('✅ Notifications initialized');
  
  runApp(const DebugApp());
}

class DebugApp extends StatefulWidget {
  const DebugApp({Key? key}) : super(key: key);

  @override
  State<DebugApp> createState() => _DebugAppState();
}

class _DebugAppState extends State<DebugApp> {
  late AppSettings _appSettings;
  late PrayerProvider _prayerProvider;
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _appSettings = AppSettings();
    _prayerProvider = PrayerProvider();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('📱 Initializing app...');
      _updateDebug('Initializing AppSettings...');
      await _appSettings.initialize();
      print('✅ AppSettings initialized');
      _updateDebug('AppSettings initialized');
      
      print('📱 Initializing PrayerProvider...');
      _updateDebug('Initializing PrayerProvider...');
      await _prayerProvider.initialize();
      print('✅ PrayerProvider initialized');
      _updateDebug('PrayerProvider initialized');
    } catch (e, stacktrace) {
      print('❌ Error initializing app: $e');
      print(stacktrace);
      _updateDebug('Error: $e');
    }
  }

  void _updateDebug(String message) {
    setState(() {
      _debugInfo += '\n$message';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppSettings>.value(value: _appSettings),
        ChangeNotifierProvider<PrayerProvider>.value(value: _prayerProvider),
      ],
      child: MaterialApp(
        title: 'Prayer Times - Debug',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: AppColors.lightBg,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: AppColors.darkBg,
        ),
        home: DebugHomeScreen(debugInfo: _debugInfo),
        debugShowCheckedModeBanner: true,
      ),
    );
  }
}

class DebugHomeScreen extends StatelessWidget {
  final String debugInfo;

  const DebugHomeScreen({
    Key? key,
    required this.debugInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, prayerProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Initialization Debug Info:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(debugInfo.isEmpty ? 'Initializing...' : debugInfo),
                ),
                const SizedBox(height: 24),
                Text(
                  'Prayer Provider Status:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Is Loading: ${prayerProvider.isLoading}'),
                Text('Error Message: ${prayerProvider.errorMessage}'),
                Text('Current Location: ${prayerProvider.currentLocation?.city ?? "None"}'),
                Text('Saved City: ${prayerProvider.savedCity}'),
                Text('Prayer Times: ${prayerProvider.currentPrayerTimes != null ? "Loaded" : "Null"}'),
                Text(
                  'Prayer Count: ${prayerProvider.currentPrayerTimes?.prayerTimesList.length ?? 0}',
                ),
                Text('Next Prayer: ${prayerProvider.nextPrayer?.name ?? "None"}'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    print('🔄 Fetching prayer times manually...');
                    prayerProvider.fetchPrayerTimes();
                  },
                  child: const Text('Retry Prayer Times'),
                ),
                const SizedBox(height: 24),
                if (prayerProvider.currentPrayerTimes != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prayer Times List:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ...prayerProvider.currentPrayerTimes!.prayerTimesList
                          .map(
                            (prayer) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${prayer.name}: ${prayer.time.hour}:${prayer.time.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
