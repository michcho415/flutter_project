import 'package:flutter/material.dart';
import 'package:flutter_project/data/app_settings.dart';
import 'package:flutter_project/widgets/custom_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

class Player extends StatefulWidget {
  Player(this.appData, this.audioFilePath, {Key? key}) : super(key: key);

  AppData appData;
  String audioFilePath = "";

  @override
  _PlayerState createState() => _PlayerState();

}

class _PlayerState extends State<Player> {

  AudioPlayer audioPlayer = AudioPlayer(mode:PlayerMode.MEDIA_PLAYER);
  AudioCache? audioCache;


  bool isPlayButtonVisible = true;
  bool isStopButtonVisible = false;

  @override
  void initState() {
    audioCache = AudioCache(fixedPlayer: audioPlayer);
    audioPlayer.setReleaseMode(ReleaseMode.LOOP);
    super.initState();
  }

  @override
  void dispose() {

    audioPlayer.release();
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(flex: 1, child: CustomButton(isPlayButtonVisible, Icons.play_arrow, 32.0, onPlay, Colors.grey)),
              Flexible(flex: 1, child: CustomButton(isStopButtonVisible, Icons.stop, 32.0, onStop, Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Future<void> onPlay() async {

    var result = widget.audioFilePath.isEmpty;
    if (widget.audioFilePath.isEmpty == true)
    {
      showDialog(
          context: context,
          builder: (context) {
          return const AlertDialog(title: Text("No audio file found!") );
      });

    }
    else {
      await audioPlayer.setUrl(widget.audioFilePath, isLocal: true);
      await audioPlayer.play(widget.audioFilePath, isLocal: true);

      setState(() {
        isStopButtonVisible = true;
        isPlayButtonVisible = false;
      });

    }
  }

  Future<void> onStop() async{
    await audioPlayer.stop();
    await audioPlayer.release();
    setState(() {
      isStopButtonVisible = false;
      isPlayButtonVisible = true;
    });
  }

  void setAudioPath(String audioPath)
  {
    setState(() {
      widget.audioFilePath = audioPath;
    });
  }

}
