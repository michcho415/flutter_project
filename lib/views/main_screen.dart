import 'package:flutter/material.dart';
import 'package:flutter_project/data/app_settings.dart';
import 'package:flutter_project/views/settings_screen.dart';

class MainScreen extends StatefulWidget
{
  const MainScreen({Key? key}) : super(key: key);


  @override
  State<StatefulWidget> createState() => _MainScreenState();

}



class _MainScreenState extends State<MainScreen>{

  AppData data = AppData(4, beatsPerMinute: 60, numberOfTactsToRecord: 2);

  @override
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Looper"),
          leading: IconButton(
            icon: Icon(Icons.settings),
            onPressed: getDataFromSettings
            ),
          ),
        body: Container(
          child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
            children: [Text("Beats per minute: ${data.getBeats()} \nTacts: ${data.getTacts()}")]
            )
          )
        ),
      );

  }

  Future<void> getDataFromSettings() async {
     final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(appData: data)));

     setState(() {
       data = result;
     });
  }

}

