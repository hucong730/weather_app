// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Weather';

  @override
  String get searchPrompt => 'Search for a city to see its weather';

  @override
  String get searchHint => 'Enter a city name';

  @override
  String get searchButton => 'Search';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get settings => 'Settings';

  @override
  String get cityManagement => 'Manage cities';

  @override
  String get cityManagementHint => 'Delete or reorder added cities';

  @override
  String get noSavedCities => 'No added cities';

  @override
  String get noSavedCitiesHint =>
      'Search and add a city from the home page first.';

  @override
  String deleteCity(String city) {
    return 'Delete $city';
  }

  @override
  String reorderCity(String city) {
    return 'Drag to reorder $city';
  }

  @override
  String get locationPrompt =>
      'Unable to get your current position. Check Location Services and location permission, then retry, or search for a city.';

  @override
  String get cachedLocationWarning =>
      'Current location is unavailable. Showing saved weather.';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get followSystem => 'Follow system';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get locationPermission => 'Location permission';

  @override
  String get permissionSystemHint =>
      'Changes are confirmed by the operating system. Turning permission off opens App Settings.';

  @override
  String get aboutApp => 'About this app';

  @override
  String get appDescription =>
      'A Flutter weather app with current conditions, hourly and daily forecasts, and multiple cities.';

  @override
  String get dataSources => 'Data sources';

  @override
  String get iconSource =>
      'Weather icons: QWeather Icons (MIT License)\nhttps://github.com/qwd/Icons';

  @override
  String get invalidQuery =>
      'Enter a city name without postcodes or coordinates';

  @override
  String get noResults => 'No matching cities';

  @override
  String get locating => 'Finding your location…';

  @override
  String get loading => 'Loading weather…';

  @override
  String get currentLocation => 'Current location';

  @override
  String currentLocationPage(int index, int count) {
    return 'Current location, page $index of $count';
  }

  @override
  String cityPage(int index, int count) {
    return 'City, page $index of $count';
  }

  @override
  String get hourlyForecast => '24-hour forecast';

  @override
  String get dailyForecast => '7-day forecast';

  @override
  String dailyForecastToday(String date) {
    return 'Today, $date';
  }

  @override
  String dailyForecastWeekday(String weekday, String date) {
    return '$weekday, $date';
  }

  @override
  String get now => 'Now';

  @override
  String get airQuality => 'Air quality';

  @override
  String get feelsLike => 'Feels like';

  @override
  String get humidity => 'Humidity';

  @override
  String get precipitation => 'Precipitation';

  @override
  String get wind => 'Wind';

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get networkError => 'Check your connection and try again';

  @override
  String get timeoutError => 'The request timed out. Try again';

  @override
  String get rateLimitError => 'Too many requests. Try again later';

  @override
  String get serviceError => 'Weather service is unavailable';

  @override
  String get dataError => 'Weather data could not be read';

  @override
  String get configError =>
      'Weather API is not configured. Use the QWeather launch configuration.';

  @override
  String get accountError =>
      'Weather service rejected the request. Check the API key, host or account quota';

  @override
  String get weatherSource =>
      'Weather data by QWeather\nhttps://developer.qweather.com/attribution.html';

  @override
  String get openMeteoSource =>
      'Weather data by Open-Meteo\nhttps://open-meteo.com/';

  @override
  String get weatherProvider => 'Weather service';

  @override
  String get weatherProviderHint =>
      'Keep added cities and refresh the current page after changing services.';

  @override
  String get qWeatherService => 'QWeather';

  @override
  String get openMeteoService => 'Open-Meteo';

  @override
  String get conditionClear => 'Clear';

  @override
  String get conditionMainlyClear => 'Mainly clear';

  @override
  String get conditionPartlyCloudy => 'Partly cloudy';

  @override
  String get conditionOvercast => 'Overcast';

  @override
  String get conditionFog => 'Fog';

  @override
  String get conditionDrizzle => 'Drizzle';

  @override
  String get conditionFreezingDrizzle => 'Freezing drizzle';

  @override
  String get conditionRain => 'Rain';

  @override
  String get conditionFreezingRain => 'Freezing rain';

  @override
  String get conditionSnow => 'Snow';

  @override
  String get conditionSnowGrains => 'Snow grains';

  @override
  String get conditionShowers => 'Rain showers';

  @override
  String get conditionSnowShowers => 'Snow showers';

  @override
  String get conditionThunderstorm => 'Thunderstorm';

  @override
  String get conditionThunderstormHail => 'Thunderstorm with hail';

  @override
  String get conditionUnknown => 'Unknown weather';
}
