
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_project/data/app_settings.dart';
import 'package:flutter_project/widgets/audio_player.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

class PlayerScreen extends StatefulWidget {
  PlayerScreen(this.appData, {Key? key}) : super(key: key) {}

  AppData appData;

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {

  late String audioFilePath = "";
  late String audioFilePathText = "";
  Directory? filesDirectory;
  List<FileSystemEntity> files = [];
  List<String> fileNames = [];

  @override
  void initState() {
    getFilesWithSpecifiedType();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Player"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            children: [
              Text("Current file: $audioFilePathText", style: const TextStyle(fontSize: 20)),
              Flexible(
                  flex: 1,
                  child: Player(widget.appData, audioFilePath)
              ),
              Flexible(
                flex: 3,
                child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child:FutureBuilder(
                        future: _inFutureList(),
                        builder: (BuildContext context, AsyncSnapshot snapshot) {
                          if(snapshot.connectionState == ConnectionState.waiting){
                            return const Text('Data is loading...');
                          }
                          else{
                            return customBuild(context, snapshot);
                          }
                        }
                    )
                )
              )
            ],
          )
      ),
    );
  }

  Widget customBuild(BuildContext context, AsyncSnapshot snapshot){
    List<FileSystemEntity> values = snapshot.data;
    return  Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all()
            ),
            child: Scrollbar(
              child: ListView.builder(
                  itemCount: fileNames.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => {
                        changeRecording(index)
                      },
                      child: Card(child: ListTile(
                        title: Text(fileNames[index].toString()),
                      )),
                    );
                  }
              ),
            ),
          ),
        )
    ;
  }

  Future<List<FileSystemEntity>>_inFutureList() async{
    List<FileSystemEntity> filesList;
    filesDirectory = await getExternalStorageDirectory();
    filesList = files = io.Directory(filesDirectory!.path).listSync();
    getFilesWithSpecifiedType();
    await Future.delayed(const Duration(milliseconds: 800));
    return filesList;
  }

  void getFilesWithSpecifiedType() async {

    RegExp regExp = RegExp('.+\.aac\$');
    fileNames.clear();
    for (var element in files) {
      if(regExp.hasMatch(element.path))
        {
          var filename = element.path.substring(filesDirectory!.path.length + 1);
          fileNames.add(filename);
          audioFilePathText = filename;
        }
    }

  }

  void changeRecording(int index)
  {
    setState(() {
      audioFilePath = filesDirectory!.path + '/' + fileNames[index];
      audioFilePathText = fileNames[index];
    });
  }
}

