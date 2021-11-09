

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


enum LooperState{
  Stopped,
  Playing,
  Recording,
  Recorded
}

class Looper extends StatefulWidget {
  const Looper({Key? key, required AppData this.appData}) : super(key: key);

  final AppData appData;

  @override
  _LooperState createState() => _LooperState();
}

class _LooperState extends State<Looper> {

  //final microphoneRecorder = MicrophoneRecorder()..init();
  FlutterSoundRecorder flutterRecorder = FlutterSoundRecorder();
  FlutterSoundPlayer flutterPlayer = FlutterSoundPlayer();

  AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  AudioPlayer looperPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  AudioCache? audioCache;
  AudioCache? looperAudioCache;

  final recorder = Record();

  late LooperState state;
  bool isRecordButtonVisible = true;
  bool isStopButtonVisible = false;
  bool isPlayButtonVisible = false;

  late int tactDuration = 0;
  late int beatDuration = 0;
  late int oneTickDuration = 0;

  Timer? startCounting;
  Timer? metronomeLoop;
  Timer? recordTimer;
  Timer? playingTimer;

  String recordingStateString = "";
  String path = 'met.mp3';
  String recordedPath = 'recording.aac';

  int counter = 1;


  @override
  void initState() {
    state = LooperState.Stopped;
    initTempoSetup();

    super.initState();

    audioCache = AudioCache(fixedPlayer: audioPlayer);
    looperAudioCache = AudioCache(fixedPlayer: looperPlayer);

    flutterRecorder.openAudioSession(
      focus: AudioFocus.requestFocusAndStopOthers,
      mode: SessionMode.modeDefault,
      device: AudioDevice.speaker,
      category: SessionCategory.record,
    );

    flutterPlayer.openAudioSession(
      focus: AudioFocus.requestFocusAndStopOthers,
      mode: SessionMode.modeDefault,
      device: AudioDevice.speaker,
      category: SessionCategory.playback
    );

  }

  @override
  void dispose() {
    audioPlayer.release();
    audioPlayer.dispose();

    looperPlayer.release();
    looperPlayer.dispose();

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
            padding: EdgeInsets.symmetric(vertical: 25),
            child: Center(child: Text(recordingStateString.toString(), textScaleFactor: 1.3,))),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                      CustomButton(isRecordButtonVisible, Icons.circle, 16, preRecording, Colors.red),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.0),
                        child: CustomButton(isStopButtonVisible, Icons.stop, 32, stopRecording, Colors.white70)
                      ),
                  ],
                )
            )
        ],
    );

  }

  Future<void> askForPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> preRecording() async {
    await askForPermissions();
    var tempDir = await getTemporaryDirectory();
    recordedPath = '${tempDir.path}/recording.aac';
    startCounting = new Timer(Duration(milliseconds: 2*tactDuration), startRecording);
    metronomeLoop = new Timer.periodic(Duration(milliseconds: oneTickDuration), onTick);
    audioCache!.play(path);

    setState(() {
      initTempoSetup();
      isRecordButtonVisible = false;
      isStopButtonVisible = true;
      counter = 0;
      state = LooperState.Recording;
      recordingStateString = "Recording will start in 2 tacts after start.";
      counter += 1;
    });
  }

  void initTempoSetup()
  {
    setState(() {
      oneTickDuration = (1000 * 60 / widget.appData.beatsPerMinute).toInt();
      tactDuration = (oneTickDuration * widget.appData.metrum).toInt();
      beatDuration = (widget.appData.numberOfTactsToRecord * tactDuration).toInt(); // in ms
    });
  }

  Future<void> onTick(Timer t) async {
    await audioCache!.play(path);
    setState(() {
      counter += 1;
      if(counter == widget.appData.metrum + 1)
        counter = 1;
    });

  }

  Future<void> startRecording() async {
    recordTimer = new Timer(Duration(milliseconds: beatDuration), Recorded);
    flutterRecorder.startRecorder(toFile: 'foo.aac', sampleRate: 44100, codec: Codec.aacADTS);
    setState((){
      startCounting?.cancel();
      state = LooperState.Recording;
      recordingStateString = "Recording.";
      /*recorder.start(
        path: 'myFile.m4a', // required
        encoder: AudioEncoder.AAC, // by default
        bitRate: 128000, // by default
        samplingRate: 44100, // by default
      );*/
      //microphoneRecorder.start();


    });
  }

  Future<void> Playing(Timer t) async{

    await flutterPlayer.startPlayer(
        fromURI: 'foo.aac',
        codec: Codec.aacADTS,
        whenFinished: () { setState((){}); }
    );

  }

  Future<void> stopRecording() async {
    await flutterRecorder.stopRecorder();
    await flutterPlayer.stopPlayer();
    playingTimer?.cancel();
    setState(() {
      metronomeLoop?.cancel();
      startCounting?.cancel();
      isRecordButtonVisible = true;
      isStopButtonVisible = false;
      recordingStateString = "stopped.";
    });
  }

  Future<void> Recorded() async
  {
    await flutterRecorder.stopRecorder();
    await flutterPlayer.startPlayer(
        fromURI: 'foo.aac',
        codec: Codec.aacADTS,
        whenFinished: () { setState((){}); }
    );
    playingTimer = Timer.periodic(Duration(milliseconds: beatDuration), Playing);

    setState(() {
      metronomeLoop?.cancel();
      startCounting?.cancel();
      isStopButtonVisible = true;
      isRecordButtonVisible = false;
      recordingStateString = "Playing loop.";
    });
  }

}
