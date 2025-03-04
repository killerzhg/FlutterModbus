import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

// Create the modbus client.
ModbusClientTcp modbusClient = ModbusClientTcp("192.168.1.6", unitId: 1);
//modbusClient.disconnect();

// 假设 bytesRegister.value 是一个 List<int> 或 Uint8List
int combineBytesToUInt16(List<int> bytes, {bool bigEndian = true}) {
  if (bytes.length != 2) {
    throw ArgumentError("The length of bytes must be 2!");
  }
  int highByte = bytes[0]; // 高位字节
  int lowByte = bytes[1];   // 低位字节
  if (bigEndian) {
    // 大端序：高位字节在前，低位字节在后
    return (highByte << 8) | lowByte;
  } else {
    // 小端序：低位字节在前，高位字节在后
    return (lowByte << 8) | highByte;
  }
}

void main() {
  runApp(const MyApp());
}
// byteCount必须偶数
void getReadRequestString(int address , int byteCount) async {
  var bytesRegister = ModbusBytesRegister(
      name: "BytesArray",
      address: address,
      byteCount: byteCount,
      onUpdate: (self) => {
        print(self)
      });
  var req2 = bytesRegister.getReadRequest();
  var res = await modbusClient.send(req2);
  if (byteCount ==2)
  {
    print(combineBytesToUInt16(bytesRegister.value as List<int>, bigEndian: true));
  } else {
    print(utf8.decode(bytesRegister.value as List<int>));
  }
}

void getWriteRequestString(int address , Uint8List bytes) async {
  var bytesRegister = ModbusBytesRegister(
      name: "BytesArray",
      address: address,
      byteCount: bytes.length,
      onUpdate: (self) => {
        print(self)
      });
  var req1 = bytesRegister.getWriteRequest(bytes);
  var res = await modbusClient.send(req1);
  print(res.code);
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
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
    //Share.share("widget.code");
    getReadRequestString(1100, 4);
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
