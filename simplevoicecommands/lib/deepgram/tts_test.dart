
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:simplevoicecommands/deepgram/utils.dart';
import 'package:simplevoicecommands/main.dart';


// reference : https://developers.deepgram.com/reference/listen-file
Map<String, dynamic> baseParams = {
  'model': 'nova-2-general',
  'detect_language': true,
  'filler_words': false,
  'punctuation': true,
};

class TTSTestPage extends StatefulWidget {
  const TTSTestPage({super.key, required this.title});

  final String title;

  @override
  State<TTSTestPage> createState() => _TTSTestPage();
}

class _TTSTestPage extends State<TTSTestPage> {

  late TextStyle hintFontStyle;
  late TextStyle normalFontStyle;
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    hintFontStyle = TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w100);
    normalFontStyle = TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w400);
  }

  void speakFromText() async {
    if (_textEditingController.text.isEmpty){
      showSnackbar(context, 'Error ! Please enter the text!', isError: true);
      return;
    }
    //aura-orpheus-en
    //&encoding=mp3&bit_rate=32000
    Deepgram deepgramTTS = Deepgram(
      deepgramAPIKey,
      baseQueryParams: {'model': 'aura-asteria-en', 'encoding': "mp3",  'bit_rate': 48000,},
      //baseQueryParams: {'model': 'aura-asteria-en', 'encoding': "linear16", 'container': "wav"},
    );
    final res = await deepgramTTS.speak.text(_textEditingController.text);
    log(
      'speakFromText runtimeType:${res.data.runtimeType} metaData:${res.metadata} '
          'res.data:${res.data?.length}',
    );
    if (res.data == null) return debugPrint('No audio data found');
    final data = res.data ;
    debugPrint(' audio data found');
    final player = AudioPlayer();
    await player.setSourceBytes(res.data!);
    await player.resume();
    //await player.play(BytesSource(Deepgram.toWav(data!)));
    debugPrint(' audio data play');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column( children: [
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
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color:  Theme.of(context).primaryColor, width: 1.0)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey, width: 1.0)),
                    hintText: 'Type your text here',
                    hintStyle: hintFontStyle,
                  ),
                  textInputAction: TextInputAction.newline,
                  maxLines: 30,
                ),
              ),
            ),
          ),
          OutlinedButton(onPressed: speakFromText, child: Text('Speak from Text')),]),
      ),
    );
  }

}
