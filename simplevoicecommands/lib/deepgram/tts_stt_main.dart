

import 'package:flutter/material.dart';
import 'package:simplevoicecommands/deepgram/tts_test.dart';
import 'package:simplevoicecommands/deepgram/stt_test.dart';

class TTSSSTMainPage extends StatelessWidget {
  const TTSSSTMainPage({ super.key });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Simple Voice Commands Test')),
      body:Center(
        child:SizedBox(
          height: MediaQuery.of(context).size.height * 0.2,
          child:Column(
            children: [
              Expanded(child:OutlinedButton(onPressed: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => TTSTestPage(title: 'Text to Speech')));
              }, child: Text('Text to Speech'))),
              const SizedBox(height: 20,),
              Expanded(child:OutlinedButton(onPressed: (){
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => STTTestPage(title: 'Speech to Text')));
              }, child: Text('Speech to Text'))),
            ],
          ),
        )
      )
    );
  }
}