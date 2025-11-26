/// Factory pour les pages d'accueil personnalisées par profil de développeur
/// 
/// Ce fichier exporte toutes les pages d'accueil disponibles et fournit
/// une factory pour sélectionner la bonne page en fonction des paramètres utilisateur.

export 'frontend_home_page.dart';
export 'backend_home_page.dart';
export 'devops_home_page.dart';
export 'data_science_home_page.dart';
export 'minimal_home_page.dart';

import 'package:flutter/material.dart';
import '../modern_home_page.dart';
import '../notilus_dev_home_page.dart';
import 'frontend_home_page.dart';
import 'backend_home_page.dart';
import 'devops_home_page.dart';
import 'data_science_home_page.dart';
import 'minimal_home_page.dart';

/// Configuration d'un profil de page d'accueil
class HomePageProfile {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final Color accentColor;
  final List<String> keywords;

  const HomePageProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.accentColor,
    this.keywords = const [],
  });
}

/// Liste des profils de pages d'accueil disponibles
class HomePageProfiles {
  static const List<HomePageProfile> all = [
    HomePageProfile(
      id: 'modern',
      name: 'Modern',
      description: 'Interface classique avec Speed Dial et widgets système',
      emoji: '🌟',
      accentColor: Color(0xFFFF4444),
      keywords: ['général', 'classique', 'standard'],
    ),
    HomePageProfile(
      id: 'notilus_dev',
      name: 'Notilus Dev',
      description: 'Style développeur avec command bar et catégories de liens',
      emoji: '💻',
      accentColor: Color(0xFFFF4444),
      keywords: ['développeur', 'programmeur', 'coder'],
    ),
    HomePageProfile(
      id: 'frontend',
      name: 'Frontend',
      description: 'Optimisé pour React, Vue, Angular et le développement web',
      emoji: '⚛️',
      accentColor: Color(0xFF61DAFB),
      keywords: ['react', 'vue', 'angular', 'css', 'html', 'javascript', 'web'],
    ),
    HomePageProfile(
      id: 'backend',
      name: 'Backend',
      description: 'Terminal-style avec métriques système et APIs',
      emoji: '🖥️',
      accentColor: Color(0xFF339933),
      keywords: ['node', 'python', 'java', 'api', 'serveur', 'database'],
    ),
    HomePageProfile(
      id: 'devops',
      name: 'DevOps',
      description: 'Dashboard monitoring avec statut des services et déploiement',
      emoji: '☁️',
      accentColor: Color(0xFF00FF88),
      keywords: ['docker', 'kubernetes', 'aws', 'ci/cd', 'infrastructure', 'cloud'],
    ),
    HomePageProfile(
      id: 'data_science',
      name: 'Data Science',
      description: 'Visualisations et accès rapide aux outils ML/AI',
      emoji: '📊',
      accentColor: Color(0xFF8B5CF6),
      keywords: ['python', 'machine learning', 'tensorflow', 'pandas', 'jupyter', 'data'],
    ),
    HomePageProfile(
      id: 'minimal',
      name: 'Minimal',
      description: 'Interface épurée, focus sur l\'essentiel',
      emoji: '✨',
      accentColor: Color(0xFFFFFFFF),
      keywords: ['simple', 'clean', 'minimaliste', 'zen'],
    ),
  ];

  /// Trouve un profil par son ID
  static HomePageProfile? findById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Suggère un profil basé sur des mots-clés
  static HomePageProfile suggestProfile(List<String> keywords) {
    int maxScore = 0;
    HomePageProfile suggested = all.first;

    for (final profile in all) {
      int score = 0;
      for (final keyword in keywords) {
        if (profile.keywords.any((k) => k.toLowerCase().contains(keyword.toLowerCase()))) {
          score++;
        }
      }
      if (score > maxScore) {
        maxScore = score;
        suggested = profile;
      }
    }

    return suggested;
  }
}

/// Factory pour créer la page d'accueil appropriée
class HomePageFactory {
  /// Crée le widget de page d'accueil basé sur le style choisi
  static Widget create({
    required String style,
    VoidCallback? onTerminalSelected,
    VoidCallback? onDevToolsSelected,
  }) {
    switch (style) {
      case 'frontend':
        return FrontendHomePage(
          onTerminalSelected: onTerminalSelected,
          onDevToolsSelected: onDevToolsSelected,
        );
      
      case 'backend':
        return BackendHomePage(
          onTerminalSelected: onTerminalSelected,
          onDevToolsSelected: onDevToolsSelected,
        );
      
      case 'devops':
        return DevOpsHomePage(
          onTerminalSelected: onTerminalSelected,
          onDevToolsSelected: onDevToolsSelected,
        );
      
      case 'data_science':
        return DataScienceHomePage(
          onTerminalSelected: onTerminalSelected,
          onDevToolsSelected: onDevToolsSelected,
        );
      
      case 'minimal':
        return MinimalHomePage(
          onTerminalSelected: onTerminalSelected,
          onDevToolsSelected: onDevToolsSelected,
        );
      
      case 'notilus_dev':
        return NotilusDevHomePage(
          onTerminalSelected: onTerminalSelected,
          onDevToolsSelected: onDevToolsSelected,
        );
      
      case 'modern':
      default:
        return ModernHomePage(
          onTerminalSelected: onTerminalSelected,
        );
    }
  }

  /// Retourne le profil correspondant au style
  static HomePageProfile getProfile(String style) {
    return HomePageProfiles.findById(style) ?? HomePageProfiles.all.first;
  }

  /// Liste tous les styles disponibles
  static List<String> get availableStyles => 
      HomePageProfiles.all.map((p) => p.id).toList();
}
