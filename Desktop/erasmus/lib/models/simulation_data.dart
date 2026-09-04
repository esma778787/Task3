import 'package:flutter/material.dart';

class SimulationData extends ChangeNotifier {
  // ───────── Kullanıcı Bilgileri ─────────
  String userEmail = '';
  String userNote  = '';
  String userName  = '';
  String userGender = '';
  String selectedCategory = '';
  String projectDescription = '';
  String userInterests = '';

  // ───────── Seçilen Erasmus+ Projesi (YENİ) ─────────
  String selectedProjectTitle = '';
  String selectedProjectLink = '';
  String selectedProjectCategory = '';

  // ───────── CV & Mektup ─────────
  String generatedCV = '';
  String generatedMotivationLetter = '';

  // ➤ Europass alanları (YENİ)
  String userSkills      = '';
  String userAboutMe     = '';
  String userEducation   = '';
  String userExperience  = '';

  // ───────── Skor & Seviye ─────────
  int  score        = 0;
  int  currentStep  = 0;

  // ───────── Mini Erasmus Challenge (Gamification) ─────────
  int gameScore = 0;
  double gameScorePercentage = 0;
  Map<String, int> gameScoreProfile = {};
  String gameSummary = '';

  // ───────── Uygunluk Puanı (YENİ) ─────────
  int suitabilityScore = 0;
  bool get isSuitable => suitabilityScore >= 60;

  // ───────── Eksik Bilgiler (YENİ) ─────────
  String userLanguageLevel = '';  // CEFR: A1, A2, B1, B2, C1, C2
  String userCVLanguage = '';      // CV dilı: İngilizce, Türkçe, vb.
  String aiFeedback = '';          // OpenRouter tarafından oluşturulan geri bildirim

  void evaluateSuitability() {
    // Basit anahtar-kelime eşleşmesi (örnek)
    final keywords = [
      'team', 'communication', 'volunteer', 'project',
      'leadership', 'english', 'youth', 'problem'
    ];
    final content = (
      userSkills + userAboutMe + userEducation + userExperience
    ).toLowerCase();

    int matches = keywords.where((k) => content.contains(k)).length;
    suitabilityScore = ((matches / keywords.length) * 100).round();
    notifyListeners();
  }

  // ───────── Setter’lar ─────────
  void setUserEmail(String v){ userEmail = v; notifyListeners(); }
  void setUserNote (String v){ userNote  = v; notifyListeners(); }
  void setGeneratedCV(String v){ generatedCV = v; notifyListeners(); }
  void setGeneratedMotivationLetter(String v){
    generatedMotivationLetter = v; notifyListeners();
  }
  void setUserLanguageLevel(String v){ userLanguageLevel = v; notifyListeners(); }
  void setUserCVLanguage(String v){ userCVLanguage = v; notifyListeners(); }
  void setAIFeedback(String v){ aiFeedback = v; notifyListeners(); }

  void setUserDetails({
    required String name,
    required String gender,
    required String category,
    required String projectDesc,
    required String interests,
  }){
    userName = name;
    userGender = gender;
    selectedCategory = category;
    projectDescription = projectDesc;
    userInterests = interests;
    notifyListeners();
  }

  void setUserName(String v){ userName = v; notifyListeners(); }
  void setUserGender(String v){ userGender = v; notifyListeners(); }

  void setCategoryAndProject({
    required String category,
    required String description,
    required String interests,
  }){
    selectedCategory = category;
    projectDescription = description;
    userInterests = interests;
    notifyListeners();
  }

  // ───────── Simülasyon Kontrol ─────────
  void nextStep(){
    if(currentStep < 5) currentStep++;
    notifyListeners();
  }

  void addScore(int v){ score += v; notifyListeners(); }

  // ───────── Game setters ─────────
  void setGameScore(int v){ gameScore = v; notifyListeners(); }
  void setGameScorePercentage(double v){ gameScorePercentage = v; notifyListeners(); }
  void setGameScoreProfile(Map<String,int> v){ gameScoreProfile = Map<String,int>.from(v); notifyListeners(); }
  void setGameSummary(String v){ gameSummary = v; notifyListeners(); }

  // ───────── Seçilen Proje Setter ─────────
  void setSelectedProject({
    required String title,
    required String link,
    required String category,
    String? description,
  }){
    selectedProjectTitle = title;
    selectedProjectLink = link;
    selectedProjectCategory = category;
    if (description != null) {
      projectDescription = description;
    }
    notifyListeners();
  }

  void resetSimulation(){
    userEmail = userNote = userName = userGender = '';
    selectedCategory = projectDescription = userInterests = '';
    generatedCV = generatedMotivationLetter = '';
    userSkills = userAboutMe = userEducation = userExperience = '';
    userLanguageLevel = userCVLanguage = aiFeedback = '';
    suitabilityScore = 0;
    score = 0; currentStep = 0;
    // reset selected project
    selectedProjectTitle = selectedProjectLink = selectedProjectCategory = '';
    // reset game fields
    gameScore = 0;
    gameScorePercentage = 0;
    gameScoreProfile = {};
    gameSummary = '';
    notifyListeners();
  }
}
