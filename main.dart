import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'dart:async';

void main() {
  runApp(const LinNetApp());
}

class LinNetApp extends StatelessWidget {
  const LinNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LinNet',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LinNetHomePage(),
    );
  }
}

class LinNetHomePage extends StatefulWidget {
  const LinNetHomePage({super.key});

  @override
  State<LinNetHomePage> createState() => _LinNetHomePageState();
}

class _LinNetHomePageState extends State<LinNetHomePage> {
  String localIp = "جاري الكشف عن الآي بي...";
  String gatewayIp = "";
  List<String> connectedDevices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();
    _detectNetworkAutomatically();
  }

  // دالة ذكية لاكتشاف الآي بي والـ Gateway أوتوماتيكياً مهما كان الرينج
  Future<void> _detectNetworkAutomatically() async {
    try {
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            String ip = addr.address;
            int lastDot = ip.lastIndexOf('.');
            if (lastDot != -1) {
              String detectedGateway = '${ip.substring(0, lastDot)}.1';
              setState(() {
                localIp = ip;
                gatewayIp = detectedGateway;
              });
              return;
            }
          }
        }
      }
      setState(() {
        localIp = "تعرّف تلقائي متعذر";
        gatewayIp = "192.168.1.1";
      });
    } catch (e) {
      setState(() {
        localIp = "خطأ في الاتصال";
        gatewayIp = "192.168.1.1";
      });
    }
  }

  // فحص الأجهزة أوتوماتيكياً على نفس الرينج المكتشف
  Future<void> _scanNetworkDevices() async {
    if (gatewayIp.isEmpty) return;

    setState(() {
      isScanning = true;
      connectedDevices.clear();
    });

    String subnet = gatewayIp.substring(0, gatewayIp.lastIndexOf('.'));
    
    for (int i = 1; i < 255; i++) {
      String testIp = '$subnet.$i';
      try {
        final socket = await Socket.connect(testIp, 80, timeout: const Duration(milliseconds: 120))
            .catchError((_) => null as Socket);
        if (socket != null) {
          socket.destroy();
          setState(() {
            connectedDevices.add(testIp);
          });
        }
      } catch (_) {}
    }

    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LinNet - إدارة الشبكة الذكية'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الشعار مع التوقيع المطلوب
            Center(
              child: Column(
                children: const [
                  Icon(Icons.router, size: 50, color: Colors.blue),
                  SizedBox(height: 4),
                  Text(
                    'LinNet',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'by mamdoh',
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // عرض البيانات المكتشفة أوتوماتيكياً
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('آي بي الجهاز: $localIp', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('الراوتر المكتشف أوتوماتيكياً: $gatewayIp', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isScanning ? null : _scanNetworkDevices,
                        child: isScanning
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('فحص الأجهزة أوتوماتيكياً'),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            const Text('الأجهزة النشطة على الشبكة:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Expanded(
              child: connectedDevices.isEmpty
                  ? Center(
                      child: Text(
                        isScanning ? 'جاري الفحص التلقائي للشبكة...' : 'اضغط على "فحص الأجهزة أوتوماتيكياً"',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: connectedDevices.length,
                      itemBuilder: (context, index) {
                        String deviceIp = connectedDevices[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.devices, color: Colors.blue),
                            title: Text('جهاز: $deviceIp'),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LinNetBrowserScreen(
                                      url: 'http://$gatewayIp',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('حظر', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 10),

            // زر فتح صفحة الراوتر المكتشف
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LinNetBrowserScreen(url: 'http://$gatewayIp'),
                  ),
                );
              },
              icon: const Icon(Icons.lock_reset, color: Colors.white),
              label: const Text('فتح صفحة الراوتر (إدارة الشبكة)', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// المتصفح المدمج
class LinNetBrowserScreen extends StatelessWidget {
  final String url;
  const LinNetBrowserScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browser LinNet')),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
