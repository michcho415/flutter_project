

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
  AudioPlayer metronomePlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  AudioCache? audioCache;
  AudioCache? metronomeAudioCache;

  final recorder = Record();

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
  final String path = './met.mp3';
  String recordedPath = 'recording.aac';
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




    flutterRecorder.openAudioSession(
      focus: AudioFocus.requestFocusAndStopOthers,
      mode: SessionMode.modeMeasurement,
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
    getTempDir();

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
            padding: EdgeInsets.symmetric(vertical: 25),
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
    metronomeSound = new File('${tempDir.path}/met.mp3');
    ByteData bytes = await rootBundle.load('assets/met.mp3');
    metronomeSound.writeAsBytes((bytes).buffer.asInt8List());
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

  Future<void> getTempDir() async{
    var tempDir = await getTemporaryDirectory();
    recordedPath = '${tempDir.path}/recording.aac';
  }

  Future<void> preRecording() async {
    await askForPermissions();
    await initTempoSetup();
    final iable = await metronomeAudioCache?.load(path);
    startCounting =  Timer(Duration(milliseconds: 2*tactDuration), Recording);
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
    setState(() {
      oneTickDuration = (1000 * 60 / widget.appData.beatsPerMinute).toInt();
      tactDuration = (oneTickDuration * widget.appData.metrum).toInt();
      beatDuration = (widget.appData.numberOfTactsToRecord * tactDuration).toInt(); // in ms
    });
  }

  Future<void> onTick(Timer t) async {
    await metronomePlayer.play(metronomeSound.path, isLocal: true);
    setState(() {
      counter += 1;
      if(counter == widget.appData.metrum + 1)
        counter = 1;
    });

  }

  Future<void> startRecording() async {
    await flutterRecorder.startRecorder(toFile: 'foo.aac', sampleRate: 44100, bitRate: 256000, codec: Codec.aacADTS);
    startCounting2?.cancel();
  }

  Future<void> Recording() async {
    //await flutterRecorder.startRecorder(toFile: 'foo.aac', sampleRate: 44100, bitRate: 256000, codec: Codec.aacADTS);
    //await flutterRecorder.startRecorder(toFile: 'foo.aac', sampleRate: 44100, bitRate: 256000, codec: Codec.aacADTS);
    recordTimer = Timer(Duration(milliseconds: beatDuration), Recorded);
    setState((){
      startCounting?.cancel();
      state = LooperState.Recording;
      recordingStateString = "Recording.";
    });
  }

  Future<void> Playing(Timer t) async{
    //await audioPlayer.stop();
    //await audioPlayer.seek(Duration(milliseconds: 300));
    await audioPlayer.play(
        recordedPath,
        isLocal: true,
    );
    //await audioPlayer.resume();
  }

  Future<void> stopRecording() async {
    await flutterRecorder.stopRecorder();
    await metronomePlayer.stop();
    await audioPlayer.stop();
    //await audioPlayer.release();
    //final dir = File(recordedPath);
    //dir.delete();
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

  Future<void> Recorded() async
  {
    recordedPath = (await flutterRecorder.stopRecorder())!;
    //await audioPlayer.seek(Duration(milliseconds: 297));
    /*await audioPlayer.play(
      recordedPath,
      isLocal: true,
    );*/
    metronomeLoop?.cancel();
    startCounting?.cancel();
    startCounting2?.cancel();
    state = LooperState.Playing;
    //audioPlayer.setUrl(recordedPath, isLocal: true);
    playingTimer = Timer.periodic(Duration(milliseconds: beatDuration), Playing);
    setState(() {
      isStopButtonVisible = true;
      isRecordButtonVisible = false;
      recordingStateString = "Playing loop.";
    });
  }

}
