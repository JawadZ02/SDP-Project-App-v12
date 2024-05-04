import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:google_speech/endless_streaming_service.dart';
import 'package:google_speech/google_speech.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

import 'esl.dart';

// ESC imports //////////////////////////////////////////////////////////
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'classifier.dart';
//////////////////////////////////////////////////////////////////////

import 'package:flutter_colored_print/flutter_colored_print.dart' as cp;

const int kAudioSampleRate = 16000;
const int kAudioNumChannels = 1;

class TranscriptionPage extends StatefulWidget {
  const TranscriptionPage({super.key});

  // ESC static initializations //////////////////////////////////////////////
  static String emojisToDisplay = '';
  static String emojiDescriptionsToDisplay = '';
  ////////////////////////////////////////////////////////////////////

  static bool recognizing = false;

  @override
  State<StatefulWidget> createState() => TranscriptionPageState();
}

class TranscriptionPageState extends State<TranscriptionPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool recognizeFinished = false;
  String text = '';
  StreamSubscription<List<int>>? _audioStreamSubscription;
  BehaviorSubject<List<int>>? _audioStream;
  StreamController<Food>? _recordingDataController;
  StreamSubscription? _recordingDataSubscription;
  String responseText = '';
  String selectedLanguage = 'en-US';
  TextAlign textAlign = TextAlign.left;
  TextDirection textDirection = TextDirection.ltr;
  bool firstTimeShowASL = true;
  String dropdownValue = 'English';

  // ESC Initializations /////////////////////////////////////////////////
  final RecorderStream _recorderESC = RecorderStream();

  bool inputState = true;

  final List<int> _micChunks = [];
  late StreamSubscription _recorderStatus;
  late StreamSubscription _audioStreamESC;

  late StreamController<List<Category>> streamController;
  late Timer _timer;

  late Classifier _classifier;

  List<Category> preds = [];

  Category? prediction;
  /////////////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();

    cp.info('Initializing TranscriptionPage state...');

    // ESC init state /////////////////////////////////////////////////
    streamController = StreamController();
    initPlugin();
    _classifier = Classifier();

    startESC();

    cp.info('ESC Model Loaded.');
    /////////////////////////////////////////////////////////////////////

    cp.info('TranscriptionPage state initialization test passed.');
  }

  // ESC functions /////////////////////////////////////////////////////
  @override
  void dispose() {
    _recorderStatus.cancel();
    _audioStreamESC.cancel();
    _timer.cancel();
    super.dispose();
  }

  Future<void> initPlugin() async {
    cp.info('Initializing ESC recorder...');

    _recorderStatus = _recorderESC.status.listen((status) {
      setState(() {});
    });

    _audioStreamESC = _recorderESC.audioStream.listen((data) {
      if (_micChunks.length > 2 * sampleRate) {
        _micChunks.clear();
      }
      _micChunks.addAll(data);
    });

    streamController.stream.listen((event) {
      setState(() {
        preds = event;
        TranscriptionPage.emojisToDisplay = getAudioDetectedEmojis(preds);
        // TranscriptionPage.emojiDescriptionsToDisplay =
        //     getAudioDetectedDescriptions(preds);
      });
    });

    await Future.wait([_recorderESC.initialize(), _recorderESC.start()]);
  }

  void startESC() async {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      streamController.add(_classifier.predict(_micChunks));
    });

    if (inputState) {
      cp.info('Passed ESC recording initialization test.');
    } else {
      cp.info('Failed ESC recording initialization test.');
    }
  }

  String getAudioDetectedEmojis(List<Category> p) {
    List<String> significantPreds = [];
    for (Category pred in p) {
      if (pred.score >= 0.4) {
        significantPreds.add(pred.label);
      }
    }

    List<String> emojis = [];
    for (String pred in significantPreds) {
      switch (pred) {
        // case 'Silence':
        //   emojis.add('🔇');
        //   break;
        case 'Speech':
          emojis.add('🗣️');
          break;
        case 'Chatter':
          emojis.add('🗣️');
          break;
        case 'Crowd':
          emojis.add('🗣️');
          break;
        case 'Cheering':
          emojis.add('🗣️');
          emojis.add('📣');
          break;
        case 'Applause':
          emojis.add('👏');
          break;
        case 'Telephone bell ringing':
          emojis.add('🔔');
          break;
        case 'Telephone':
          emojis.add('🔔');
          break;
        case 'Train':
          emojis.add('🔔');
          break;
        case 'Rail transport':
          emojis.add('🔔');
          break;
        case 'Ding':
          emojis.add('🔔');
          break;
        case 'Alarm clock':
          emojis.add('🔔');
          break;
        case 'Alarm':
          emojis.add('🔔');
          break;
        case '"Vehicle horn':
          emojis.add('🚗');
          emojis.add('🔊');
          break;
        case '"Air horn':
          emojis.add('🚗');
          emojis.add('🔊');
          break;
        case 'Vehicle':
          emojis.add('🚗');
          break;
        case 'Bus':
          emojis.add('🚌');
          break;
        case 'Car alarm':
          emojis.add('🚨');
          break;
        case 'Siren':
          emojis.add('🚨');
          break;
        case '"Beep':
          emojis.add('🚨');
          break;
        case 'Buzzer':
          emojis.add('🔥');
          emojis.add('🚨');
          break;
        case 'Cowbell':
          emojis.add('🔥');
          emojis.add('🚨');
          break;
        case 'Bagpipes':
          emojis.add('🔥');
          emojis.add('🚨');
          break;
        case 'Fire alarm':
          emojis.add('🔥');
          emojis.add('🚨');
          break;
        case '"Dental drill':
          emojis.add('🔥');
          emojis.add('🚨');
          break;
        case '"Smoke detector':
          emojis.add('💨');
          emojis.add('🚨');
          break;
        case 'Knock':
          emojis.add('✊');
          emojis.add('🚪');
          break;
        case 'Door':
          emojis.add('🚪');
          break;
        case 'Ringtone':
          emojis.add('📞');
          break;
        case 'Music':
          emojis.add('🎵');
          break;
        case 'Walk, footsteps':
          emojis.add('🚶');
          break;
        case 'Whistle':
          emojis.add('😙');
          break;
        case 'Whistling':
          emojis.add('😙');
          break;
        case 'Tools':
          emojis.add('🛠️');
          break;
        case 'Drill':
          emojis.add('🛠️');
          break;
        case 'Power tool':
          emojis.add('🛠️');
          break;
        case 'Sawing':
          emojis.add('🪚');
          break;
        case 'Chainsaw':
          emojis.add('🪚');
          break;
        case 'Light engine (high frequency)':
          emojis.add('🪚');
          break;
        case 'Hammer':
          emojis.add('🔨');
          break;
        case 'Jackhammer':
          emojis.add('🔨');
          break;
        // default:
        //   emojis.add(pred);
      }
    }

    // List<String> emojis = [];
    // for (String pred in significantPreds) {
    //   switch (pred) {
    //     // case 'Silence':
    //     //   emojis.add('🔇');
    //     //   break;
    //     case 'Buzzer':
    //     case 'Fire Alarm':
    //     case 'Alarm':
    //     case 'Ding':
    //       emojis.add('🚨');
    //       break;
    //     case 'Knock':
    //     case 'Door':
    //     case 'Plop':
    //       emojis.add('🚪');
    //       break;
    //     case 'Speech':
    //     case 'Crowd':
    //     case 'Chatter':
    //       emojis.add('🗣️');
    //       break;
    //     case 'Cheering':
    //     case 'Clapping':
    //     case 'Hands':
    //       emojis.add('👏');
    //       break;
    //     case 'Telephone Bell Ringing':
    //     case 'Telephone':
    //     case 'Alarm Clock':
    //     case 'Ringtone':
    //       emojis.add('📞');
    //       break;
    //     case 'Vehicle Horn':
    //     case 'Air Horn':
    //     case 'Vehicle':
    //       emojis.add('🚗');
    //       break;
    //     case 'Car Alarm':
    //     case 'Ambulance (Siren)':
    //     case 'Police Car (Siren)':
    //     case 'Emergency Vehicle':
    //     case 'Fog Horn':
    //     case 'Beep':
    //     case 'Smoke Detector':
    //       emojis.add('🚨');
    //       break;
    //     case 'Music':
    //     case 'Ringtone':
    //       emojis.add('🎵');
    //       break;
    //     case 'Whistle':
    //     case 'Whistling':
    //       emojis.add('😙');
    //       break;
    //     case 'Filing':
    //     case 'Scrape':
    //     case 'Tools':
    //     case 'Rub Wood':
    //     case 'Ratchet':
    //     case 'Wood':
    //     case 'Sawing':
    //     case 'Chainsaw':
    //     case 'Jackhammer':
    //     case 'Hammer':
    //       emojis.add('🛠️');
    //       break;
    //     default:
    //       emojis.add(
    //           pred); // Add the prediction itself if it does not match any case
    //   }
    // }

    // if (emojis.isEmpty) {
    //   emojis.add('🔇');
    // }

    List<String> uniqueEmojis = emojis.toSet().toList();
    String emojisToPrint = uniqueEmojis.join(' ');

    return emojisToPrint;
  }

  String getAudioDetectedDescriptions(List<Category> p) {
    List<String> significantPreds = [];
    for (Category pred in p) {
      if (pred.score >= 0.4) {
        significantPreds.add(pred.label);
      }
    }

    List<String> descriptions = [];
    for (String pred in significantPreds) {
      switch (pred) {
        // case 'Silence':
        //   descriptions.add('Silence');
        //   break;
        case 'Speech':
        case 'Chatter':
        case 'Crowd':
          descriptions.add('Speech');
          break;
        case 'Cheering':
          descriptions.add('Cheering');
          break;
        case 'Applause':
          descriptions.add('Applause');
          break;
        case 'Telephone bell ringing':
        case 'Telephone':
        case 'Train':
        case 'Rail transport':
        case 'Ding':
        case 'Alarm clock':
        case 'Alarm':
          descriptions.add('School bell');
          break;
        case '"Vehicle horn':
        case '"Air horn':
          descriptions.add('Vehicle horn');
          break;
        case 'Vehicle':
          descriptions.add('Vehicle');
          break;
        case 'Bus':
          descriptions.add('Bus');
          break;
        case 'Car alarm':
        case 'Siren':
        case '"Beep':
          descriptions.add('Alarm/Siren');
          break;
        case 'Buzzer':
        case 'Cowbell':
        case 'Bagpipes':
        case 'Fire alarm':
        case '"Dental drill':
          descriptions.add('Fire alarm');
          break;
        case '"Smoke detector':
          descriptions.add('Smoke alarm');
          break;
        case 'Knock':
        case 'Door':
          descriptions.add('Door knocking');
          break;
        case 'Ringtone':
          descriptions.add('Ringtone');
          break;
        case 'Music':
          descriptions.add('Music');
          break;
        case 'Walk, footsteps':
          descriptions.add('Footsteps');
          break;
        case 'Whistle':
        case 'Whistling':
          descriptions.add('Whistling');
          break;
        case 'Tools':
        case 'Drill':
        case 'Power tool':
        // descriptions.add('Construction noise (drill)');
        // break;
        case 'Sawing':
        case 'Chainsaw':
        case 'Light engine (high frequency)':
        // descriptions.add('Construction noise (chainsaw)');
        // break;
        case 'Hammer':
        case 'Jackhammer':
          // descriptions.add('Construction noise (hammer)');
          // break;
          descriptions.add('Construction noise');
          break;
        // default:
        //   emojis.add(pred);
      }
    }

    // if (descriptions.isEmpty) {
    //   descriptions.add('Silence');
    // }

    List<String> uniqueDescriptions = descriptions.toSet().toList();
    String descriptionsToPrint = uniqueDescriptions.join(', ');

    return descriptionsToPrint;
  }
  /////////////////////////////////////////////////////////////////////

  void streamingRecognize() async {
    cp.info('Initializing transcription streaming recognizer...');

    await _recorder.openAudioSession();

    // Stream to be consumed by speech recognizer
    _audioStream = BehaviorSubject<List<int>>();

    // Create recording stream
    _recordingDataController = StreamController<Food>();
    _recordingDataSubscription =
        _recordingDataController?.stream.listen((buffer) {
      if (buffer is FoodData) {
        _audioStream!.add(buffer.data!);
      }
    });

    setState(() {
      TranscriptionPage.recognizing = true;
    });

    await Permission.microphone.request();

    await _recorder.startRecorder(
        toStream: _recordingDataController!.sink,
        codec: Codec.pcm16,
        numChannels: kAudioNumChannels,
        sampleRate: kAudioSampleRate);

    final serviceAccount = ServiceAccount.fromString(
        (await rootBundle.loadString('assets/test_service_account.json')));
    final speechToText =
        EndlessStreamingService.viaServiceAccount(serviceAccount);
    final config = _getConfig();

    final responseStream = speechToText.endlessStream;

    speechToText.endlessStreamingRecognize(
      StreamingRecognitionConfig(config: config, interimResults: true),
      _audioStream!,
      restartTime: const Duration(seconds: 60),
      transitionBufferTime: const Duration(seconds: 2),
    );

    responseStream.listen((data) {
      String currentText =
          data.results.map((e) => e.alternatives.first.transcript).join('\n');

      currentText = currentText.trim();

      if (data.results.first.isFinal) {
        // this is when the new sentence is complete
        // this is where we need to send new sentence to sign language page

        // add most recent complete phrase to phrase queue for processing (to be sent to sign language translation)
        // only for valid languages

        cp.info('New final sentence: $currentText');

        if (ESLPage.validSignLang) {
          if (currentText != '') {
            if (ESLPage.startPressed) {
              String nextSentence = currentText;
              // remove punctuation from sentence
              String regex =
                  r'[^\p{Alphabetic}\p{Mark}\p{Decimal_Number}\p{Connector_Punctuation}\p{Join_Control}\s]+';
              String nextSentenceNoPunctuation =
                  nextSentence.replaceAll(RegExp(regex, unicode: true), '');
              ESLPage.sentenceQueue.add(nextSentenceNoPunctuation);
            }
          }
        }

        // ignore: prefer_interpolation_to_compose_strings
        responseText += '\n' + currentText;
        setState(() {
          text = responseText;
          recognizeFinished = true;
        });
      } else {
        setState(() {
          // ignore: prefer_interpolation_to_compose_strings
          text = responseText.trim() + '\n' + currentText;
          recognizeFinished = true;
        });
      }
    }, onDone: () {
      setState(() {
        TranscriptionPage.recognizing = false;
      });
    });

    if (TranscriptionPage.recognizing) {
      cp.info('Transcription initialization test passed.');
    } else {
      cp.info('Transcription initialization test failed.');
    }
  }

  void stopRecording() async {
    cp.info('Stopping transcription recording...');

    await _recorder.stopRecorder();
    await _audioStreamSubscription?.cancel();
    await _audioStream?.close();
    await _recordingDataSubscription?.cancel();
    setState(() {
      TranscriptionPage.recognizing = false;
    });

    if (!TranscriptionPage.recognizing) {
      cp.info('Stopping transcription recording test passed.');
    } else {
      cp.info('Stopping transcription recording test failed.');
    }
  }

  RecognitionConfig _getConfig() => RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: true,
      sampleRateHertz: 16000,
      languageCode: selectedLanguage);

  void clearTranscriptionText() {
    cp.info('Clearing transcription text...');
    setState(() {
      responseText = '';
      text = '';
    });
    if (text == '') {
      cp.info('Clearing transcription text test passed.');
    } else {
      cp.info('Clearing transcription text test failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   //title: const Text('Transcription'),
      //   //centerTitle: true,
      //   toolbarHeight: 0.0,
      //   systemOverlayStyle: SystemUiOverlayStyle.light,
      // ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                  margin: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple)),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      TranscriptionPage.emojisToDisplay.isEmpty
                          ? 'Listening for cues...'
                          : TranscriptionPage.emojisToDisplay,
                      style: TextStyle(
                          fontSize: TranscriptionPage.emojisToDisplay.isEmpty
                              ? 24
                              : 100),
                      textAlign: TextAlign.center,
                    ),
                  )),
            ),
            Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(20.0),
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepPurple)),
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                      reverse: true,
                      child: Text(
                          text.trim().isNotEmpty
                              ? text.trim()
                              : 'Transcription will appear here...',
                          textAlign: textAlign,
                          textDirection: textDirection,
                          style: const TextStyle(fontSize: 24.0))),
                )),
            Container(
              margin: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: clearTranscriptionText,
                      child: const Text('Clear',
                          style: TextStyle(color: Colors.deepPurple)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                        key: const Key('startStopButton'),
                        onPressed: () {
                          TranscriptionPage.recognizing
                              ? stopRecording()
                              : streamingRecognize();
                        },
                        child: Text(
                            TranscriptionPage.recognizing
                                ? 'Stop listening'
                                : 'Start listening',
                            style: const TextStyle(color: Colors.deepPurple))),
                    const SizedBox(width: 10),
                    DropdownButton(
                      value: dropdownValue,
                      icon:
                          const Icon(Icons.language, color: Colors.deepPurple),
                      iconSize: 20.0,
                      style: const TextStyle(color: Colors.deepPurple),
                      items: const [
                        DropdownMenuItem(
                            value: 'English', child: Text('English ')),
                        DropdownMenuItem(
                            value: 'Arabic', child: Text('Arabic')),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                        if (dropdownValue == 'Arabic') {
                          setState(() {
                            selectedLanguage = 'ar-AE';
                            textAlign = TextAlign.right;
                            textDirection = TextDirection.rtl;
                            ESLPage.validSignLang = true;
                          });
                          ESLPage.startPressed = false;
                          // Note: arabic language not supported for sign language translation
                        } else if (dropdownValue == 'English') {
                          setState(() {
                            selectedLanguage = 'en-US';
                            textAlign = TextAlign.left;
                            textDirection = TextDirection.ltr;
                            ESLPage.validSignLang = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
