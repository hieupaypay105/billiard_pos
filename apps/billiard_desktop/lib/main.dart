import 'dart:async';
import 'package:flutter/material.dart';
import 'package:core_shared/core_shared.dart';
import 'package:iot_controller/iot_controller.dart';

void main() {
  runApp(const BilliardDesktopApp());
}

class BilliardDesktopApp extends StatelessWidget {
  const BilliardDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Billiard POS & IoT Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E4F4F),
          background: const Color(0xFFF8F9FA),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock Data lists representing tables and their configs
  late List<TableModel> _tables;
  late Map<String, IotConfigModel> _iotConfigs;
  late Map<String, double> _hourlyRates; // map of tableTypeId to hourly rate
  
  // Active IoT Controller map to maintain connections for active tables
  final Map<String, BilliardIoTController> _activeControllers = {};
  
  // Selected table ID for detail pane
  String? _selectedTableId;
  
  // Console logs specific to the selected table or general
  final List<String> _consoleLogs = [];
  final ScrollController _consoleScrollController = ScrollController();
  
  // Global timer to update playtime display every second
  Timer? _ticker;
  
  // Simulated settings
  bool _useRealController = false;

  // Track active table start times locally for real-time calculations
  final Map<String, DateTime> _tableStartTimes = {};
  
  // Track mock ordered products per active table for invoicing
  final Map<String, List<Map<String, dynamic>>> _tableMockOrders = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    for (final controller in _activeControllers.values) {
      controller.disconnect();
    }
    _consoleScrollController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // 3 Table Types
    // 1: Pool (Bàn lỗ), 2: Carom (Bàn phăng), 3: Snooker
    _hourlyRates = {
      '1': 80000.0,
      '2': 90000.0,
      '3': 120000.0,
    };

    // Initialize 6 tables
    _tables = [
      const TableModel(id: 't-1', tableName: 'Bàn 01 (Pool)', areaId: 1, tableTypeId: 1, status: 'idle'),
      const TableModel(id: 't-2', tableName: 'Bàn 02 (Pool)', areaId: 1, tableTypeId: 1, status: 'idle'),
      const TableModel(id: 't-3', tableName: 'Bàn 03 (Pool)', areaId: 1, tableTypeId: 1, status: 'idle'),
      const TableModel(id: 't-4', tableName: 'Bàn 04 (Carom)', areaId: 2, tableTypeId: 2, status: 'idle'),
      const TableModel(id: 't-5', tableName: 'Bàn 05 (Carom)', areaId: 2, tableTypeId: 2, status: 'idle'),
      const TableModel(id: 't-6', tableName: 'Bàn 06 (Snooker)', areaId: 3, tableTypeId: 3, status: 'idle'),
    ];

    // Initialize IoT configs mapped by table ID
    _iotConfigs = {
      't-1': const IotConfigModel(id: 1, tableId: 't-1', connectionType: 'serial', port: 'COM1', relayChannel: 1, commandOn: '01050000FF008C3A', commandOff: '010500000000CDCA'),
      't-2': const IotConfigModel(id: 2, tableId: 't-2', connectionType: 'serial', port: 'COM2', relayChannel: 2, commandOn: '01050001FF00DDFA', commandOff: '0105000100009C0A'),
      't-3': const IotConfigModel(id: 3, tableId: 't-3', connectionType: 'serial', port: 'COM3', relayChannel: 3, commandOn: '01050002FF002DFA', commandOff: '0105000200006C0A'),
      't-4': const IotConfigModel(id: 4, tableId: 't-4', connectionType: 'tcp_ip', ipAddress: '192.168.1.150', port: '8080', relayChannel: 1, commandOn: '01050000FF008C3A', commandOff: '010500000000CDCA'),
      't-5': const IotConfigModel(id: 5, tableId: 't-5', connectionType: 'tcp_ip', ipAddress: '192.168.1.150', port: '8080', relayChannel: 2, commandOn: '01050001FF00DDFA', commandOff: '0105000100009C0A'),
      't-6': const IotConfigModel(id: 6, tableId: 't-6', connectionType: 'tcp_ip', ipAddress: '192.168.1.160', port: '9000', relayChannel: 1, commandOn: '01050000FF008C3A', commandOff: '010500000000CDCA'),
    };

    _selectedTableId = _tables.first.id;
    _logGeneral('System initialized. Mode: ${_useRealController ? "Real Hardware Sockets" : "Simulation Enabled"}');
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); // redraw to update ticking active timers
      }
    });
  }

  void _logGeneral(String msg) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    setState(() {
      _consoleLogs.add('[$timestamp] [System] $msg');
    });
    _scrollToConsoleBottom();
  }

  void _scrollToConsoleBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.animateTo(
          _consoleScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Action: Select table
  void _selectTable(String tableId) {
    setState(() {
      _selectedTableId = tableId;
    });
    _logGeneral('Switched focus to ${getNameOfTable(tableId)}');
  }

  String getNameOfTable(String id) {
    return _tables.firstWhere((t) => t.id == id).tableName;
  }

  // Get current active duration of a table
  Duration _getTablePlayDuration(String tableId) {
    final startTime = _tableStartTimes[tableId];
    if (startTime == null) return Duration.zero;
    return DateTime.now().difference(startTime);
  }

  // Get current play cost calculation
  double _calculatePlayCost(String tableId) {
    final table = _tables.firstWhere((t) => t.id == tableId);
    final duration = _getTablePlayDuration(tableId);
    final rate = _hourlyRates[table.tableTypeId.toString()] ?? 80000.0;
    return (duration.inSeconds / 3600.0) * rate;
  }

  // Action: Toggle Power (Turn light ON/OFF & manage billing)
  Future<void> _toggleTablePower(String tableId) async {
    final tableIndex = _tables.indexWhere((t) => t.id == tableId);
    if (tableIndex == -1) return;

    final currentTable = _tables[tableIndex];
    final iotConfig = _iotConfigs[tableId];

    if (iotConfig == null) {
      _logGeneral('Error: Table ${currentTable.tableName} does not have an IoT configurations map.');
      return;
    }

    if (currentTable.status == 'idle') {
      // 1. TURN ON TABLE (Start Game)
      _logGeneral('Activating table ${currentTable.tableName}...');
      
      // Get or instantiate controller
      BilliardIoTController controller = _activeControllers[tableId] ??
          (_useRealController
              ? RealBilliardIoTController()
              : SimulatedBilliardIoTController());
      
      _activeControllers[tableId] = controller;

      // Listen to logs from the controller
      final logSubscription = controller.logStream.listen((logEvent) {
        if (mounted) {
          setState(() {
            _consoleLogs.add(logEvent);
          });
          _scrollToConsoleBottom();
        }
      });

      // Connect
      final connected = await controller.connect(iotConfig);
      if (!connected) {
        _logGeneral('Error: Could not establish connection to IoT relay for ${currentTable.tableName}.');
        return;
      }

      // Turn ON
      final turnedOn = await controller.turnOn();
      if (!turnedOn) {
        _logGeneral('Error: Relay failed to toggle ON for ${currentTable.tableName}.');
        return;
      }

      setState(() {
        _tables[tableIndex] = currentTable.copyWith(
          status: 'active',
          currentOrderId: 'ord-${DateTime.now().millisecondsSinceEpoch}',
        );
        _tableStartTimes[tableId] = DateTime.now();
        
        // Add some mock orders for simulation
        _tableMockOrders[tableId] = [
          {'name': 'Sting Dâu Đỏ', 'price': 15000.0, 'qty': 2},
          {'name': 'Bánh Mì Kẹp Thịt', 'price': 25000.0, 'qty': 1},
        ];
      });

      _logGeneral('Table ${currentTable.tableName} is now ACTIVE. Game timer started.');
    } else if (currentTable.status == 'active') {
      // 2. TURN OFF TABLE (Checkout and show invoice)
      _logGeneral('Deactivating table ${currentTable.tableName} and preparing invoice...');

      final controller = _activeControllers[tableId];
      if (controller != null) {
        final turnedOff = await controller.turnOff();
        if (!turnedOff) {
          _logGeneral('Warning: Relay failed to toggle OFF cleanly.');
        }
        await controller.disconnect();
      }
      
      _activeControllers.remove(tableId);

      final endTime = DateTime.now();
      final startTime = _tableStartTimes[tableId] ?? endTime;
      final duration = endTime.difference(startTime);
      final playMinutes = duration.inMinutes + (duration.inSeconds % 60 > 0 ? 1 : 0); // round up
      final rate = _hourlyRates[currentTable.tableTypeId.toString()] ?? 80000.0;
      final playAmount = (playMinutes / 60.0) * rate;

      final products = _tableMockOrders[tableId] ?? [];
      double productAmount = 0.0;
      for (final p in products) {
        productAmount += (p['price'] as double) * (p['qty'] as int);
      }

      final totalAmount = playAmount + productAmount;

      // Show Invoice Dialog before resetting table state
      if (mounted) {
        await _showInvoiceDialog(
          tableName: currentTable.tableName,
          startTime: startTime,
          endTime: endTime,
          playMinutes: playMinutes,
          playAmount: playAmount,
          rate: rate,
          products: products,
          totalAmount: totalAmount,
        );
      }

      setState(() {
        _tables[tableIndex] = currentTable.copyWith(
          status: 'idle',
          currentOrderId: null,
        );
        _tableStartTimes.remove(tableId);
        _tableMockOrders.remove(tableId);
      });

      _logGeneral('Table ${currentTable.tableName} is now IDLE.');
    }
  }

  // Invoice visual receipt dialog
  Future<void> _showInvoiceDialog({
    required String tableName,
    required DateTime startTime,
    required DateTime endTime,
    required int playMinutes,
    required double playAmount,
    required double rate,
    required List<Map<String, dynamic>> products,
    required double totalAmount,
  }) async {
    final formatTime = (DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    final formatCurrency = (double amount) => '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HÓA ĐƠN THANH TOÁN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF2E4F4F),
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bàn:', style: TextStyle(color: Colors.grey)),
                    Text(tableName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thời gian chơi:', style: TextStyle(color: Colors.grey)),
                    Text('${formatTime(startTime)} - ${formatTime(endTime)}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Tổng số phút:', style: TextStyle(color: Colors.grey)),
                    Text('$playMinutes phút', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Đơn giá giờ chơi:', style: TextStyle(color: Colors.grey)),
                    Text('${formatCurrency(rate)}/giờ', style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Thành tiền giờ:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(formatCurrency(playAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E4F4F))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Dịch vụ đi kèm:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E4F4F)),
                ),
                const SizedBox(height: 6),
                if (products.isEmpty)
                  const Text('Không sử dụng dịch vụ ăn uống.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13))
                else
                  ...products.map((p) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${p['name']} (x${p['qty']})', style: const TextStyle(fontSize: 13)),
                            Text(formatCurrency((p['price'] as double) * (p['qty'] as int)), style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      )),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('TỔNG THANH TOÁN:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      formatCurrency(totalAmount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFFE28743),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _logGeneral('Invoice for $tableName finalized and printed.');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E4F4F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('XÁC NHẬN THANH TOÁN & IN HÓA ĐƠN'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Update configuration details from the editor panel
  void _updateIotConfig({
    required String connectionType,
    required String? port,
    required String? ipAddress,
    required int relayChannel,
  }) {
    if (_selectedTableId == null) return;
    
    final currentConfig = _iotConfigs[_selectedTableId!];
    if (currentConfig == null) return;

    setState(() {
      _iotConfigs[_selectedTableId!] = IotConfigModel(
        id: currentConfig.id,
        tableId: currentConfig.tableId,
        connectionType: connectionType,
        port: port,
        ipAddress: ipAddress,
        relayChannel: relayChannel,
        commandOn: currentConfig.commandOn,
        commandOff: currentConfig.commandOff,
        createdAt: currentConfig.createdAt,
        updatedAt: DateTime.now(),
      );
    });

    _logGeneral('Updated IoT Config mapping for ${getNameOfTable(_selectedTableId!)}');
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = (double amount) => '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ';

    final selectedTable = _tables.firstWhere((t) => t.id == _selectedTableId);
    final selectedIotConfig = _iotConfigs[_selectedTableId!];
    final isSelectedTableActive = selectedTable.status == 'active';
    final selectedDuration = _getTablePlayDuration(_selectedTableId!);
    final selectedCost = _calculatePlayCost(_selectedTableId!);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E4F4F),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.table_bar, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Billiard POS & IoT Control',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Spacer(),
            // Simulation Toggle
            Row(
              children: [
                const Text('Chế độ giả lập IoT:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 8),
                Switch(
                  value: !_useRealController,
                  onChanged: (val) {
                    setState(() {
                      _useRealController = !val;
                      _logGeneral('Switched IoT driver to: ${_useRealController ? "Real Hardware (Socket/Serial)" : "Simulated/Mock Mode"}');
                    });
                  },
                  activeColor: const Color(0xFFE28743),
                  activeTrackColor: const Color(0xFFE28743).withOpacity(0.4),
                  inactiveThumbColor: Colors.grey[400],
                  inactiveTrackColor: Colors.grey[700],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. LEFT COLUMN: Grid Sơ đồ bàn (Billiards Table Grid)
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SƠ ĐỒ BÀN (TABLE GRID SYSTEM)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF212121), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GridView.builder(
                      itemCount: _tables.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemBuilder: (context, index) {
                        final table = _tables[index];
                        final isSelected = table.id == _selectedTableId;
                        final isActive = table.status == 'active';
                        
                        // Color styling depending on table state
                        Color cardColor;
                        Color accentColor;
                        Color textColor = const Color(0xFF212121);

                        if (isActive) {
                          cardColor = const Color(0xFFE2ECF7);
                          accentColor = const Color(0xFF1E3A8A); // active
                        } else if (table.status == 'maintenance') {
                          cardColor = const Color(0xFFFDE8E8);
                          accentColor = const Color(0xFF9B1C1C); // red/error
                        } else {
                          cardColor = Colors.white;
                          accentColor = Colors.grey[400]!; // idle
                        }

                        if (isSelected) {
                          cardColor = cardColor == Colors.white 
                              ? const Color(0xFFEDF2F2) 
                              : cardColor.withOpacity(0.9);
                        }

                        final playDuration = _getTablePlayDuration(table.id);
                        final durationStr = '${playDuration.inHours.toString().padLeft(2, '0')}:${(playDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(playDuration.inSeconds % 60).toString().padLeft(2, '0')}';

                        return InkWell(
                          onTap: () => _selectTable(table.id),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2E4F4F) : accentColor.withOpacity(0.3),
                                width: isSelected ? 2.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isSelected ? 0.08 : 0.03),
                                  blurRadius: isSelected ? 12 : 6,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          table.tableName,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isActive ? Colors.green : Colors.grey,
                                          boxShadow: isActive ? [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(0.6),
                                              blurRadius: 6,
                                              spreadRadius: 2,
                                            )
                                          ] : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    table.tableTypeId == 1
                                        ? 'Bàn Pool'
                                        : table.tableTypeId == 2
                                            ? 'Bàn Carom'
                                            : 'Bàn Snooker',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  if (isActive) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Thời gian:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text(durationStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Courier')),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Tạm tính:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text(formatCurrency(_calculatePlayCost(table.id)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E4F4F))),
                                      ],
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        table.status == 'maintenance' ? 'Bảo trì' : 'Trống',
                                        style: TextStyle(
                                          color: table.status == 'maintenance' ? Colors.red : Colors.grey[600],
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. BOTTOM ROW (CONSOLE LOGS)
                  const Text(
                    'CONSOLE COMMUNICATIONS LOGS (HEX TRAFFIC)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF212121), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Live Relays I/O Diagnostics',
                                style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[400],
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                setState(() {
                                  _consoleLogs.clear();
                                });
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 14),
                                  SizedBox(width: 4),
                                  Text('Clear log', style: TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 8),
                        Expanded(
                          child: ListView.builder(
                            controller: _consoleScrollController,
                            itemCount: _consoleLogs.length,
                            itemBuilder: (context, index) {
                              final log = _consoleLogs[index];
                              Color logColor = Colors.white;
                              if (log.contains('TX:')) {
                                logColor = const Color(0xFF38BDF8); // Blue for TX
                              } else if (log.contains('RX:')) {
                                logColor = const Color(0xFF4ADE80); // Green for RX
                              } else if (log.contains('ERROR')) {
                                logColor = const Color(0xFFF87171); // Red for error
                              } else if (log.contains('System')) {
                                logColor = const Color(0xFFFBBF24); // Yellow for System
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  log,
                                  style: TextStyle(
                                    color: logColor,
                                    fontFamily: 'Courier',
                                    fontSize: 12.5,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 3. RIGHT COLUMN: Detail and Config Panel (Màn hình điều khiển và cấu hình IoT)
          Container(
            width: 380,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: Color(0xFFECEFF1), width: 1),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Row(
                  children: [
                    const Icon(Icons.settings_input_hdmi, color: Color(0xFF2E4F4F)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedTable.tableName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const Text(
                            'IoT Configuration & Control Panel',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                // POWER CONTROLLER BOX (Relay Trigger UI)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelectedTableActive ? const Color(0xFFEDF7F7) : const Color(0xFFF4F6F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelectedTableActive ? const Color(0xFF2E4F4F).withOpacity(0.3) : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isSelectedTableActive ? 'TRẠNG THÁI: HOẠT ĐỘNG' : 'TRẠNG THÁI: TẮT ĐÈN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                              color: isSelectedTableActive ? const Color(0xFF2E4F4F) : Colors.grey[700],
                            ),
                          ),
                          Icon(
                            Icons.circle,
                            color: isSelectedTableActive ? Colors.green : Colors.grey,
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _toggleTablePower(_selectedTableId!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelectedTableActive ? Colors.red[600] : const Color(0xFF2E4F4F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isSelectedTableActive ? Icons.power_settings_new : Icons.play_arrow),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                isSelectedTableActive ? 'TẮT BÀN & THANH TOÁN' : 'BẬT ĐÈN BÀN & TÍNH GIỜ',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // REAL-TIME STATS PANEL (WHEN ACTIVE)
                if (isSelectedTableActive) ...[
                  const Text(
                    'THỜI GIAN THỰC TẾ (REAL-TIME BILLING)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Bắt đầu:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text(
                              '${_tableStartTimes[_selectedTableId!]?.hour.toString().padLeft(2, '0')}:${_tableStartTimes[_selectedTableId!]?.minute.toString().padLeft(2, '0')}:${_tableStartTimes[_selectedTableId!]?.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tổng giờ chơi:', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text(
                              '${selectedDuration.inHours.toString().padLeft(2, '0')}:${(selectedDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(selectedDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Courier'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tiền giờ (tạm tính):', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text(
                              formatCurrency(selectedCost),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E4F4F)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // IOT HARDWARE MAP EDITOR
                const Text(
                  'CẤU HÌNH PHẦN CỨNG IOT (RELAY BOARD SETUP)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                
                // Form Fields to view/edit configuration mapping
                if (selectedIotConfig != null) ...[
                  // Connection type selector
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Serial (COM)', style: TextStyle(fontSize: 11)),
                          value: 'serial',
                          groupValue: selectedIotConfig.connectionType,
                          onChanged: (val) {
                            if (val != null) {
                              _updateIotConfig(
                                connectionType: val,
                                port: selectedIotConfig.port ?? 'COM3',
                                ipAddress: selectedIotConfig.ipAddress,
                                relayChannel: selectedIotConfig.relayChannel,
                              );
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('LAN (TCP/IP)', style: TextStyle(fontSize: 11)),
                          value: 'tcp_ip',
                          groupValue: selectedIotConfig.connectionType,
                          onChanged: (val) {
                            if (val != null) {
                              _updateIotConfig(
                                connectionType: val,
                                port: selectedIotConfig.port ?? '8080',
                                ipAddress: selectedIotConfig.ipAddress ?? '192.168.1.100',
                                relayChannel: selectedIotConfig.relayChannel,
                              );
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Connection inputs depending on selection
                  if (selectedIotConfig.connectionType == 'serial')
                    TextField(
                      controller: TextEditingController(text: selectedIotConfig.port),
                      onSubmitted: (val) {
                        _updateIotConfig(
                          connectionType: selectedIotConfig.connectionType,
                          port: val,
                          ipAddress: selectedIotConfig.ipAddress,
                          relayChannel: selectedIotConfig.relayChannel,
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Cổng Serial (e.g. COM3 or /dev/ttyUSB0)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                    )
                  else ...[
                    TextField(
                      controller: TextEditingController(text: selectedIotConfig.ipAddress),
                      onSubmitted: (val) {
                        _updateIotConfig(
                          connectionType: selectedIotConfig.connectionType,
                          port: selectedIotConfig.port,
                          ipAddress: val,
                          relayChannel: selectedIotConfig.relayChannel,
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Địa chỉ IP Relay Board (LAN)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: TextEditingController(text: selectedIotConfig.port),
                      onSubmitted: (val) {
                        _updateIotConfig(
                          connectionType: selectedIotConfig.connectionType,
                          port: val,
                          ipAddress: selectedIotConfig.ipAddress,
                          relayChannel: selectedIotConfig.relayChannel,
                        );
                      },
                      decoration: const InputDecoration(
                        labelText: 'Cổng Port TCP',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        labelStyle: TextStyle(fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Relay Channel Selector
                  DropdownButtonFormField<int>(
                    value: selectedIotConfig.relayChannel,
                    decoration: const InputDecoration(
                      labelText: 'Cổng Relay đóng ngắt',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    items: List.generate(8, (i) => i + 1).map((ch) {
                      return DropdownMenuItem<int>(
                        value: ch,
                        child: Text('Kênh Rơ-le $ch', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _updateIotConfig(
                          connectionType: selectedIotConfig.connectionType,
                          port: selectedIotConfig.port,
                          ipAddress: selectedIotConfig.ipAddress,
                          relayChannel: val,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Raw HEX Command viewers
                  Text(
                    'HEX CMD Bật (HEX): ${selectedIotConfig.commandOn}',
                    style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'HEX CMD Tắt (HEX): ${selectedIotConfig.commandOff}',
                    style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}
