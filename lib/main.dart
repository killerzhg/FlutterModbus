import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'socket/modbusTCP.dart';

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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _connect(); // 连接 Modbus 服务器
  }

  Future<void> _connect() async {
    await modbusClient.connect();
    modbusClient.startReconnectionListener(); // 启动重连监听器
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        log('应用回到前台');
        break;
      case AppLifecycleState.inactive:
        //通常是应用即将暂停（paused）或者恢复（resumed）的过渡状态.当应用处于非活跃状态时，它并没有完全失去焦点，但也不能接收用户的输入。
        if (Theme.of(context).platform == TargetPlatform.iOS ||
            Theme.of(context).platform == TargetPlatform.android) {
          log("应用处于非活动状态");
        }
        break;
      case AppLifecycleState.paused:
        //当应用处于暂停状态时，它在后台运行，不再接收用户输入，并且通常会停止执行一些不必要的操作以节省资源。后台不能执行网络请求 只针对移动端
        log('应用进入后台');
        break;

      case AppLifecycleState.detached:
        log('应用与宿主隔离');
        break;
      case AppLifecycleState.hidden:
        //桌面端最小化的时候调用这个 只针对桌面端
        if (Theme.of(context).platform == TargetPlatform.windows ||
            Theme.of(context).platform == TargetPlatform.linux ||
            Theme.of(context).platform == TargetPlatform.macOS) {
          log("应用最小化");
        }
        break;
    }
  }

  //region 系统改变回调
  //当前系统改变了一些访问性活动的回调
  // @override
  // void didChangeAccessibilityFeatures() {
  //   super.didChangeAccessibilityFeatures();
  //   print("didChangeAccessibilityFeatures 当前系统改变了一些访问性活动的回调");
  // }
  //
  // //低内存回调
  // @override
  // void didHaveMemoryPressure() {
  //   super.didHaveMemoryPressure();
  //   print("didHaveMemoryPressure 低内存回调");
  // }
  // //用户本地设置变化时调用，如系统语言改变
  // @override
  // void didChangeLocales(List<Locale>? locale) {
  //   super.didChangeLocales(locale);
  //   print("didChangeLocales 用户本地设置变化时调用，如系统语言改变");
  // }
  // //应用尺寸改变时回调，例如旋转
  // @override
  // void didChangeMetrics() {
  //   super.didChangeMetrics();
  //   Size size = WidgetsBinding.instance.window.physicalSize;
  //   print("didChangeMetrics  ：宽：${size.width} 高：${size.height}");
  // }
  // //系统切换主题时回调
  // @override
  // void didChangePlatformBrightness() {
  //   super.didChangePlatformBrightness();
  //   print("didChangePlatformBrightness 切换主题");
  // }
  // ///文字系数变化
  // @override
  // void didChangeTextScaleFactor() {
  //   super.didChangeTextScaleFactor();
  //   print(
  //       "didChangeTextScaleFactor  文字系数变化：${WidgetsBinding.instance.window.textScaleFactor}");
  // }
  // @override
  // void deactivate() {
  //   print("deactivate");
  //   // TODO: implement deactivate
  //   super.deactivate();
  // }
//endregion

  Future<void> _incrementCounter() async {
    //modbusClient.getReadRequestString(2970, 12);
    if (!modbusClient.client.isConnected) {
      _showNoConnectionDialog(context);
      return;
    }
    var value =
        await modbusClient.getReadRequestString(int.parse(_registerAddress), 2);
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
        title: Text(modbusClient.getConnectStatus),
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
                    _registerAddress =
                        value; // Update the variable with the input value
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
