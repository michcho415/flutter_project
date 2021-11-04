

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/data/app_settings.dart';
import 'package:flutter_project/widgets/custom_button.dart';
import 'dart:async';
import 'dart:math';
import 'package:microphone/microphone.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers_api.dart';


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

  //final microphoneRecorder = MicrophoneRecorder().init();

  AudioPlayer audioPlayer = AudioPlayer(mode: PlayerMode.LOW_LATENCY);
  AudioCache? audioCache;
  late LooperState state;
  bool isRecordButtonVisible = true;
  bool isStopButtonVisible = false;
  bool isPlayButtonVisible = false;
  late int tactDuration = 0;
  late int beatDuration = 0;
  late int oneTickDuration = 0;
  Timer? startCounting;
  Timer? metronomeLoop;
  String path = 'met.mp3';
  int counter = 1;


  @override
  void initState() {
    state = LooperState.Stopped;
    initTempoSetup();

    audioCache = AudioCache(fixedPlayer: audioPlayer);
    super.initState();
  }

  @override
  void dispose() {
    //preRecordTimer?.cancel();
    //recordingTimer?.cancel();

    audioPlayer.release();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(child: Text(counter.toString(), textScaleFactor: 1.3,)),
            Padding( padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(isRecordButtonVisible, Icons.circle, 16, preRecording, Colors.red),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: CustomButton(isStopButtonVisible, Icons.stop, 32, stopRecording, Colors.white70))
                
              ],
            )
            )


        ],
        );

  }

  void preRecording() {
    setState(() {
      initTempoSetup();
      isRecordButtonVisible = false;
      isStopButtonVisible = true;
      counter = 0;
      state = LooperState.Recording;
      startCounting = new Timer(Duration(milliseconds: tactDuration), startRecording);
      metronomeLoop = new Timer.periodic(Duration(milliseconds: oneTickDuration), onTick);
      audioCache!.play(path);
      counter += 1;
      //microphoneRecorder.start();
    });
  }

  void initTempoSetup()
  {
    setState(() {
      oneTickDuration = (1000 * 60 / widget.appData.beatsPerMinute).toInt();
      tactDuration = (tactDuration * widget.appData.metrum).toInt();
      beatDuration = (widget.appData.numberOfTactsToRecord * tactDuration).toInt(); // in ms
    });
  }

  void onTick(Timer t) {
    audioCache!.play(path);
    setState(() {
      counter += 1;
      if(counter == widget.appData.metrum + 1)
        counter = 1;
    });

  }

  void startRecording(){
    setState(() {

    });
  }

  void stopRecording()
  {
    setState(() {
      metronomeLoop?.cancel();
      startCounting?.cancel();
      isRecordButtonVisible = true;
    });
  }

}
