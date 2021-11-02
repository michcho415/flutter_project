import 'package:flutter/material.dart';

class AppData
{
  AppData(int this.metrum, {required int this.beatsPerMinute, required int this.numberOfTactsToRecord});

  int beatsPerMinute;
  int numberOfTactsToRecord;
  int metrum = 4;

}