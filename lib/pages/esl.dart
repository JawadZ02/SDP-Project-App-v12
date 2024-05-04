import 'package:flutter/material.dart';

import 'transcription.dart';

import 'dart:collection'; // needed for Queue

import 'package:media_kit/media_kit.dart'; // Provides [Player], [Media], [Playlist] etc.
import 'package:media_kit_video/media_kit_video.dart'; // Provides [VideoController] & [Video] etc.

import 'package:collection/collection.dart'; // needed for firstWhereOrNull()
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_colored_print/flutter_colored_print.dart' as cp;

class ESLPage extends StatefulWidget {
  const ESLPage({super.key});

  static bool startPressed = false;
  static bool validSignLang = false;
  static Queue<String> sentenceQueue = Queue();

  @override
  State<ESLPage> createState() => _ESLPageState();
}

class _ESLPageState extends State<ESLPage> {
  // Create a [Player] to control playback.
  late final player = Player();
  // Create a [VideoController] to handle video output from [Player].
  late final controller = VideoController(
    player,
    configuration: const VideoControllerConfiguration(
      vo: 'mediacodec_embed',
      hwdec: 'mediacodec',
    ),
  );

  bool currentlyPlaying = false;

  final csvFilePath = 'assets/arabic_metadata_14.csv';
  final videoDirectory = 'assets/sign_videos';
  late String csvData;
  late List<List<dynamic>> rows;
  late List<Map<dynamic, dynamic>> videosDf;
  late Playlist currentPlaylist;

  int currentPlaylistVideoIndex = 0;

  List<Widget> signLanguageLetters = [];
  String signLanguageWord = '';

  bool playlistCompleted = true;

  bool showSignVideo = true;

  String currentSentenceShown = '';

  Queue<String> wordsToSignLanguageLetters = Queue();

  String dropdownValue = 'Human';

  void refreshESC() async {
    while (true) {
      await Future.delayed(const Duration(milliseconds: 300), () {
        setState(() {});
      });
    }
  }

  void checkButtonStatus() async {
    while (true) {
      bool initial = ESLPage.validSignLang;
      await Future.delayed(const Duration(seconds: 1), () {
        if (ESLPage.validSignLang != initial) {
          setState(() {});
        }
      });
    }
  }

  void processSentenceQueue() async {
    // send the next sentence to be displayed once the current one finished
    while (true) {
      if (ESLPage.startPressed) {
        if (playlistCompleted && ESLPage.sentenceQueue.isNotEmpty) {
          cp.info('current queue: ${ESLPage.sentenceQueue}');
          String nextSentence = ESLPage.sentenceQueue.removeFirst();
          cp.info('removed from queue: $nextSentence');
          if (nextSentence.trim() != '') {
            playVideosForSentence(nextSentence);
            setState(() {
              currentSentenceShown = nextSentence;
            });
          }
        }
      } else {
        // if we are not displaying, then clear the queue (reset it)
        // since we dont want to continue processing the old phrases
        // when start displaying is pressed again
        ESLPage.sentenceQueue.clear();
      }

      // to provide some buffer in while true loop
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  @override
  void initState() {
    super.initState();
    cp.info('Initializing ESLPage state...');

    // Loading CSV file for video metadata
    loadCSV();

    // Below is used to keep track of the current playing video index in the playlist
    player.stream.completed.listen((event) {
      //print('COMPLETED: ${event}');
      if (event == true) {
        // here one video is completed
        currentPlaylistVideoIndex++;
        cp.info('current playlist index changed to: $currentPlaylistVideoIndex');

        // if we are currently on the last video and it got completed
        // this means we finished the playlist
        if (currentPlaylistVideoIndex == currentPlaylist.medias.length) {
          // setState(() {
          //   playlistCompleted = true;
          // });
          playlistCompleted = true;
          currentPlaylistVideoIndex = 0;
          cp.info('current playlist index reset to: $currentPlaylistVideoIndex');
        } else {
          // setState(() {
          //   playlistCompleted = false;
          // });
          playlistCompleted = false;
        }

        // setState(() {
        //   currentPlaylistVideoIndex =
        //       (currentPlaylistVideoIndex + 1) % currentPlaylist.medias.length;
        // });
      }
    });

    // Speeding up video playback!!!!!!!!!!!!!!
    player.setRate(2.0);

    refreshESC();

    processSentenceQueue();

    //checkButtonStatus();

    cp.info('ESLPage state initialization test passed.');
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  void loadCSV() async {
    csvData = await rootBundle.loadString(csvFilePath);
    rows = const CsvToListConverter().convert(csvData);
    videosDf = rows.map((row) => Map.fromIterables(rows[0], row)).toList();
  }

  void generateSignLanguageLetters(String word) {
    cp.info('Generating sign language letters for $word...');
    signLanguageLetters = word.split('').map((letter) {
      return Expanded(child: Image.asset('assets/alphabet_images/$letter.png'));
    }).toList();
    signLanguageWord = word;
    setState(() {}); // Update the UI
    cp.info(
        'Generated sign language letters for $signLanguageWord successfully.');
  }

  void playVideosForSentence(String inputSentence) async {
    cp.info('Finding videos for sentence: $inputSentence...');
    List<String> wordOrPhraseVideosFound = [];

    List<String> words = inputSentence.split(' ');
    int maxPhraseLen = 5; // Adjust based on your dataset's longest phrase
    Set<int> skippedWords =
        {}; // To track words that are part of a matched longer phrase

    List<Media> videosToPlay = [];

    List<int> blackScreenIndexes = [];
    //Queue<String> wordsToSignLanguageLetters = Queue();
    wordsToSignLanguageLetters.clear();

    int playlistIndex = 0;

    int i = 0;
    while (i < words.length) {
      bool matched = false;
      // Iterate backwards from the longest possible phrase to single words
      for (int j = maxPhraseLen; j > 0; j--) {
        if (i + j <= words.length) {
          String phrase = words.sublist(i, i + j).join(' ');
          final videoEntry = videosDf
              .firstWhereOrNull((entry) => entry['phrase'] == phrase.trim());
          if (videoEntry != null) {
            // Play video for the phrase
            String fileName = videoEntry['file_name'];
            String videoFilePath = 'asset:///$videoDirectory/$fileName';
            cp.info('Playing video for phrase: \'$phrase\' -> $videoFilePath');

            videosToPlay.add(Media(videoFilePath));
            playlistIndex++;

            wordOrPhraseVideosFound.add(phrase);

            // Skip words that are part of this phrase
            for (int k = i + 1; k < i + j; k++) {
              skippedWords.add(k);
            }
            i += j - 1; // Move index past the end of the matched phrase
            matched = true;
            break;
          }
        }
      }
      if (!matched && !skippedWords.contains(i)) {
        // If it's a single word not part of any matched longer phrase or word
        String word = words[i];
        cp.info(
            'No video found for word: \'$word\', attempting finger spelling.');

        //playVideosForLetters(word, videosToPlay);

        // instead of adding the letter videos to the playlist,
        // we add a 2 second black video to the playlist
        videosToPlay.add(Media('asset:///assets/black_screen_2s.mp4'));
        // during this 1 second duration, we display the letters on the screen
        blackScreenIndexes.add(playlistIndex);
        playlistIndex++;
        wordsToSignLanguageLetters.add(word);

        wordOrPhraseVideosFound.add(word);
      }
      i++;
    }

    // Play all videos
    currentPlaylist = Playlist(videosToPlay);
    cp.info('blackScreenIndexes: $blackScreenIndexes');
    cp.info('wordsToSignLanguageLetters: $wordsToSignLanguageLetters');
    playAllVideos(blackScreenIndexes, wordsToSignLanguageLetters);

    cp.info(
        'Found videos successfully for phrases/words: $wordOrPhraseVideosFound');
  }

  Future<void> playAllVideos(List<int> blackScreenIndexes,
      Queue<String> wordsToSignLanguageLetters) async {
    cp.info(
        'Displaying videos for all phrases/words/letters starting with video index: $currentPlaylistVideoIndex...');
    // here we play the playlist
    // but for each black screen index that it reaches, we generate the sign language letters

    // begin playing the playlist
    player.open(currentPlaylist);

    // while the playlist is still playing its videos i.e. has not reached end of playlist
    // which is while the video index didnt reach the last video index or
    // it is the last video index and currentlyPlaying == true

    // ORRRR while we have not displayed all black screens yet
    // (since the purpose of the loop is to display the black screens only)
    // (the videos will play till the end regardless of this loop)

    // while ((currentPlaylistVideoIndex < currentPlaylist.medias.length - 1) ||
    //     (currentlyPlaying)) {
    //while (!playlistCompleted) {
    while (blackScreenIndexes.isNotEmpty) {
      //cp.info(
      //    'current playlist index inside while: $currentPlaylistVideoIndex');

      if (blackScreenIndexes.contains(currentPlaylistVideoIndex)) {
        // remove index from blackscreenindexes to mark as completed
        blackScreenIndexes.remove(currentPlaylistVideoIndex);
        // stop displaying sign video widget, display only sign word
        setState(() {
          showSignVideo = false;
        });
        cp.info(
            'showing sign word at playlist index: $currentPlaylistVideoIndex');
        // display the first sign word in the queue (and remove it)
        generateSignLanguageLetters(wordsToSignLanguageLetters.removeFirst());
        // wait for 1 seconds (for 2 second black screen with sign word shown)
        await Future.delayed(const Duration(seconds: 1));

        // stop showing sign word, show sign video
        setState(() {
          showSignVideo = true;
        });

        // reset the sign word to empty string (to stop showing the sign word)
        signLanguageWord = '';
        signLanguageLetters.clear();
        setState(() {}); // update the UI

        // if blackscreenindexes is empty, then there are no more sign words to display
        // so we can stop looping
      }

      // small delay to allow program to run
      await Future.delayed(const Duration(milliseconds: 100));
    }

    cp.info(
        'All videos displayed successfully, with ending video index: $currentPlaylistVideoIndex');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.deepPurple)),
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Visibility(
                      visible: showSignVideo,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                        child: Video(
                            controller:
                                controller), // , fill: Colors.grey // default is black if no vid playing
                      ),
                    ),
                    Visibility(
                      visible: !showSignVideo,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width * 9.0 / 16.0,
                        decoration: const BoxDecoration(color: Colors.black),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),
                            Expanded(
                              flex: 5,
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Row(
                                  children: signLanguageLetters,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Expanded(
                              flex: 5,
                              child: Text(
                                signLanguageWord,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                    fontSize: 30.0, color: Colors.white),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      currentSentenceShown,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 20.0),
                    ),
                  ],
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: ESLPage.validSignLang &&
                            TranscriptionPage.recognizing
                        ? () {
                            // clear previous phrase(s)
                            if (ESLPage.startPressed) {
                              ESLPage.sentenceQueue.clear();
                              player.stop();
                              setState(() {
                                currentSentenceShown = '';
                                currentPlaylistVideoIndex = 0;
                                playlistCompleted = true;
                              });
                            }

                            setState(() {
                              ESLPage.startPressed =
                                  ESLPage.startPressed ? false : true;
                            });
                          }
                        : null, // button disabled if unsupported sign language
                    child: Text(
                        ESLPage.startPressed
                            ? 'Stop displaying'
                            : 'Start displaying',
                        style: const TextStyle(color: Colors.deepPurple)),
                  ),
                  const SizedBox(width: 10),
                    DropdownButton(
                      value: dropdownValue,
                      icon:
                          const Icon(Icons.person, color: Colors.deepPurple),
                      iconSize: 20.0,
                      style: const TextStyle(color: Colors.deepPurple),
                      items: const [
                        DropdownMenuItem(
                            value: 'Human', child: Text('Human ')),
                        DropdownMenuItem(
                            value: 'Avatar', child: Text('Avatar ')),
                      ],
                      onChanged: (newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });

                        // put logic here for using human or avatar videos

                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () async {
      //     String inputSentence = 'يلعب الطفل بالمنزل';
      //     playVideosForSentence(inputSentence);

      //     await Future.delayed(const Duration(seconds: 6), () {
      //       inputSentence = 'السلام عليكم';
      //       playVideosForSentence(inputSentence);
      //     });

      //     await Future.delayed(const Duration(seconds: 3), () {
      //       inputSentence =
      //           'هو يلعب الرياضة في الحديقة الهيئة العامة لرعاية الشباب والرياضة وزاره الصحه ووقايه المجتمع';
      //       playVideosForSentence(inputSentence);
      //     });
      //   },
      //   child: const Icon(Icons.play_arrow),
      // ),
    );
  }
}
