import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'socket/modbusTCP.dart';

void main() {
  runApp(const MyApp());
  WidgetsBinding.instance.addObserver(MyAppLifecycleObserver());
}

class MyAppLifecycleObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      print('App进入后台');
      // 在这里执行进入后台的逻辑，如暂停动画、保存数据等
    } else if (state == AppLifecycleState.resumed) {
      print('App回到前台');
      // 在这里执行回到前台的逻辑，如恢复动画、重新加载数据等
    }
  }
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
  String _registerAddress = ""; // Variable to store the input value

  // 创建 ModbusClientWithReconnect 对象
  final ModbusClientWithReconnect modbusClient = ModbusClientWithReconnect(
    host: "192.168.1.6", // 替换为你的 Modbus 服务器地址
    unitId: 1, // 替换为你的 Modbus 单元 ID
    maxReconnectAttempts: 10, // 设置最大重连次数为 10
    reconnectInterval: const Duration(seconds: 3), // 设置重连间隔为 3 秒
  );

  @override
  void initState() {
    super.initState();
    _connect();// 连接 Modbus 服务器
  }

  Future<void> _connect() async {
    await modbusClient.connect();
    // 启动重连监听器
    modbusClient.startReconnectionListener();
  }

@override
  void deactivate() {
    print("deactivate");
    // TODO: implement deactivate
    super.deactivate();
  }

  Future<void>  _incrementCounter() async {
    //modbusClient.getReadRequestString(2970, 12);
    if (!modbusClient.client.isConnected) {
      _showNoConnectionDialog(context);
      return;
    }
    var value = await modbusClient.getReadRequestString(int.parse(_registerAddress), 2);
    result = "Received value: $value";
    setState(() {
      _counter++;
      result;
    });
  }

  void _showNoConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('没有连接'),
          content: const Text('设备未连接。'),
          actions: <Widget>[
            TextButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(modbusClient.isConnected),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 150,
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(hintText: "请输入寄存器地址"),
                onChanged: (value) {
                  _registerAddress = value; // Update the variable with the input value
                },
              )),
            Text(
              result,
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
