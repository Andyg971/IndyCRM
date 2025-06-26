# 💼 IndyCRM

*Solution CRM complète pour indépendants et freelances*

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-blue.svg)](https://developer.apple.com/swiftui/)
[![Platform](https://img.shields.io/badge/Platform-iOS%2016+%20%7C%20macOS%2013+-lightgrey.svg)](https://developer.apple.com)
[![CloudKit](https://img.shields.io/badge/CloudKit-Sync-green.svg)](https://developer.apple.com/icloud/cloudkit/)
[![Core Data](https://img.shields.io/badge/Core%20Data-Enabled-blue.svg)](https://developer.apple.com/documentation/coredata)

## 🎯 Vision

IndyCRM révolutionne la gestion d'activité pour les indépendants en offrant une solution tout-en-un moderne, intuitive et puissante. Conçue spécifiquement pour les freelances, consultants et petites entreprises, elle simplifie la gestion quotidienne tout en maximisant la productivité.

## ✨ Fonctionnalités Principales

### 🏢 **Gestion Clients Avancée**
- **Profils clients détaillés** avec historique complet
- **Segmentation intelligente** par secteur, importance, localisation
- **Timeline d'interactions** avec rappels automatiques
- **Documents clients** centralisés et sécurisés
- **Notes privées** et informations stratégiques

### 📊 **Gestion de Projets**
- **Planification visuelle** avec Gantt charts
- **Suivi du temps** précis par tâche et client
- **Jalons et échéances** avec notifications intelligentes
- **Collaboration** avec clients et sous-traitants
- **Templates de projets** pour accélérer les démarrages

### 💰 **Facturation Professionnelle**
- **Facturation automatisée** à partir du temps passé
- **Templates personnalisables** avec votre branding
- **Multi-devises** et calculs de taxes automatiques
- **Relances automatiques** pour les impayés
- **Export comptable** vers les principaux logiciels

### 📈 **Tableau de Bord Analytics**
- **KPIs en temps réel** : CA, marge, productivité
- **Graphiques interactifs** pour visualiser les tendances
- **Prévisions de revenus** basées sur l'historique
- **Analyse de rentabilité** par client et projet
- **Rapports d'activité** automatisés

### 🎨 **Interface Moderne**
- **Design système cohérent** avec composants réutilisables
- **Navigation intuitive** adaptée aux workflows métier
- **Thème sombre/clair** avec basculement automatique
- **Responsive design** pour tous les écrans Apple
- **Accessibilité complète** conforme aux standards

### ☁️ **Synchronisation CloudKit**
- **Sync automatique** entre iPhone, iPad et Mac
- **Backup sécurisé** dans le cloud Apple
- **Partage contrôlé** avec votre équipe
- **Mode hors ligne** avec synchronisation différée

## 🎨 **Architecture & Technologies**

### Stack Technique
- **SwiftUI** - Interface utilisateur moderne et déclarative
- **Core Data** - Persistance locale robuste avec migrations
- **CloudKit** - Synchronisation cloud native Apple
- **Combine** - Programmation réactive
- **Swift Package Manager** - Gestion des dépendances
- **MVVM + Clean Architecture** - Code maintenable et testable

### Fonctionnalités iOS/macOS
- **Multi-plateforme** - Code partagé iOS/macOS optimisé
- **Widgets** - Informations clés sur l'écran d'accueil
- **Siri Shortcuts** - Automatisation vocale des tâches courantes
- **Handoff** - Continuité entre appareils Apple
- **Document Provider** - Intégration avec Files et iCloud Drive

## 👥 **Public Cible**

### 🚀 **Freelances & Consultants**
- Développeurs, designers, marketeurs indépendants
- Conseil en stratégie, formation, coaching
- Optimisation du temps et maximisation des revenus

### 🏢 **Petites Entreprises**
- Agences créatives et digitales
- Cabinets de conseil spécialisés
- Studios de développement et design

### 💼 **Professions Libérales**
- Avocats, notaires, experts-comptables
- Architectes, ingénieurs indépendants
- Thérapeutes et praticiens de santé

### 🎯 **Entrepreneurs**
- Créateurs de start-ups
- E-commerçants et dropshippers
- Formateurs et créateurs de contenu

## 🚀 **Installation & Configuration**

### Prérequis
- **Xcode 15.0+** avec Swift 5.9+
- **iOS 16.0+** ou **macOS 13.0+**
- **Compte développeur Apple** pour CloudKit
- **Swift Package Manager** pour les dépendances

### Installation
```bash
# Cloner le repository
git clone https://github.com/Andyg971/IndyCRM.git

# Naviguer dans le dossier
cd IndyCRM

# Ouvrir le workspace Xcode
open IndyCrm/IndyCrm.xcodeproj
```

### Configuration CloudKit
1. **Container CloudKit** - Créer dans le portail développeur
2. **Schémas de données** - Auto-génération au premier lancement
3. **Permissions** - Configurer les accès privés/publics
4. **Notifications** - Activer les push notifications

### Configuration Core Data
```swift
// La stack Core Data est configurée automatiquement
// Migrations gérées via DataController.shared
let dataController = DataController.shared
```

## 🛠️ **Développement**

### Structure du Projet
```
IndyCRM/
├── Models/              # Modèles de données Core Data
│   ├── Client+CoreData.swift
│   ├── Project+CoreData.swift
│   ├── Invoice+CoreData.swift
│   └── TimeEntry+CoreData.swift
├── Views/               # Interfaces SwiftUI
│   ├── Dashboard/
│   ├── Clients/
│   ├── Projects/
│   ├── Invoicing/
│   └── Components/
├── ViewModels/          # Logique de présentation
│   ├── DashboardViewModel.swift
│   ├── ClientsViewModel.swift
│   └── ProjectsViewModel.swift
├── Services/            # Services métier
│   ├── CloudKitService.swift
│   ├── InvoiceService.swift
│   └── TimeTrackingService.swift
├── Managers/            # Gestionnaires système
│   ├── DataController.swift
│   ├── LanguageManager.swift
│   └── ThemeManager.swift
└── Resources/           # Ressources localisées
    ├── en.lproj/
    ├── fr.lproj/
    └── es.lproj/
```

### Fonctionnalités Clés Implémentées

#### 💾 **Persistance Données**
- **Core Data Stack** optimisé avec migrations automatiques
- **CloudKit Sync** bidirectionnel avec résolution de conflits
- **Cache local** pour performances optimales hors ligne

#### 🎯 **Gestion Métier**
- **Invoice Engine** - Génération PDF avec templates personnalisables
- **Time Tracking** - Minuteur intégré avec détection automatique
- **Project Templates** - Accélération des créations de projets

#### 🔄 **Synchronisation**
- **Real-time sync** avec CloudKit
- **Conflict resolution** intelligent
- **Backup automatique** et restauration

## 📱 **Fonctionnalités par Plateforme**

### iOS Features
- **3D Touch** - Actions rapides sur l'icône
- **Dynamic Island** - Suivi du temps en cours
- **Live Activities** - Timer de projet en direct
- **Widgets** - Dashboard sur l'écran d'accueil

### macOS Features
- **Menu Bar** - Accès rapide aux fonctions essentielles
- **Touch Bar** - Raccourcis contextuels (MacBook Pro)
- **Multi-Window** - Gestion simultanée de plusieurs projets
- **Keyboard Shortcuts** - Navigation rapide au clavier

## 🔧 **API & Intégrations**

### Intégrations Natives
- **Contacts.framework** - Import automatique des contacts
- **EventKit** - Synchronisation avec Calendar
- **PDFKit** - Génération et annotation de factures
- **MessageUI** - Envoi direct d'emails et SMS

### Extensions Prévues
- **QuickBooks** - Export comptable automatique
- **Stripe** - Paiements en ligne intégrés
- **Toggl** - Import des temps trackés
- **Slack** - Notifications d'équipe

## 🎨 **Design System**

### Composants UI Réutilisables
```swift
// Exemple de composant ModernCard
struct ModernCard<Content: View>: View {
    let content: Content
    let darkMode: Bool
    
    init(darkMode: Bool = false, @ViewBuilder content: () -> Content) {
        self.darkMode = darkMode
        self.content = content()
    }
}
```

### Thèmes & Styles
- **Color Palette** - Cohérence visuelle sur toutes les plateformes
- **Typography Scale** - Hiérarchie typographique claire
- **Spacing System** - Grille modulaire pour layouts consistants
- **Animation Library** - Transitions fluides et naturelles

## 📊 **Performance & Optimisation**

### Optimisations Techniques
- **Lazy Loading** - Chargement différé des données volumineuses
- **Image Caching** - Cache intelligent pour les photos clients
- **Background Sync** - Synchronisation en arrière-plan
- **Memory Management** - Gestion optimisée de la mémoire

### Métriques de Performance
- **Temps de démarrage** : < 2 secondes
- **Synchronisation** : < 5 secondes pour 1000 entrées
- **Export PDF** : < 3 secondes pour facture complexe
- **Recherche** : Résultats instantanés jusqu'à 10k entrées

## 🔐 **Sécurité & Confidentialité**

### Sécurité des Données
- **Chiffrement local** - Base de données chiffrée
- **CloudKit Private** - Données privées utilisateur uniquement
- **Keychain** - Stockage sécurisé des credentials
- **Biometric Auth** - Face ID / Touch ID pour l'accès

### Conformité RGPD
- **Privacy by Design** - Respect de la vie privée dès la conception
- **Data Minimization** - Collecte strictement nécessaire
- **User Control** - Gestion complète par l'utilisateur
- **Export/Delete** - Droit à la portabilité et à l'effacement

## 🔮 **Roadmap**

### Phase 1 - Core CRM ✅
- [x] Gestion clients et projets
- [x] Facturation de base
- [x] Synchronisation CloudKit
- [x] Interface SwiftUI native

### Phase 2 - Business Intelligence 🚧
- [x] Dashboard analytics avancé
- [x] Rapports personnalisables
- [ ] Prévisions IA de revenus
- [ ] Analyse comportementale clients

### Phase 3 - Automatisation 📋
- [ ] Workflows automatisés
- [ ] Templates intelligents
- [ ] Intégrations tierces étendues
- [ ] Assistant IA pour recommandations

### Phase 4 - Expansion 🌟
- [ ] Version Web collaborative
- [ ] API publique pour développeurs
- [ ] Marketplace de templates
- [ ] Solutions sectorielles spécialisées

## 🏆 **Avantages Concurrentiels**

### vs Solutions Existantes
- **Native Apple** - Performance et intégration optimales
- **Privacy First** - Données 100% privées utilisateur
- **No Subscription** - Achat unique, pas d'abonnement
- **Offline Ready** - Fonctionnement complet hors ligne

### Proposition de Valeur Unique
- **Simplicité** - Interface intuitive, courbe d'apprentissage minimale
- **Polyvalence** - S'adapte à tous types d'activités indépendantes
- **Évolutivité** - Grandit avec votre activité
- **ROI Immédiat** - Rentabilité dès les premières factures

## 📄 **Licence**

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🤝 **Support & Communauté**

- **Documentation** : [Wiki du projet](https://github.com/Andyg971/IndyCRM/wiki)
- **Issues** : [Rapporter un problème](https://github.com/Andyg971/IndyCRM/issues)
- **Discussions** : [Forum communautaire](https://github.com/Andyg971/IndyCRM/discussions)
- **Email** : contact@indycrm.fr

## 📊 **Statistiques Techniques**

- **Langage principal** : Swift (92%)
- **Lignes de code** : ~12,000
- **Tests unitaires** : 120+ tests
- **Couverture de code** : 85%+
- **Compatibilité** : iOS 16.0+ | macOS 13.0+

---

*Développé avec 💙 en SwiftUI par [Andyg971](https://github.com/Andyg971)*

**⭐ Donnez une étoile si IndyCRM vous aide à développer votre activité !**