import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class STTTestPage extends StatefulWidget {
  const STTTestPage({super.key, required this.title});

  final String title;

  @override
  State<STTTestPage> createState() => _STTTestPageState();
}

class _STTTestPageState extends State<STTTestPage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  late TextStyle hintFontStyle;
  late TextStyle normalFontStyle;
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    hintFontStyle = TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w100);
    normalFontStyle = TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w400);
    await _speechToText.initialize(onError: _onError, onStatus: _onStatus);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: 1,
              //color: Colors.transparent,
              child: Container(
                width: 100,
                height: 100,
                decoration: ShapeDecoration(
                  color: _isListening ? Colors.blue : Colors.lightBlueAccent.shade100,
                  shape: CircleBorder(),
                ),
                child: IgnorePointer(
                  ignoring: !_isListening,
                  child: IconButton(
                    isSelected: _isListening,
                    icon: const Icon(Icons.mic, size: 40, color: Colors.white),
                    selectedIcon: const Icon(Icons.mic_outlined, size: 40, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isListening = !_isListening;
                      });
                      if (_isListening) {
                        _onPlayerStart();
                      } else {
                        _onPlayerStop();
                      }
                    },
                  ),
                ),
              ),
            ),
            Flexible(
              flex: 1,
              child: Text(_isListening ? 'Listening' : 'Press button and speak now', style: normalFontStyle),
            ),

            Flexible(
              flex: 2,
              child: Container(
                color: Colors.transparent,
                child:
                    _isListening
                        ? Lottie.asset(
                          width: 200,
                          height: 100,
                          fit: BoxFit.fill,
                          'assets/lottiefiles/lf20_vwyvwzzl.json',
                        )
                        : SizedBox(width: 200, height: 100),
                //animation1719108527778 //animation1700642783167
              ),
            ),
            Flexible(
              flex: 3,
              child: Container(
                color: Colors.transparent,
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: _textEditingController,
                  decoration: InputDecoration(
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent, width: 5.0)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 1.0)),
                    hintText: 'Capture text will appear here...',
                    hintStyle: hintFontStyle,
                  ),
                  //keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.newline,
                  maxLines: 30,
                ),
                //animation1719108527778 //animation1700642783167
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onStatus(String status) async {
    log('onStatus: $status');
    if (status == SpeechToText.notListeningStatus || status == SpeechToText.doneStatus) {
      log('listener stopped');
      _isListening = false;
    }
    setState(() {});
  }

  void _onError(SpeechRecognitionError errorNotification) {
    _textEditingController.text = "Error: ${errorNotification.errorMsg}\n";
    setState(() {});
  }

  void _onPlayerStart() async {
    _speechToText.listen(onResult: _onResult, listenFor: Duration(seconds: 5));
    setState(() {});
  }

  void _onPlayerStop() async {
    _speechToText.stop();
    _isListening = false;
    setState(() {});
  }

  void _onResult(SpeechRecognitionResult result) {
    final resultJson = result.toJson();
    final alternates = resultJson['alternates'];
    debugPrint('_onResult: runTime:${alternates.runtimeType}  alternates:$alternates');
    if (alternates is List && alternates.isNotEmpty) {
      alternates.sort((a, b) => a['confidence'].compareTo(b['confidence']));
      log('the higest confidence:${alternates.last}');
      _textEditingController.text = 'The highest confidence word:\n ${alternates.last}';
    }
  }

  Future<void> openSettings() async {
    if (await Permission.microphone.isPermanentlyDenied) {
      log('Microphone permission permanently denied.');
      await openAppSettings();
    } else {
      log('Microphone permission denied.');
    }
  }

  Future<void> requestAudioPermissions() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      log('No Microphone permission requesting:');
      status = await Permission.microphone.request();
    }

    if (status.isGranted) {
      log('Microphone permission granted.');
      if (Platform.isAndroid) {
        var foregroundServicePermission = await Permission.systemAlertWindow.request();
        if (!foregroundServicePermission.isGranted) {
          foregroundServicePermission = await Permission.systemAlertWindow.request();
        }
      }
    } else {
      log('Microphone permission denied.');
      openSettings();
    }
  }
}
