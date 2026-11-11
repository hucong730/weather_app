import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get appTitle;

  /// Manual location prompt
  ///
  /// In en, this message translates to:
  /// **'Search for a city to see its weather'**
  String get searchPrompt;

  /// City-name-only search input hint
  ///
  /// In en, this message translates to:
  /// **'Enter a city name'**
  String get searchHint;

  /// Search button tooltip
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchButton;

  /// Cancel weather preview button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Add previewed city button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Settings button and page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// City management entry and page title
  ///
  /// In en, this message translates to:
  /// **'Manage cities'**
  String get cityManagement;

  /// City management settings entry subtitle
  ///
  /// In en, this message translates to:
  /// **'Delete or reorder added cities'**
  String get cityManagementHint;

  /// Empty city management title
  ///
  /// In en, this message translates to:
  /// **'No added cities'**
  String get noSavedCities;

  /// Empty city management explanation
  ///
  /// In en, this message translates to:
  /// **'Search and add a city from the home page first.'**
  String get noSavedCitiesHint;

  /// Delete city button tooltip
  ///
  /// In en, this message translates to:
  /// **'Delete {city}'**
  String deleteCity(String city);

  /// City drag handle accessibility label
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder {city}'**
  String reorderCity(String city);

  /// Fixed current-location empty state
  ///
  /// In en, this message translates to:
  /// **'Unable to get your current position. Check Location Services and location permission, then retry, or search for a city.'**
  String get locationPrompt;

  /// Warning when cached GPS weather remains after location failure
  ///
  /// In en, this message translates to:
  /// **'Current location is unavailable. Showing saved weather.'**
  String get cachedLocationWarning;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// System default option
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// Location permission switch label
  ///
  /// In en, this message translates to:
  /// **'Location permission'**
  String get locationPermission;

  /// System permission limitation explanation
  ///
  /// In en, this message translates to:
  /// **'Changes are confirmed by the operating system. Turning permission off opens App Settings.'**
  String get permissionSystemHint;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutApp;

  /// About app description
  ///
  /// In en, this message translates to:
  /// **'A Flutter weather app with current conditions, hourly and daily forecasts, and multiple cities.'**
  String get appDescription;

  /// Data sources section title
  ///
  /// In en, this message translates to:
  /// **'Data sources'**
  String get dataSources;

  /// Weather icon source and license
  ///
  /// In en, this message translates to:
  /// **'Weather icons: QWeather Icons (MIT License)\nhttps://github.com/qwd/Icons'**
  String get iconSource;

  /// City-name-only validation message
  ///
  /// In en, this message translates to:
  /// **'Enter a city name without postcodes or coordinates'**
  String get invalidQuery;

  /// Empty city-name search result
  ///
  /// In en, this message translates to:
  /// **'No matching cities'**
  String get noResults;

  /// Automatic location progress
  ///
  /// In en, this message translates to:
  /// **'Finding your location…'**
  String get locating;

  /// Weather loading progress
  ///
  /// In en, this message translates to:
  /// **'Loading weather…'**
  String get loading;

  /// GPS location label
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// Accessibility label for the fixed location page marker
  ///
  /// In en, this message translates to:
  /// **'Current location, page {index} of {count}'**
  String currentLocationPage(int index, int count);

  /// Accessibility label for an added city page marker
  ///
  /// In en, this message translates to:
  /// **'City, page {index} of {count}'**
  String cityPage(int index, int count);

  /// Hourly forecast section title
  ///
  /// In en, this message translates to:
  /// **'24-hour forecast'**
  String get hourlyForecast;

  /// Daily forecast section title
  ///
  /// In en, this message translates to:
  /// **'7-day forecast'**
  String get dailyForecast;

  /// Daily forecast label for the selected city's current day
  ///
  /// In en, this message translates to:
  /// **'Today, {date}'**
  String dailyForecastToday(String date);

  /// Daily forecast label for days other than today
  ///
  /// In en, this message translates to:
  /// **'{weekday}, {date}'**
  String dailyForecastWeekday(String weekday, String date);

  /// Current hour label
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get now;

  /// Air quality label
  ///
  /// In en, this message translates to:
  /// **'Air quality'**
  String get airQuality;

  /// Apparent temperature label
  ///
  /// In en, this message translates to:
  /// **'Feels like'**
  String get feelsLike;

  /// Humidity label
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// Precipitation label
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get precipitation;

  /// Wind speed label
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Refresh button tooltip
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Network failure message
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get networkError;

  /// Network timeout message
  ///
  /// In en, this message translates to:
  /// **'The request timed out. Try again'**
  String get timeoutError;

  /// Rate limit message
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Try again later'**
  String get rateLimitError;

  /// Weather service HTTP error
  ///
  /// In en, this message translates to:
  /// **'Weather service is unavailable'**
  String get serviceError;

  /// Invalid weather data message
  ///
  /// In en, this message translates to:
  /// **'Weather data could not be read'**
  String get dataError;

  /// Missing weather API configuration message
  ///
  /// In en, this message translates to:
  /// **'Weather API is not configured. Use the QWeather launch configuration.'**
  String get configError;

  /// Weather service credential or quota rejection message
  ///
  /// In en, this message translates to:
  /// **'Weather service rejected the request. Check the API key, host or account quota'**
  String get accountError;

  /// QWeather data attribution
  ///
  /// In en, this message translates to:
  /// **'Weather data by QWeather\nhttps://developer.qweather.com/attribution.html'**
  String get weatherSource;

  /// Open-Meteo data attribution
  ///
  /// In en, this message translates to:
  /// **'Weather data by Open-Meteo\nhttps://open-meteo.com/'**
  String get openMeteoSource;

  /// Weather provider setting label
  ///
  /// In en, this message translates to:
  /// **'Weather service'**
  String get weatherProvider;

  /// Weather provider setting explanation
  ///
  /// In en, this message translates to:
  /// **'Keep added cities and refresh the current page after changing services.'**
  String get weatherProviderHint;

  /// QWeather provider option
  ///
  /// In en, this message translates to:
  /// **'QWeather'**
  String get qWeatherService;

  /// Open-Meteo provider option
  ///
  /// In en, this message translates to:
  /// **'Open-Meteo'**
  String get openMeteoService;

  /// Clear weather
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get conditionClear;

  /// Mainly clear weather
  ///
  /// In en, this message translates to:
  /// **'Mainly clear'**
  String get conditionMainlyClear;

  /// Partly cloudy weather
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get conditionPartlyCloudy;

  /// Overcast weather
  ///
  /// In en, this message translates to:
  /// **'Overcast'**
  String get conditionOvercast;

  /// Foggy weather
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get conditionFog;

  /// Drizzle weather
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get conditionDrizzle;

  /// Freezing drizzle weather
  ///
  /// In en, this message translates to:
  /// **'Freezing drizzle'**
  String get conditionFreezingDrizzle;

  /// Rainy weather
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get conditionRain;

  /// Freezing rain weather
  ///
  /// In en, this message translates to:
  /// **'Freezing rain'**
  String get conditionFreezingRain;

  /// Snowy weather
  ///
  /// In en, this message translates to:
  /// **'Snow'**
  String get conditionSnow;

  /// Snow grains weather
  ///
  /// In en, this message translates to:
  /// **'Snow grains'**
  String get conditionSnowGrains;

  /// Rain showers weather
  ///
  /// In en, this message translates to:
  /// **'Rain showers'**
  String get conditionShowers;

  /// Snow showers weather
  ///
  /// In en, this message translates to:
  /// **'Snow showers'**
  String get conditionSnowShowers;

  /// Thunderstorm weather
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get conditionThunderstorm;

  /// Thunderstorm with hail
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm with hail'**
  String get conditionThunderstormHail;

  /// Unknown weather condition
  ///
  /// In en, this message translates to:
  /// **'Unknown weather'**
  String get conditionUnknown;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
