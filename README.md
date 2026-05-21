# 🛡️ BloodAdmin — Menu Admin NUI Premium

**BloodAdmin** est un outil d'administration complet, moderne et extrêmement performant conçu pour les serveurs FiveM sous le framework **ESX**. Grâce à une interface NUI élégante en verre dépoli (glassmorphism), des performances optimisées (0.00ms au repos) et une sécurité renforcée côté serveur, il offre aux staffs une expérience d'administration ultime.

---

## 🌟 Caractéristiques Principales

*   **🎨 Design Glassmorphic Ultra-Moderne** : Une interface fluide et animée avec des thèmes colorés en fonction des grades et des angles arrondis haut de gamme.
*   **👻 Invisibilité & Noclip Ghostly** :
    *   Le staff en invisibilité (ou noclip) devient un **fantôme translucide (opacité à 20%)** sur son propre écran pour naviguer confortablement.
    *   Il reste **100% invisible réseau** pour les autres joueurs.
    *   Prise en charge automatique des véhicules avec la même transparence et invisibilité dynamique.
*   **🔒 Double Sécurité & Permissions SQL** :
    *   Système de permissions ultra-sécurisé en temps réel géré dans la table `bl_grades`.
    *   Toutes les actions sensibles (Ban, Kick, Teleport, Give, Revive, etc.) sont systématiquement vérifiées côté serveur pour bloquer tout exploit de tricheurs.
    *   Sécurité double couche pour l'IP du joueur (permission `bl.viewip` vérifiée côté client et côté serveur).
*   **📊 Métriques Haute Fidélité** : Visualisation en direct du ping moyen, du nombre de joueurs, de l'uptime et de l'utilisation mémoire (FXServer et Node.js).
*   **💬 Système de Signalement (Reports) & Chat Staff** : Onglet dédié aux reports actifs et fermés avec logs d'action, et chat privé pour le staff.
*   **📜 Logs Discord & Logs SQL** : Enregistrement automatique de toutes les actions administratives dans la table `bl_logs` et envoi instantané vers vos webhooks Discord configurés.
*   **⚡ Diagnostic Intégré** : Commande `/admin_debug` pour aider instantanément les administrateurs à valider leur configuration SQL.

---

## 📋 Prérequis

*   **Framework** : ESX (Legacy ou versions antérieures supportées via détection automatique).
*   **Base de données** : `oxmysql` ou `mysql-async` (détection et adaptation automatique).

---

## ⚙️ Installation

1.  **Importer la structure SQL** :
    *   Importez le fichier [data/database.sql](file:///c:/Users/natha/Desktop/BloodLeak%20v2/bl_admin/data/database.sql) dans votre base de données SQL pour créer les tables nécessaires (`bl_staff`, `bl_grades` et `bl_logs`).
2.  **Ajouter le script au serveur** :
    *   Glissez le dossier `bl_admin` dans votre répertoire `resources/`.
3.  **Configurer le script** :
    *   Ouvrez le fichier [config.lua](file:///c:/Users/natha/Desktop/BloodLeak%20v2/bl_admin/config.lua) pour ajuster les grades, les durées de bans et y coller votre **Webhook Discord** pour les logs.
4.  **Démarrer la ressource** :
    *   Ajoutez la ligne suivante dans votre fichier `server.cfg` :
    ```cfg
    ensure bl_admin
    ```
5.  **Attribuer les droits Staff** :
    *   Ajoutez l'identifiant Rockstar (licence) du staff dans la table `bl_staff` en lui attribuant son grade (ex: `boss`, `admin`, `moderateur`).

---

## ⌨️ Commandes Disponibles

*   `admin` (Touche raccourcie : **F10**) : Ouvre l'interface NUI BloodAdmin (si vous êtes enregistré comme staff).
*   `report` : Permet aux joueurs d'ouvrir l'interface de création de ticket d'aide en jeu.
*   `admin_debug` : Permet de diagnostiquer les erreurs de permissions SQL directement depuis la console du serveur.

---

## 📈 Performances

*   **En veille** : `0.00 ms` dans le moniteur de ressources FiveM.
*   **En cours d'utilisation** : `0.01 ms` - `0.03 ms` (selon l'utilisation du noclip ou de l'invisibilité).

---

*Développé avec passion par **BloodLeak**. Des designs haut de gamme et des performances optimisées pour votre communauté FiveM.*
