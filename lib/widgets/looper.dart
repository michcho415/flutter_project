
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/data/app_settings.dart';
import 'package:flutter_project/widgets/custom_button.dart';
import 'dart:async';
import 'package:microphone/microphone.dart';

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

  late LooperState state;
  bool isRecordButtonVisible = true;
  bool isStopButtonVisible = false;
  bool isPlayButtonVisible = false;



  @override
  void initState() {
    state = LooperState.Stopped;
    super.initState();
  }

  @override
  void dispose() {
    //preRecordTimer?.cancel();
    //recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomButton(isRecordButtonVisible, Icons.circle, 16, startRecording, Colors.red),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: CustomButton(isStopButtonVisible, Icons.stop, 32, startRecording, Colors.white70))
                
              ],
            )


        ],
        );

  }

  void startRecording() {
    setState(() {
      state = LooperState.Recording;
    });
  }

}
