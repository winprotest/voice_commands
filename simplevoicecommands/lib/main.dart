import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:simplevoicecommands/deepgram/tts_stt_main.dart';
import 'package:simplevoicecommands/deepgram/stt_test.dart';

final deepgramAPIKey = dotenv.get("DEEPGRAM_API_KEY");
Deepgram deepgram = Deepgram(deepgramAPIKey, baseQueryParams: baseParams);
// reference : https://developers.deepgram.com/reference/listen-file
Map<String, dynamic> baseParams = {
  'model': 'nova-2-general',
  'detect_language': true,
  'filler_words': false,
  'punctuation': true,
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  final _title = 'Speech to Text App';
  const ExampleApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _title,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: TTSSSTMainPage(),
    );
  }
}
