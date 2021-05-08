import 'dart:convert';
import 'dart:ui';

import 'package:devicelocale/devicelocale.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localize_and_translate.dart';

class LocalizeAndTranslate {
  ///------------------------------------------------
  /// Config
  ///------------------------------------------------
  List<String> _langList = [];
  String? _assetsDir;
  Locale? _locale;
  Map<String, dynamic>? _values;
  SharedPreferences? _prefs;

  ///------------------------------------------------
  /// Initialize Plugin
  ///------------------------------------------------
  Future<Null> init({
    required List<String> languagesList,
    String? assetsDirectory,
    Map<String, String>? valuesAsMap, // Later
    SharedPreferences? prefsInstance,
  }) async {
    // ---- Vars ---- //
    _assetsDir = assetsDirectory!.endsWith('/')
        ? '$assetsDirectory'
        : '$assetsDirectory/';
    _prefs = prefsInstance ?? await SharedPreferences.getInstance();
    _langList = languagesList;

    if (_prefs!.getString('currentLang') != null) {
      _locale = Locale(_prefs!.getString('currentLang')!);
    } else {
      Locale? locale = await Devicelocale.currentAsLocale;
      if (locale != null) {
        if (_langList.contains(locale.languageCode)) {
          _locale = locale;
        } else {
          _locale = Locale(_langList[0]);
        }
      } else {
        _locale = Locale(_langList[0]);
      }
    }

    if (_assetsDir == null && valuesAsMap == null) {
      assert(
        _assetsDir != null || valuesAsMap != null,
        '--You must define _assetsDirectory or valuesAsMap',
      );
      return null;
    }

    if (_assetsDir != null) {
      _assetsDir = assetsDirectory;
      _values = await initLanguage(_locale!.languageCode);
    } else {
      _values = valuesAsMap;
    }

    return null;
  }

  ///------------------------------------------------
  /// Initialize Active Language Values
  ///------------------------------------------------
  initLanguage(String languageCode) async {
    String filePath = '$_assetsDir$languageCode.json';
    String content = await rootBundle.loadString(filePath);
    return json.decode(content);
  }

  ///------------------------------------------------
  /// Transle : [key]
  ///------------------------------------------------
  String translate(String key, [Map<String, String>? arguments]) {
    String value =
        (_values == null || _values![key] == null) ? '$key' : _values![key];
    if (arguments == null) return value;
    for (var key in arguments.keys) {
      value = value.replaceAll(key, arguments[key]!);
    }
    return value;
  }

  ///------------------------------------------------
  /// Change Language
  ///------------------------------------------------
  Future<Null> setNewLanguage(
    context, {
    required String newLanguage,
    bool restart = true,
    bool remember = true,
  }) async {
    String updatedLanguage = newLanguage;
    if (newLanguage == '') {
      updatedLanguage = _locale?.languageCode ?? _langList[0];
    }
    _locale = Locale(updatedLanguage, '');

    String filePath = '$_assetsDir$newLanguage.json';
    String content = await rootBundle.loadString(filePath);

    _values = json.decode(content);

    if (remember) {
      SharedPreferences prefs = _prefs ?? await SharedPreferences.getInstance();
      await prefs.setString('currentLang', newLanguage);
    }

    if (restart) {
      LocalizedApp.restart(context);
    }

    return null;
  }

  ///------------------------------------------------
  /// Determine Active Layout (bool)
  ///------------------------------------------------
  isDirectionRTL(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl;

  ///------------------------------------------------
  /// Restart App
  ///------------------------------------------------
  restart(BuildContext context) => LocalizedApp.restart(context);

  ///------------------------------------------------
  /// Active Language Code (String)
  ///------------------------------------------------
  String get currentLanguage => _locale!.languageCode;

  ///------------------------------------------------
  /// Active Locale
  ///------------------------------------------------
  Locale get locale => _locale ?? Locale(_langList[0]);

  ///------------------------------------------------
  /// delegatess
  ///------------------------------------------------
  Iterable<LocalizationsDelegate> get delegates => [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
      ];

  ///------------------------------------------------
  /// Locals List
  ///------------------------------------------------
  Iterable<Locale> locals() =>
      _langList.map<Locale>((lang) => new Locale(lang, ''));
}
