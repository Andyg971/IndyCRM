# IndyCRM

## Description
IndyCRM est une application de gestion de relation client (CRM) conçue pour les indépendants et les petites entreprises. Elle permet de gérer efficacement les contacts, les projets, les factures et le suivi des tâches.

## Fonctionnalités principales
- 📋 Gestion des contacts
- 📊 Gestion de projets
- 💰 Facturation
- 📅 Suivi des tâches
- 📈 Tableau de bord analytique
- 🔔 Système de notifications
- 📤 Export (PDF, vCard)
- 📝 Historique des activités

## Configuration requise
- iOS 14.0 ou supérieur
- macOS 11.0 ou supérieur
- Xcode 13.0 ou supérieur
- Swift 5.5 ou supérieur

## Installation
1. Clonez le dépôt :
```bash
git clone https://github.com/Andyg971/IndyCRM.git
```

2. Ouvrez le projet dans Xcode :
```bash
cd IndyCRM
open IndyCrm.xcodeproj
```

3. Installez les dépendances via Swift Package Manager :
- GoogleSignIn
- PDFKit
- SwiftUI

## Architecture
L'application suit une architecture MVVM (Model-View-ViewModel) avec les composants suivants :

### Models
- Contact
- Project
- Invoice
- Task
- ActivityLog

### Views
- Dashboard
- Contacts
- Projects
- Invoices
- Settings

### Services
- AuthenticationService
- ExportService
- ProjectManager
- InvoiceManager
- NotificationManager

## Guide d'utilisation

### Gestion des contacts
- Ajout/modification/suppression de contacts
- Import/export de contacts (vCard)
- Historique des interactions

### Gestion de projets
- Création de projets
- Assignation de tâches
- Suivi de l'avancement
- Gestion des délais

### Facturation
- Création de factures
- Suivi des paiements
- Export PDF
- Historique des transactions

### Tableau de bord
- Vue d'ensemble des activités
- Statistiques
- Indicateurs de performance

## Sécurité
- Authentification sécurisée
- Chiffrement des données sensibles
- Sauvegarde automatique
- Conformité RGPD

## Support
Pour toute question ou assistance :
- 📧 Email : support@indycrm.com
- 💬 Discord : [Rejoindre le serveur](https://discord.gg/indycrm)
- 📱 Twitter : [@IndyCRM](https://twitter.com/indycrm)

## Licence
IndyCRM est distribué sous la licence MIT. Voir le fichier `LICENSE` pour plus d'informations.

## Contribution
Les contributions sont les bienvenues ! Veuillez consulter notre guide de contribution dans `CONTRIBUTING.md`. 