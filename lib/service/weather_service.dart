import 'package:flutter/material.dart';

import '/global_variables.dart' as globals;
import 'shared_preferences_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/weather.dart';

class WeatherService {
  static final WeatherService _instance = WeatherService._internal();

  factory WeatherService() => _instance;

  Position? position;
  DateTime currentDate = DateTime.now();
  String weatherExpirationHour = DateTime(DateTime.now().year,
          DateTime.now().month, DateTime.now().day, DateTime.now().hour)
      .toString();
  Weather? currentWeather;
  String? currentWeatherMain;
  String? currentWeatherDescription;
  String? currentWeatherIcon;
  String currentWeatherIconURL = '';

  int? currentWeatherConditionCode;

  bool enableSpeedReminders = false;

  WeatherFactory weatherFactory =
      WeatherFactory("399618d96bfbe9447ec9a3f798c7ed00");

  WeatherService._internal();

  Future<void> getCurrentWeather() async {
    if (position == null) {
      try {
        currentWeather =
            await weatherFactory.currentWeatherByCityName("Hong Kong, HK");
      } catch (exception) {
        showSnackBar("$exception");
      }
    } else {
      try {
        currentWeather = await weatherFactory.currentWeatherByLocation(
            position!.latitude, position!.longitude);
      } catch (exception) {
        showSnackBar("$exception");
      }
    }
  }

  void extractWeatherConditionCode() {
    if (currentWeather == null) {
      currentWeatherConditionCode = -1;
      return;
    }
    currentWeatherConditionCode = currentWeather!.weatherConditionCode;
    SharedPreferencesService.setInt(
        'currentWeatherConditionCode', currentWeatherConditionCode ?? -1);
  }

  void extractWeatherDescription() {
    if (currentWeather == null) {
      currentWeatherMain = "Oops...";
      currentWeatherDescription = "No weather information yet :(";
      currentWeatherIcon = null;
      currentWeatherIconURL = "";
      return;
    }
    currentWeatherMain = currentWeather!.weatherMain;
    currentWeatherDescription = currentWeather!.weatherDescription;
    currentWeatherIcon = currentWeather!.weatherIcon;
    currentWeatherIconURL =
        "https://openweathermap.org/img/wn/$currentWeatherIcon@2x.png";
    SharedPreferencesService.setString(
        'currentWeatherMain', currentWeatherMain ?? "Oops...");
    SharedPreferencesService.setString('currentWeatherDescription',
        currentWeatherDescription ?? "No weather information yet :(");
    SharedPreferencesService.setString(
        'currentWeatherIconURL', currentWeatherIconURL);
  }

  void showSnackBar(String text) {
    var snackBar =
        SnackBar(content: Text(text), duration: const Duration(seconds: 2));
    globals.snackbarKey.currentState?.showSnackBar(snackBar);
  }
}
