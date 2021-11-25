import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/data/app_settings.dart';

class SettingsScreen extends StatefulWidget {
  SettingsScreen({Key? key, required AppData this.appData}) : super(key: key);
  AppData appData;


  @override
  _SettingsScreenState createState() => _SettingsScreenState(appData);
}

class _SettingsScreenState extends State<SettingsScreen> {
  _SettingsScreenState(AppData data) : appData = data {}

  bool isTextFieldValid = true;
  String errorText = "";
  AppData appData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text("Settings"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, appData),
          ),
      ),
      body: Padding(
          padding: EdgeInsets.all(30.0),
          child: Column(
                children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        Text("Metrum: ", textScaleFactor: 1.1,),
                        DropdownButton<int>(
                            value: appData.metrum,
                            onChanged: (int? value) => {
                              setState(() {
                                appData.metrum = value!;
                              })
                            },
                            items: <int>[3, 4].map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(value.toString()),
                              );
                            }).toList(),

                        ),
                        Text("/ 4", textScaleFactor: 1.1,)
                     ]
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Tacts to record: ", textScaleFactor: 1.1,),
                        DropdownButton<int>(
                          value: appData.numberOfTactsToRecord,
                          onChanged: (int? value) => {
                            setState(() {
                              appData.numberOfTactsToRecord = value!;
                            })
                          },
                          items: <int>[2, 3, 4].map<DropdownMenuItem<int>>((int? value) {
                            return DropdownMenuItem<int>(
                              value: value,
                              child: Text(value.toString()),
                            );
                          }).toList(),
                    ),
                  ],
                )
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("Tempo: ", textScaleFactor: 1.1,),
                        Flexible(
                            child: TextField(
                            onChanged: validateTextField,
                            keyboardType: TextInputType.number,
                            decoration:  InputDecoration(
                              errorText: isTextFieldValid ? null : errorText,
                              hintText: "Tempo in BPM",
                              labelText: "Current: ${appData.beatsPerMinute}"
                              ),
                            )
                        )
                      ],
                    )
                )
              ]
          )

      )
    );
  }

  void validateTextField(String? value){
    RegExp regExp = RegExp('^[0-9]+\$');
    setState(() {
      if(!regExp.hasMatch(value!))
      {
        isTextFieldValid = false;
        errorText = "Value should contain only numeric values";
      }
      else{
        final bpm = int.parse(value);
        if(bpm < 30 || bpm > 250) {
          isTextFieldValid = false;
          errorText = "Range should be between 30 and 250";
        }
        else {
          appData.beatsPerMinute = bpm;
          isTextFieldValid = true;
        }
      }
    });


  }

}
