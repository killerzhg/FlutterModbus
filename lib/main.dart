import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:modbus_client/modbus_client.dart';

import 'socket/modbusTCP.dart';

// 创建 ModbusClientWithReconnect 对象
final ModbusClientWithReconnect modbusClient = ModbusClientWithReconnect(
  host: "192.168.1.6", // 替换为你的 Modbus 服务器地址
  unitId: 1, // 替换为你的 Modbus 单元 ID
  maxReconnectAttempts: 10, // 设置最大重连次数为 10
  reconnectInterval: const Duration(seconds: 3), // 设置重连间隔为 3 秒
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String result = "";



  @override
  void initState() {
    super.initState();
    // 连接 Modbus 服务器
    _connect();
  }

  Future<void> _connect() async {
    await modbusClient.connect();
    // 启动重连监听器
    modbusClient.startReconnectionListener();
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    modbusClient.getReadRequestString(1100, 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
