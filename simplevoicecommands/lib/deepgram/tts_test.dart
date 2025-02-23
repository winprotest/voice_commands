
import 'dart:developer';


import 'package:audioplayers/audioplayers.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
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
  final Map<String,String> voicePersonMap ={
    'aura-asteria-en':'Asteria (American, feminine)',
    'aura-orpheus-en':'Orpheus (American, masculine)',
    'aura-angus-en':'Angus (Irish, masculine)',
    'aura-arcas-en':'Arcas (American, masculine)',
    'aura-athena-en':'Athena (British, feminine)',
    'aura-helios-en':'Helios (British, masculine)',
    'aura-hera-en':'Hera (American, feminine)',
    'aura-luna-en': 'Luna (American, feminine)',
    'aura-orion-en':'Orion (American, masculine)',
    'aura-perseus-en':'Perseus (American, masculine)',
    'aura-stella-en':'Stella (American, feminine)',
    'aura-zeus-en':'Zeus (American, masculine)'};
   
  late List<String> voicePersonList =[];
  late TextStyle hintFontStyle;
  late TextStyle normalFontStyle;
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String dropdownPersonCodeValue;

  @override
  void initState() {
    super.initState();
    _init();
  }

  String _getTheOutputVoicePersonCodeName(){
    if (dropdownPersonCodeValue.isNotEmpty){
      final resultEntry =  voicePersonMap.entries.firstWhereOrNull((entry) => entry.value == dropdownPersonCodeValue);
      if (resultEntry != null){
        return resultEntry.key;
      }
    }
    return voicePersonMap.keys.first;
  }

  void _init() async {
    voicePersonMap.forEach((key, value) {
      voicePersonList.add(value);
    });
    dropdownPersonCodeValue = voicePersonList.first;
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
    final String selectedVoicePersonCodeName = _getTheOutputVoicePersonCodeName();
    Deepgram deepgramTTS = Deepgram(
      deepgramAPIKey,
      baseQueryParams: {'model': selectedVoicePersonCodeName, 'encoding': "mp3",  'bit_rate': 48000,},
      //baseQueryParams: {'model': 'aura-asteria-en', 'encoding': "linear16", 'container': "wav"},
    );
    final res = await deepgramTTS.speak.text(_textEditingController.text);
    log(
      'speakFromText selectedVoicePersonCodeName:$selectedVoicePersonCodeName metaData:${res.metadata} '
          'res.data:${res.data?.length}',
    );
    if (res.data == null)  {
      debugPrint('No audio data found');
      if (mounted){
        showSnackbar(context, 'Error ! The server did not return any audio data!', isError: true);
      }
      return;
    }
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
            const Text('Select preferred voice'),
            Container(
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                  side: BorderSide(width: 1.0, style: BorderStyle.solid),
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                ),
              ),
              child:DropdownButton<String>(
                padding: EdgeInsets.only(left:4, right:4),
                value: dropdownPersonCodeValue,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                underline: SizedBox.shrink(),
                onChanged: (String? value) {
                  // This is called when the user selects an item.
                  setState(() {
                    dropdownPersonCodeValue = value!;
                  });
                },
                items:
                voicePersonList.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
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
