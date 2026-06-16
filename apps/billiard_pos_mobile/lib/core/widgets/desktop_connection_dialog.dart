import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/providers.dart';
import '../../features/tables/tables_provider.dart';

class DesktopConnectionDialog extends ConsumerStatefulWidget {
  const DesktopConnectionDialog({super.key});

  @override
  ConsumerState<DesktopConnectionDialog> createState() => _DesktopConnectionDialogState();
}

class _DesktopConnectionDialogState extends ConsumerState<DesktopConnectionDialog> {
  final _manualIpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isScanning = false;
  List<String> _discoveredIps = [];
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _manualIpCtrl.text = prefs.getString('desktop_server_ip') ?? '';
    _startScan();
  }

  @override
  void dispose() {
    _manualIpCtrl.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _discoveredIps.clear();
      _statusMessage = 'Đang tìm kiếm Máy tính trong mạng wifi...';
    });

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      final List<String> subnetPrefixes = [];
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          if (ip.startsWith('127.') || ip == '0.0.0.0') continue;
          final parts = ip.split('.');
          if (parts.length == 4) {
            subnetPrefixes.add('${parts[0]}.${parts[1]}.${parts[2]}.');
          }
        }
      }

      final List<String> foundIps = [];
      if (subnetPrefixes.isNotEmpty) {
        final client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1200);

        for (final subnet in subnetPrefixes) {
          // Scan in chunks of 50 in parallel to prevent socket exhaustion and packet loss
          const chunkSize = 50;
          for (int chunkStart = 1; chunkStart < 255; chunkStart += chunkSize) {
            final chunkEnd = (chunkStart + chunkSize < 255) ? chunkStart + chunkSize : 255;
            final List<Future<void>> chunkScans = [];

            for (int i = chunkStart; i < chunkEnd; i++) {
              final targetIp = '$subnet$i';
              chunkScans.add(() async {
                try {
                  final request = await client.getUrl(Uri.parse('http://$targetIp:8085/api/ping'));
                  final response = await request.close();
                  if (response.statusCode == 200) {
                    final body = await response.transform(utf8.decoder).join();
                    final data = jsonDecode(body) as Map<String, dynamic>;
                    if (data['app'] == 'billiard_pos') {
                      foundIps.add(targetIp);
                    }
                  }
                } catch (_) {
                  // Ignore timeouts and socket exceptions
                }
              }());
            }
            await Future.wait(chunkScans);
          }
        }
      }

      if (mounted) {
        setState(() {
          _isScanning = false;
          _discoveredIps = foundIps;
          _statusMessage = foundIps.isEmpty 
              ? 'Không tìm thấy máy tính tự động. Vui lòng nhập IP thủ công.' 
              : 'Đã tìm thấy ${foundIps.length} máy tính.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Lỗi tìm kiếm: $e';
        });
      }
    }
  }


  Future<void> _connect(String ip) async {
    setState(() {
      _isScanning = true;
      _statusMessage = 'Đang kết nối đến $ip...';
    });

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final request = await client.getUrl(Uri.parse('http://$ip:8085/api/ping'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        
        if (data['app'] == 'billiard_pos') {
          final prefs = ref.read(sharedPreferencesProvider);
          await prefs.setString('desktop_server_ip', ip);
          
          if (mounted) {
            setState(() {
              _isScanning = false;
              _isSuccess = true;
              _statusMessage = 'Kết nối thành công!';
            });
            
            // Reload tables provider to pull desktop state immediately
            ref.read(tablesProvider.notifier).loadTables();
            
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) Navigator.pop(context);
            });
          }
          return;
        }
      }
      throw Exception('Thiết bị không phản hồi đúng giao thức.');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = 'Kết nối thất bại: $e';
        });
      }
    }
  }

  Future<void> _disconnect() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('desktop_server_ip');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ngắt kết nối và quay lại chế độ Cloud')),
      );
      Navigator.pop(context);
    }
    
    // Reload tables to restore normal local/cloud state
    ref.read(tablesProvider.notifier).loadTables();
  }

  @override
  Widget build(BuildContext context) {
    final currentIp = ref.read(sharedPreferencesProvider).getString('desktop_server_ip') ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.wifi_tethering, color: Colors.blue),
          const SizedBox(width: 10),
          const Text('Kết nối máy tính'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (currentIp.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Đang kết nối đến: $currentIp',
                          style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: _disconnect,
                        child: const Text('Ngắt', style: TextStyle(color: Colors.red)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              const Text(
                'Danh sách máy tính tìm thấy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              if (_isScanning && _discoveredIps.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_discoveredIps.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: const Text('Không tìm thấy thiết bị nào trong mạng.', style: TextStyle(color: Colors.black38)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _discoveredIps.length,
                  itemBuilder: (ctx, index) {
                    final ip = _discoveredIps[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.computer, color: Colors.blue),
                        title: Text('Billiard Desktop Server'),
                        subtitle: Text(ip),
                        trailing: ElevatedButton(
                          onPressed: () => _connect(ip),
                          child: const Text('Kết nối'),
                        ),
                      ),
                    );
                  },
                ),
              
              const Divider(height: 24),
              
              Form(
                key: _formKey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _manualIpCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Địa chỉ IP thủ công',
                          hintText: 'Ví dụ: 192.168.1.15',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập IP' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _connect(_manualIpCtrl.text.trim());
                        }
                      },
                      child: const Text('Kết nối'),
                    )
                  ],
                ),
              ),
              
              if (_statusMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green : Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isScanning ? null : _startScan,
          child: const Text('Quét lại'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
