

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/data/app_settings.dart';
import 'package:flutter_project/widgets/custom_button.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers_api.dart';
import 'package:record/record.dart';
import 'package:microphone/microphone.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:flutter_sound_lite/public/flutter_sound_recorder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


enum LooperState{
  Stopped,
  Playing,
  PreRecording,
  Recording,
  Recorded
}

class Looper extends StatefulWidget {
  const Looper({Key? key, required this.appData}) : super(key: key);

  final AppData appData;

  @override
  _LooperState createState() => _LooperState();
}

class _LooperState extends State<Looper> {

  FlutterSoundRecorder flutterRecorder = FlutterSoundRecorder();
  FlutterSoundPlayer flutterPlayer = FlutterSoundPlayer();

  AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
  AudioPlayer metronomePlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  AudioCache? audioCache;
  AudioCache? metronomeAudioCache;

  late LooperState state;
  bool isRecordButtonVisible = true;
  bool isStopButtonVisible = false;
  bool isPlayButtonVisible = false;

  late int tactDuration = 0;
  late int beatDuration = 0;
  late int oneTickDuration = 0;

  Timer? startCounting;
  Timer? startCounting2;
  Timer? metronomeLoop;
  Timer? recordTimer;
  Timer? playingTimer;

  String recordingStateString = "";

  Directory? saveDirectory;
  final String path = './met.mp3';
  String recordedPath = 'recording.aac';
  String recordingFilename = "recording.aac";
  late File metronomeSound;
  int counter = 1;


  @override
  void initState() {
    state = LooperState.Stopped;
    initTempoSetup();

    super.initState();

    audioCache = AudioCache(fixedPlayer: audioPlayer);
    metronomeAudioCache = AudioCache(fixedPlayer: metronomePlayer);

    setTempDirForMet();
    setSaveDirectory();

    flutterRecorder.openAudioSession(
      focus: AudioFocus.requestFocusAndStopOthers,
      mode: SessionMode.modeDefault,
      device: AudioDevice.speaker,
      category: SessionCategory.record,
    );

    flutterPlayer.openAudioSession(
      focus: AudioFocus.requestFocusAndStopOthers,
      mode: SessionMode.modeMeasurement,
      device: AudioDevice.speaker,
      category: SessionCategory.playback
    );

    audioPlayer.setReleaseMode(ReleaseMode.STOP);

  }

  @override
  void dispose() {
    audioPlayer.release();
    audioPlayer.dispose();

    metronomePlayer.release();
    metronomePlayer.dispose();

    flutterRecorder.closeAudioSession();
    flutterPlayer.closeAudioSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text(counter.toString(), textScaleFactor: 1.3,)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25),
            child: Center(child: Text(recordingStateString.toString(), textScaleFactor: 1.3,))),
            Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      CustomButton(isRecordButtonVisible, Icons.circle, 16, preRecording, Colors.red),
                      CustomButton(isStopButtonVisible, Icons.stop, 32, stopRecording, Colors.white70)

                  ],
                )

        ],
    );

  }

  Future<void> setTempDirForMet() async {
    var tempDir =  await getTemporaryDirectory();
    metronomeSound = File('${tempDir.path}/met.mp3');
    ByteData bytes = await rootBundle.load('assets/met.mp3');
    metronomeSound.writeAsBytes((bytes).buffer.asInt8List());
  }

  Future<void> setSaveDirectory() async {
    saveDirectory = await getExternalStorageDirectory();
  }

  Future<void> askForPermissions() async {
    if( await Permission.storage.isDenied
        || await Permission.microphone.isDenied
        || await Permission.manageExternalStorage.isDenied)
      {
        await Permission.microphone.request();
        await Permission.storage.request();
        await Permission.manageExternalStorage.request();
      }
  }

  Future<void> preRecording() async {
    await askForPermissions();
    await initTempoSetup();
    await _displayTextInputDialog(context);
    startCounting =  Timer(Duration(milliseconds: 2*tactDuration), recording);
    startCounting2 = Timer(Duration(milliseconds: 2*tactDuration-300), startRecording);
    metronomeLoop = Timer.periodic(Duration(milliseconds: oneTickDuration), onTick);
    await metronomePlayer.play(metronomeSound.path, isLocal: true);

    setState(() {
      isRecordButtonVisible = false;
      isStopButtonVisible = true;
      counter = 0;
      state = LooperState.PreRecording;
      recordingStateString = "Recording will start in 2 tacts after start.";
      counter += 1;
    });
  }

  Future<void> initTempoSetup() async
  {
    oneTickDuration = (1000 * 60 / widget.appData.beatsPerMinute).toInt();
    tactDuration = (oneTickDuration * widget.appData.metrum).toInt();
    beatDuration = (widget.appData.numberOfTactsToRecord * tactDuration).toInt(); // in ms
  }

  Future<void> onTick(Timer t) async {
    await metronomePlayer.play(metronomeSound.path, isLocal: true);
    setState(() {
      counter += 1;
      if(counter == widget.appData.metrum + 1) {
        counter = 1;
      }
    });

  }

  Future<void> startRecording() async {
    String savePath = saveDirectory!.path + '/' + recordingFilename;
    //await flutterRecorder.startRecorder(toFile: savePath, sampleRate: 44100, bitRate: 256000, codec: Codec.aacADTS);
    startCounting2?.cancel();
  }

  Future<void> recording() async {
    String savePath = saveDirectory!.path + '/' + recordingFilename;
    await flutterRecorder.startRecorder(toFile: savePath, sampleRate: 44100, bitRate: 256000, codec: Codec.aacADTS);
    recordTimer = Timer(Duration(milliseconds: beatDuration), recorded);
    setState((){
      startCounting?.cancel();
      state = LooperState.Recording;
      recordingStateString = "Recording.";
    });
  }

  Future<void> playing(Timer t) async{
    await audioPlayer.stop();
    await audioPlayer.play(
        recordedPath,
        isLocal: true,
    );
  }

  Future<void> stopRecording() async {
    await flutterRecorder.stopRecorder();
    await metronomePlayer.stop();
    await audioPlayer.stop();
    metronomeLoop?.cancel();
    startCounting2?.cancel();
    startCounting?.cancel();
    recordTimer?.cancel();
    playingTimer?.cancel();
    state = LooperState.Stopped;
    setState(() {
      isRecordButtonVisible = true;
      isStopButtonVisible = false;
      recordingStateString = "stopped.";
    });
  }

  Future<void> recorded() async
  {
    recordedPath = (await flutterRecorder.stopRecorder())!;
    metronomeLoop?.cancel();
    startCounting?.cancel();
    startCounting2?.cancel();
    state = LooperState.Playing;
    await audioPlayer.setUrl(recordedPath, isLocal: true);
    playingTimer = Timer.periodic(Duration(milliseconds: beatDuration), playing);
    setState(() {
      isStopButtonVisible = true;
      isRecordButtonVisible = false;
      recordingStateString = "Playing loop.";
    });
  }

  Future<void> _displayTextInputDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Recording name'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  recordingFilename = value;
                  recordingFilename += '.aac';
                });
              },
              decoration: const InputDecoration(hintText: "Provide record name"),
            ),
            actions: <Widget>[
              ElevatedButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                ),
                child: const Text('OK'),
                onPressed: () {
                  setState(() {
                    Navigator.pop(context);
                  });
                },
              ),
            ],
          );
        });
  }

}
