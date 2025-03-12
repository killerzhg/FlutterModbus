import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:modbus_client/modbus_client.dart';
import 'package:modbus_client_tcp/modbus_client_tcp.dart';

class ModbusClientWithReconnect {
  final String host;
  final int unitId;
  final int maxReconnectAttempts; // 最大重连次数
  final Duration reconnectInterval; // 重连间隔
  ModbusClientTcp? _modbusClient;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;

  ModbusClientWithReconnect({
    required this.host,
    required this.unitId,
    this.maxReconnectAttempts = 5, // 默认最大重连次数为 5
    this.reconnectInterval = const Duration(seconds: 5), // 默认重连间隔为 5 秒
  }) {
    _modbusClient = ModbusClientTcp(host, unitId: unitId);
  }

  // byteCount必须偶数
  Future<String> getReadRequestString(int address, int byteCount) async {
    var bytesRegister = ModbusBytesRegister(
        name: "BytesArray",
        address: address,
        byteCount: byteCount,
        onUpdate: (self) => {print(self)});
    var req2 = bytesRegister.getReadRequest();
    var res = await send(req2);
    if (byteCount == 2) {
      return combineBytesToUInt16(bytesRegister.value as List<int>,
          bigEndian: true).toString();;
    } else {
      return utf8.decode(bytesRegister.value as List<int>);
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
    var res = await send(req1);
    print(res.code?"写入成功":"写入失败");
  }

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

  ModbusClientTcp get client {
    if (_modbusClient == null) {
      throw Exception("Modbus client is not initialized.");
    }
    return _modbusClient!;
  }

  Future<void> connect() async {
    await _connectWithRetry();
  }

  String get isConnected {
    return client.isConnected?"PLC已连接":"PLC未连接";
  }
  Future<void> _connectWithRetry() async {
    print("开始尝试连接...");
    await Future.doWhile(() async {
      if (client.isConnected) {
        print("已连接");
        _reconnectAttempts = 0; // 重置重连次数
        return false; // 退出循环
      } else {
        try {
          print("尝试连接...");
          await client.connect();
          if (client.isConnected) {
            print("连接成功");
            _reconnectAttempts = 0; // 重置重连次数
            return false; // 退出循环
          } else {
            print("连接失败，等待 ${reconnectInterval.inSeconds} 秒后重试...");
            await Future.delayed(reconnectInterval); // 等待一段时间
            return true; // 继续循环
          }
        } catch (e) {
          print("连接异常: $e，等待 ${reconnectInterval.inSeconds} 秒后重试...");
          await Future.delayed(reconnectInterval); // 等待一段时间
          return true; // 继续循环
        }
      }
    });
  }

  Future<void> disconnect() async {
    await client.disconnect();
  }

  Future<void> reconnect() async {
    if (_isReconnecting) {
      print("正在重连中，请稍后...");
      return;
    }
    _isReconnecting = true;
    _reconnectAttempts = 0;
    print("连接断开，开始尝试重连...");
    while (!client.isConnected && _reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      try {
        print("第 $_reconnectAttempts 次尝试重连...");
        await client.connect();
        if (client.isConnected) {
          print("重连成功");
          _isReconnecting = false;
          _reconnectAttempts = 0;
          return;
        } else {
          print("重连失败，等待 ${reconnectInterval.inSeconds} 秒后重试...");
          await Future.delayed(reconnectInterval);
        }
      } catch (e) {
        print("重连异常: $e，等待 ${reconnectInterval.inSeconds} 秒后重试...");
        await Future.delayed(reconnectInterval);
      }
    }
    _isReconnecting = false;
    if (!client.isConnected) {
      print("重连失败，已达到最大重连次数 $maxReconnectAttempts");
    }
  }

  void startReconnectionListener() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!client.isConnected && !_isReconnecting) {
        reconnect();
      }
    });
  }

  Future<dynamic> send(ModbusRequest request) async {
    if (!client.isConnected) {
      print("未连接，请先连接");
      return null;
    }
    try {
      return await client.send(request);
    } catch (e) {
      print("发送请求异常: $e");
      reconnect();
      return null;
    }
  }
}