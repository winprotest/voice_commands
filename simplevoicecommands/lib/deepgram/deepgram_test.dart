import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:file_picker/file_picker.dart' if (dart.library.html) 'file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:record/record.dart';
import 'package:simplevoicecommands/deepgram/utils.dart';
import 'package:simplevoicecommands/main.dart';
import 'package:universal_file/universal_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const fileName = 'fr.mp3';
const fileAssetPath = 'assets/deepgram/$fileName';
const url = 'https://www2.cs.uic.edu/~i101/SoundFiles/taunt.wav';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  if (!kIsWeb) await copyAssetToFile(fileAssetPath, fileName);
  runApp(const MainApp());
}

void checkApiKey() async {
  debugPrint('Checking API key...');
  final isValid = await deepgram.isApiKeyValid();

  debugPrint('API key is valid:  $isValid');
}

void playFromURL() async {
  final player = AudioPlayer();
  await player.play(
    UrlSource('https://github.com/rafaelreis-hotmart/Audio-Sample-files/raw/refs/heads/master/sample.mp3'),
  );
  debugPrint('playFromURL done');
}

void fromFile() async {
  // web needs user to pick file
  if (kIsWeb) {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result == null) return;
    final data = result.files.first.bytes;
    if (data == null) return;
    final res = await deepgram.listen.bytes(data);
    debugPrint(res.transcript);
  } else {
    // ios android ...
    debugPrint('Transcribing from file...');
    final path = await getLocalFilePath(fileName);
    final file = File(path);

    final res = await deepgram.listen.file(file);
    debugPrint(res.transcript);
  }
}

void fromUrl() async {
  debugPrint('Transcribing from url...');
  final res = await deepgram.listen.url(url);
  debugPrint(res.transcript);
}

void fromBytes() async {
  debugPrint('Transcribing from bytes...');
  final data = await rootBundle.load(fileAssetPath);
  final bytes = data.buffer.asUint8List();
  final res = await deepgram.listen.bytes(bytes);
  debugPrint(res.transcript);
}

final mic = AudioRecorder();
void startStream() async {
  await mic.hasPermission();

  final audioStream = await mic.startStream(
    const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
  );

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
  });
}

void stopStream() async {
  debugPrint('Recording stopped');
  await mic.stop();
}

void speakFromText() async {
  Deepgram deepgramTTS = Deepgram(
    deepgramAPIKey,
    baseQueryParams: {'model': 'aura-asteria-en', 'encoding': "linear16", 'container': "wav"},
  );
  final res = await deepgramTTS.speak.text("hello, how are you today ?");
  log(
    'speakFromText runtimeType:${res.data.runtimeType} metaData:${res.metadata} '
    'res.data:${res.data?.length}',
  );
  if (res.data == null) return debugPrint('No audio data found');

  final player = AudioPlayer();
  //player.setSourceBytes(res.data!);
  //await player.play(BytesSource(res.data!));
  final textSourceController = getTextStreamController(duration: 6);
  final stream = deepgramTTS.speak.live(textSourceController.stream);
  final List<Uint8List> audioResults = [res.data!];
  int index = 0;
  void playNext() async {
    if (index < audioResults.length) {
      final data = audioResults[index++];
      debugPrint('Playing audio $index / ${audioResults.length} (${data.lengthInBytes} bytes)');
      await player.play(BytesSource(Deepgram.toWav(data)));

      return;
    }
    debugPrint('All audio played');
  }

  stream.listen((res) {
    debugPrint(res.toString());
    if (res.data != null) audioResults.add(res.data!);
    if (audioResults.length == 1) playNext(); // first audio, play it
  });

  player.onPlayerComplete.listen((_) {
    // player has finished playing the last audio, play the next one
    playNext();
  });
}

void speakFromStream() async {
  Deepgram deepgramTTS = Deepgram(
    deepgramAPIKey,
    baseQueryParams: {
      // 'model': 'aura-asteria-en',
      // 'encoding': "linear16",
      // 'sample_rate': 48000,
      // 'container': "wav",
    },
  );

  final textSourceController = getTextStreamController(duration: 6);
  final stream = deepgramTTS.speak.live(textSourceController.stream);

  final List<Uint8List> audioResults = [];
  int index = 0;
  final player = AudioPlayer();

  // in this case it's best to create a buffer, stack the audio data and play it all at once using Deepgram.toWav()
  void playNext() async {
    if (index < audioResults.length) {
      final data = audioResults[index++];
      debugPrint('Playing audio $index / ${audioResults.length} (${data.lengthInBytes} bytes)');
      await player.play(BytesSource(Deepgram.toWav(data)));

      return;
    }
    debugPrint('All audio played');
  }

  stream.listen((res) {
    debugPrint(res.toString());
    if (res.data != null) audioResults.add(res.data!);
    if (audioResults.length == 1) playNext(); // first audio, play it
  });

  player.onPlayerComplete.listen((_) {
    // player has finished playing the last audio, play the next one
    playNext();
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Deepgram Example', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
        ),
        body: SingleChildScrollView(
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(onPressed: checkApiKey, child: Text('Check Api Key')),
                  Divider(),
                  ElevatedButton(onPressed: fromFile, child: Text('From File')),
                  ElevatedButton(onPressed: fromUrl, child: Text('From Url')),
                  ElevatedButton(onPressed: fromBytes, child: Text('From Bytes')),
                  Divider(),
                  ElevatedButton(onPressed: startStream, child: Text('Start Stream')),
                  ElevatedButton(onPressed: stopStream, child: Text('Stop Stream')),
                  Divider(),
                  ElevatedButton(onPressed: speakFromText, child: Text('Speak From Text')),
                  ElevatedButton(onPressed: speakFromStream, child: Text('Speak From Stream')),
                  ElevatedButton(onPressed: playFromURL, child: Text('Play from URL')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
