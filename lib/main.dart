import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String defaultUrl1 = 'https://pandang.istanapresiden.go.id/';
const String defaultUrl2 = 'https://pointblank.id/';

class WebsiteStatus {
  int count;
  String url;
  String status;

  WebsiteStatus({
    required this.count,
    required this.url,
    required this.status,
  });
}

class HttpChecker extends StatefulWidget {
  @override
  _HttpCheckerState createState() => _HttpCheckerState();
}

class _HttpCheckerState extends State<HttpChecker> {
  final List<WebsiteStatus> websiteStatusList = [];
  int count = 0;
  bool isChecking = false;
  Timer? timer;
  final TextEditingController urlController = TextEditingController();
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid = const AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: null,
    );
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> onSelectNotification(String? payload) async {
    // Action to be taken when the notification is clicked (optional)
  }

  Future<void> showNotification(String title, String body, int count) async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: null,
    );
    await flutterLocalNotificationsPlugin.show(
      count,
      title,
      '$body (Count - $count )',
      platformChannelSpecifics,
    );
  }

  void _setDefaultUrl(String defaultUrl) {
    urlController.text = defaultUrl;
  }

  Future<void> checkWebsiteStatus() async {
    final String url = urlController.text.trim();

    setState(() {
      isChecking = true;
      count++;
    });

    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 3),
          );
      print(response.statusCode);
      if (response.statusCode == 200) {
        websiteStatusList.add(
          WebsiteStatus(count: count, url: url, status: 'Website Hidup'),
        );

        if (isNotificationEnabled) {
          showNotification('Status', 'Hidup: $url', count);
        }
      } else {
        websiteStatusList.add(
          WebsiteStatus(count: count, url: url, status: 'Website Down'),
        );
      }
    } catch (e) {
      websiteStatusList.add(
        WebsiteStatus(count: count, url: url, status: 'Website Down'),
      );
    } finally {
      setState(() {
        isChecking = false;
      });
    }

    if (count % 50 == 0) {
      stopChecking();
      await Future.delayed(const Duration(seconds: 5));
      startChecking();
    }

    if (websiteStatusList.length > 5) {
      websiteStatusList.removeRange(0, websiteStatusList.length - 5);
    }
  }

  void startChecking() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
      timer = null;
    }

    timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        checkWebsiteStatus();
      },
    );
  }

  void stopChecking() {
    if (timer != null && timer!.isActive) {
      timer!.cancel();
      timer = null;
    }
    setState(() {
      websiteStatusList.clear();
      isChecking = false;
      count = 0;
    });
  }

  @override
  void dispose() {
    stopChecking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Checker'),
        actions: [
          Switch(
            value: isNotificationEnabled,
            onChanged: (value) {
              setState(() {
                isNotificationEnabled = value;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _setDefaultUrl(defaultUrl1),
                  child: const Text('Default URL 1'),
                ),
                ElevatedButton(
                  onPressed: () => _setDefaultUrl(defaultUrl2),
                  child: const Text('Default URL 2'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Enter URL',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isChecking ? null : startChecking,
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow), // Add play icon
                      const SizedBox(
                          width: 4), // Add spacing between icon and text
                      const Text('Check'),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: isChecking || websiteStatusList.isEmpty
                      ? null
                      : stopChecking,
                  child: Row(
                    children: [
                      Icon(Icons.stop), // Add stop icon
                      const SizedBox(
                          width: 4), // Add spacing between icon and text
                      const Text('Stop'),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: websiteStatusList.isNotEmpty
                  ? ListView.builder(
                      itemCount: websiteStatusList.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        final status = websiteStatusList[index];
                        return Card(
                          elevation: 2.0,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: status.status == 'Website Hidup'
                                  ? Colors
                                      .green // Change CircleAvatar background color if website is up
                                  : Colors
                                      .red, // Change CircleAvatar background color if website is down
                              child: Text(
                                '${status.count}',
                                style: const TextStyle(
                                  color: Colors
                                      .white, // Change CircleAvatar text color
                                ),
                              ),
                            ),
                            title: Text(
                              status.url,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              status.status,
                              style: TextStyle(
                                color: status.status == 'Website Hidup'
                                    ? Colors
                                        .green // Change status text color if website is up
                                    : Colors
                                        .red, // Change status text color if website is down
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        'Tidak ada status website',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HttpChecker(),
      theme: ThemeData(
        primarySwatch: Colors.green,
      )));
}
