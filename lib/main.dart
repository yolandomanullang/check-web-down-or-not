import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class WebsiteStatus {
  int count;
  String url;
  String status;

  WebsiteStatus({required this.count, required this.url, required this.status});
}

class HttpChecker extends StatefulWidget {
  @override
  _HttpCheckerState createState() => _HttpCheckerState();
}

class _HttpCheckerState extends State<HttpChecker> {
  List<WebsiteStatus> websiteStatusList = [];
  int count = 0;
  bool isChecking = false;
  Timer? timer;
  TextEditingController urlController = TextEditingController();
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool isNotificationEnabled = false;

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: null);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future onSelectNotification(String? payload) async {
    // Tindakan yang akan diambil ketika notifikasi diklik (opsional)
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
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() {
          websiteStatusList.add(
              WebsiteStatus(count: count, url: url, status: 'Website Hidup'));
        });

        if (isNotificationEnabled) {
          showNotification('Status', 'Hidup: $url', count);
        }
      } else {
        setState(() {
          websiteStatusList.add(
              WebsiteStatus(count: count, url: url, status: 'Website Down'));
        });
      }
    } catch (e) {
      setState(() {
        websiteStatusList
            .add(WebsiteStatus(count: count, url: url, status: 'Website Down'));
      });
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

    timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      checkWebsiteStatus();
    });
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
                  onPressed: () {
                    _setDefaultUrl('https://pandang.istanapresiden.go.id/');
                  },
                  child: const Text('Default URL 1'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _setDefaultUrl('https://pointblank.id/');
                  },
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
                  onPressed: isChecking ? null : () => startChecking(),
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow), // Tambahkan ikon play
                      const SizedBox(
                          width: 4), // Tambahkan jarak antara ikon dan teks
                      const Text('Check'),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton(
                  onPressed: isChecking || websiteStatusList.isEmpty
                      ? null
                      : () => stopChecking(),
                  child: Row(
                    children: [
                      Icon(Icons.stop), // Tambahkan ikon stop
                      const SizedBox(
                          width: 4), // Tambahkan jarak antara ikon dan teks
                      const Text('Stop'),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                      .green // Ubah warna latar belakang CircleAvatar jika website hidup
                                  : Colors
                                      .red, // Ubah warna latar belakang CircleAvatar jika website down
                              child: Text(
                                '${status.count}',
                                style: TextStyle(
                                  color: Colors
                                      .white, // Ubah warna teks CircleAvatar
                                ),
                              ),
                            ),
                            title: Text(
                              status.url,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              status.status,
                              style: TextStyle(
                                color: status.status == 'Website Hidup'
                                    ? Colors
                                        .green // Ubah warna teks status jika website hidup
                                    : Colors
                                        .red, // Ubah warna teks status jika website down
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
  ));
}
