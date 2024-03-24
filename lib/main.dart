import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

// import your Api from the Dotenv file as String
String evensApiKey = dotenv.env['EVENS_API'] as String;

Future main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SpeechAI',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'SpeechAI'),
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
  //audio player obj that will play audio
  final player = AudioPlayer();

  // This gets our TextEdit control text
  final TextEditingController _textFieldController = TextEditingController();

  //for the progress indicator
  bool _isLoadingVoice = false;

  @override
  void dispose() {
    _textFieldController.dispose();
    player.dispose();
    super.dispose();
  }

  Future<void> playTextToSpeech(String text) async {
    //display the loading icon while we wait for request
    setState(() {
      _isLoadingVoice = true; //progress indicator turn on now
    });

    // our voice model ai that will read the text here we get the model by id change if you know another Voice ID
    String voiceAiModel = '5Q0t7uMcjvnagumLfvZi';

    String url = 'https://api.elevenlabs.io/v1/text-to-speech/$voiceAiModel';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'accept': 'audio/mpeg',
        'xi-api-key': evensApiKey,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "text": text,
        "model_id": "eleven_monolingual_v1",
        "voice_settings": {"stability": .30, "similarity_boost": .75}
      }),
    );

    //progress indicator turn off now
    setState(() {
      _isLoadingVoice = false;
    });

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes; //get the bytes ElevenLabs sent back
      await player.setAudioSource(CustomSourceStreamer(
          bytes)); //send the bytes to be read from the JustAudio library
      player.play(); //play the audio
    } else {
      // throw Exception('Failed to load audio');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _textFieldController,
              style: const TextStyle(fontSize: 17.0),
              maxLines: null,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelStyle:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  labelText: "Enter Some Text to Turn into Speech"),
            ),
            const SizedBox(
              height: 16.00,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent),
                onPressed: () {
                  playTextToSpeech(_textFieldController.text);
                },
                child: _isLoadingVoice
                    ? LinearProgressIndicator(
                        backgroundColor: Colors.greenAccent[
                            300], // Background color of the progress bar
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      )
                    : const Icon(
                        Icons.volume_up,
                        color: Colors.white,
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Feed your own stream of bytes into the player
class CustomSourceStreamer extends StreamAudioSource {
  final List<int> bytes;
  CustomSourceStreamer(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
