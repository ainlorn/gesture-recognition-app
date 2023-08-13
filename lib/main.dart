import 'package:flutter/material.dart';
import 'package:apivideo_live_stream/apivideo_live_stream.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:untitled/speech.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  late ApiVideoLiveStreamController _controller;
  bool _streaming = false;
  String _txt = '';
  String _txtLast15Words = '';
  late WebSocketChannel _channel;

  void onConnectionFailed(String str) {
    setState(() {
      _streaming = false;
      Fluttertoast.showToast(msg: "Не удалось подключиться к серверу.");
    });
  }

  void onConnectionSuccess() {
    setState(() {
      _streaming = true;
    });
  }

  void onDisconnected() {
    setState(() {
      _streaming = false;
    });
  }

  void startStreamingBtn() {
    if (!_streaming) {
      startStreaming();
    } else {
      _controller.stopStreaming();
      setState(() {
        _streaming = false;
      });
    }
  }

  void startStreaming() {
    _controller.startStreaming(
        streamKey: 'mystream', url: 'rtmp://100.73.198.34:1935');
  }

  Future<void> switchCamera() async {
    if (await _controller.cameraPosition == CameraPosition.front) {
      await _controller.setCameraPosition(CameraPosition.back);
    } else {
      await _controller.setCameraPosition(CameraPosition.front);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = ApiVideoLiveStreamController(
        initialAudioConfig: AudioConfig(),
        initialVideoConfig: VideoConfig.withDefaultBitrate(),
        initialCameraPosition: CameraPosition.front,
        onConnectionFailed: onConnectionFailed,
        onConnectionSuccess: onConnectionSuccess,
        onDisconnection: onDisconnected);
    _controller.initialize();
    _controller.setIsMuted(true);
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _channel = WebSocketChannel.connect(Uri.parse('ws://100.73.198.34:9000'));
    _channel.stream.listen((event) {
      setState(() {
        _txt += event + ' ';
        _txtLast15Words += event + ' ';
        var spl = _txtLast15Words.split(' ');
        if (spl.length > 15) {
          _txtLast15Words =
              "${spl.getRange(spl.length - 15, spl.length - 1).join(" ")} ";
        }
      });
    });
  }
  
  void showModalSheet() {
    showModalBottomSheet(context: context, builder: (context) {
      return Container(
        height: 1000,
        child: Center(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 7),
                    Container(height: 3, width: 60, color: Colors.grey)
                  ]
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(padding: const EdgeInsets.all(5),
                      child: Text(
                          _txt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20)
                      ))
                ],
              )
            ],
          )
        )
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);
    return Scaffold(
        body: SafeArea(
            child: Stack(fit: StackFit.expand, children: [
                Container(color: Colors.black, child:
                  Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ApiVideoCameraPreview(controller: _controller),
                      const SizedBox(height: 50),
                    ])),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(height: 30),
                    const AudioRecognize(),
                    const Spacer(),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Stack(children: [
                          Text(
                            _txtLast15Words,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = Colors.black,
                            ),
                          ),
                          Text(_txtLast15Words,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 22),
                          textAlign: TextAlign.center)])),
                    const SizedBox(height: 30),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: showModalSheet,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                surfaceTintColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20)),
                            child: const Icon(Icons.list),
                          ),
                          ElevatedButton(
                            onPressed: startStreamingBtn,
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20)),
                            child: Icon(_streaming
                                ? Icons.stop_outlined
                                : Icons.play_arrow_outlined),
                          ),
                          ElevatedButton(
                            onPressed: switchCamera,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                surfaceTintColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20)),
                            child: const Icon(Icons.change_circle_outlined),
                          ),
                    ]),
                    const SizedBox(height: 15)
        ],
      )
    ])));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller.stop();
      setState(() {
        _streaming = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      _controller.startPreview();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
