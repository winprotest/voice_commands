import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:simplevoicecommands/main.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'deepgram_test.dart';

// reference : https://developers.deepgram.com/reference/listen-file
Map<String, dynamic> baseParams = {
  'model': 'nova-2-general',
  'detect_language': true,
  'filler_words': false,
  'punctuation': true,
};

class ZdeepgramTestPage extends StatefulWidget {
  const ZdeepgramTestPage({super.key, required this.title});

  final String title;

  @override
  State<ZdeepgramTestPage> createState() => _ZdeepgramTestPage();
}

class _ZdeepgramTestPage extends State<ZdeepgramTestPage> {
  final mic = AudioRecorder();
  bool _isListening = false;
  late TextStyle hintFontStyle;
  late TextStyle normalFontStyle;
  final TextEditingController _textEditingController = TextEditingController();
  bool _hasPermission = false;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    hintFontStyle = TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w100);
    normalFontStyle = TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w400);
    _hasPermission = await mic.hasPermission();
    log('_hasPermission:$_hasPermission');
    if (!_hasPermission){
      requestAudioPermissions();
    }
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
                  ignoring: !_hasPermission,
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
            const SizedBox(height: 10,),
            Flexible(
              flex: 1,
              child: Text(_hasPermission ? (_isListening ? 'Listening...' : 'Press button and speak now')
                  :'Please enable MIC permission.', style: normalFontStyle),
            ),
            if (!_hasPermission)
              Flexible(
                flex: 1,
                child: TextButton(onPressed: _openSettings, child: Text('Open settings')),
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
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  child: TextField(
                    controller: _textEditingController,
                    scrollController: _scrollController,
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
                ),
                //animation1719108527778 //animation1700642783167
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startStream() async {
    //todo handle permission stuff here
    final audioStream = await mic.startStream(
      const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
    );

    _textEditingController.text = '';

    debugPrint('Recording started...');

    final liveParams = {
      'detect_language': false, // not supported by streaming API
      'language': 'en',
      // must specify encoding and sample_rate according to the audio stream
      'encoding': 'linear16',
      'sample_rate': 16000,
    };

    final stream = deepgram.listen.live(audioStream, queryParams: liveParams);
    stream.listen((res) {
      debugPrint(res.transcript);
      _textEditingController.text += '${res.transcript}\n' ?? '';
    });
  }

  void stopStream() async {
    debugPrint('Recording stopped');
    await mic.stop();
  }

  void _onPlayerStart() async {
    startStream();
    setState(() {
      _isListening = true;
    });
  }

  void _onPlayerStop() async {
    stopStream();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _openSettings() async {
    if (await Permission.microphone.isPermanentlyDenied) {
      log('Microphone permission permanently denied.');
      await openAppSettings();
    } else {
      log('Microphone permission denied.');
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        openAppSettings();
      }
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
      status = await Permission.microphone.request();
    }
  }
}
