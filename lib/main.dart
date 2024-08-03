import 'dart:async';

import 'package:flutter/material.dart';
import 'package:live_activities/live_activities.dart';
import 'package:live_activities/models/live_activity_image.dart';
import 'package:live_activities/models/url_scheme_data.dart';
import 'package:live_activities_example/services/libre_service.dart';

import 'models/glucose_live_activity_model.dart';
import 'models/glucose_reading.dart';
import 'widgets/glucose_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late LibreLinkUpConnection _libreConnection;
  List<GlucoseReading> _readings = [];
  bool _isConnecting = false;
  bool _isConnected = false;
  late Timer _timer;

  final _liveActivitiesPlugin = LiveActivities();
  String? _latestActivityId;
  StreamSubscription<UrlSchemeData>? urlSchemeSubscription;
  GlucoseLiveActivityModel? _glucoseLiveActivityModel;

  @override
  void initState() {
    super.initState();

    _libreConnection =
        LibreLinkUpConnection('yassin.z.aa@gmail.com', 'Vub7n2tx768QKN8g2gvM');

    _connectAndFetchReadings();

    _liveActivitiesPlugin.init(
      appGroupId: 'group.diapulse',
    );

    _liveActivitiesPlugin.activityUpdateStream.listen((event) {
      print('Activity update: $event');
    });

    urlSchemeSubscription =
        _liveActivitiesPlugin.urlSchemeStream().listen((schemeData) {
      setState(() {
        if (schemeData.path == '/glucose') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Glucose Reading 📊'),
                content: Text(
                  'Latest glucose reading: ${_readings.isNotEmpty ? _readings.last.value : "N/A"} mg/dL',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        }
      });
    });

    // Set up a timer to fetch readings periodically
    _timer = Timer.periodic(Duration(minutes: 5), (timer) {
      _fetchReadings();
    });
  }

  Future<void> _connectAndFetchReadings() async {
    setState(() {
      _isConnecting = true;
    });

    try {
      await _libreConnection.connectConnection();
      setState(() {
        _isConnected = true;
      });
      await _fetchReadings();
    } catch (e) {
      print('Error connecting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect: $e')),
      );
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _fetchReadings() async {
    if (!_isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Not connected. Please connect first.')),
      );
      return;
    }

    try {
      final readings = await _libreConnection.processFetch();
      setState(() {
        _readings = readings;
      });
      _updateGlucoseLiveActivity();
    } catch (e) {
      print('Error fetching readings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch readings: $e')),
      );
    }
  }

  @override
  void dispose() {
    urlSchemeSubscription?.cancel();
    _liveActivitiesPlugin.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Glucose Live Activities',
          style: TextStyle(
            fontSize: 19,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_latestActivityId != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Card(
                    child: SizedBox(
                      width: double.infinity,
                      height: 120,
                      child: GlucoseWidget(
                        reading: _readings.isNotEmpty ? _readings.last : null,
                      ),
                    ),
                  ),
                ),
              if (_latestActivityId == null)
                TextButton(
                  onPressed: () async {
                    await _startGlucoseLiveActivity();
                  },
                  child: const Column(
                    children: [
                      Text('Start Glucose Monitoring 🩸'),
                      Text(
                        '(start a new live activity)',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_latestActivityId == null)
                TextButton(
                  onPressed: () async {
                    final supported =
                        await _liveActivitiesPlugin.areActivitiesEnabled();
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            content: Text(
                              supported ? 'Supported' : 'Not supported',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: const Text('Is live activities supported ? 🤔'),
                ),
              if (_latestActivityId != null)
                TextButton(
                  onPressed: () {
                    _liveActivitiesPlugin.endAllActivities();
                    _latestActivityId = null;
                    setState(() {});
                  },
                  child: const Column(
                    children: [
                      Text('Stop Monitoring ✋'),
                      Text(
                        '(end all live activities)',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startGlucoseLiveActivity() async {
    if (_readings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No glucose readings available.')),
      );
      return;
    }

    final activityAttributes =
        GlucoseLiveActivityModel.fromReadings(_readings).toMap();

    final activityId =
        await _liveActivitiesPlugin.createActivity(activityAttributes);
    setState(() => _latestActivityId = activityId);
  }

  Future<void> _updateGlucoseLiveActivity() async {
    if (_latestActivityId == null || _readings.isEmpty) {
      return;
    }

    final activityAttributes =
        GlucoseLiveActivityModel.fromReadings(_readings).toMap();

    await _liveActivitiesPlugin.updateActivity(
        _latestActivityId!, activityAttributes);
  }
}
