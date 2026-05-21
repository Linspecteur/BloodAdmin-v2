<div align="center">
  <img src="https://img.shields.io/badge/FiveM-Script-orange?style=for-the-badge&logo=fivem&logoColor=white" />
  <img src="https://img.shields.io/badge/Framework-ESX-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Author-BloodLeak-purple?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-All%20Rights%20Reserved-red?style=for-the-badge" />
  
  <h1>🛡️ BloodAdmin (bl_admin)</h1>
  <p><i>L'administration ultime, sécurisée et moderne en verre dépoli (Glassmorphism) pour votre serveur FiveM</i></p>
</div>

---

## 📖 À propos

**BloodAdmin** n'est pas un simple script d'administration. C'est un outil d'administration complet, moderne et extrêmement performant conçu pour les serveurs FiveM sous le framework **ESX**. Grâce à une interface NUI élégante en verre dépoli (glassmorphism), des performances optimisées (0.00ms au repos) et une sécurité renforcée côté serveur, il offre à votre équipe d'administration une expérience fluide et haut de gamme.

---

## 🌟 Fonctionnalités Clés

- 🎨 **Interface Premium (UI) :** Design Glassmorphic ultra-moderne, fluide et réactif s'adaptant à toutes les résolutions d'écran, avec des thèmes colorés dynamiques selon le grade.
- 👻 **Invisibilité & Noclip Ghostly :** 
  - Le staff en invisibilité (ou noclip) devient un fantôme translucide (opacité à 20%) sur son propre écran pour naviguer confortablement.
  - Il reste **100% invisible réseau** pour les autres joueurs en jeu.
  - Prise en charge automatique des véhicules avec la même transparence et invisibilité dynamique.
- 🔒 **Sécurité Double Couche :** Système de permissions ultra-sécurisé en temps réel. Toutes les actions sensibles (Ban, Kick, Teleport, Give, Revive, etc.) sont systématiquement vérifiées côté serveur pour bloquer tout exploit de tricheurs. Sécurité renforcée pour l'IP du joueur (permission `bl.viewip` vérifiée côté client et côté serveur).
- 📊 **Métriques Haute Fidélité :** Suivi en direct du ping moyen, du nombre de joueurs connectés, de l'uptime et de l'utilisation mémoire (FXServer et Node.js).
- 💬 **Signalements & Chat Staff :** Onglet dédié aux reports actifs et fermés avec logs d'action, et chat privé chiffré en direct pour le staff.
- 📜 **Logs Discord & SQL :** Enregistrement automatique de toutes les actions administratives dans la table `bl_logs` et envoi instantané vers vos webhooks Discord configurés.
- ⚡ **Diagnostic Intégré :** Commande `/admin_debug` pour aider instantanément les administrateurs à valider leur configuration SQL.

---

## ⚙️ Prérequis

Pour fonctionner de manière optimale, le script nécessite :
- [**es_extended**](https://github.com/esx-framework/esx-legacy) (Legacy ou versions antérieures supportées via détection automatique)
- [**oxmysql**](https://github.com/overextended/oxmysql) ou `mysql-async` (détection et adaptation automatique)

---

## 🚀 Installation Rapide

1. **Importer la base de données :**
   Importez le fichier [data/database.sql](file:///c:/Users/natha/Desktop/BloodLeak%20v2/bl_admin/data/database.sql) dans votre base de données SQL pour créer les tables requises (`bl_staff`, `bl_grades`, `bl_bans`, `bl_warns`, `bl_logs`, etc.).
2. **Placer la ressource :**
   Glissez le dossier `bl_admin` dans votre répertoire `resources/` de votre serveur.
3. **Configurer les options :**
   Ouvrez le fichier [config.lua](file:///c:/Users/natha/Desktop/BloodLeak%20v2/bl_admin/config.lua) pour ajuster les grades, les durées de bans et y coller votre **Webhook Discord** pour les logs.
4. **Démarrer le script :**
   Ajoutez la ligne suivante dans votre fichier `server.cfg` :
   ```cfg
   ensure bl_admin
   ```

---

## 🔑 Attribution des Rangs Staff (Set Staff)

Pour pouvoir ouvrir le menu admin (touche **F10** par défaut) et accéder aux fonctionnalités, le joueur **doit être enregistré dans le système**. `bl_admin` utilise une table dédiée `bl_staff` comme source unique de vérité.

Il existe **4 méthodes** pour ajouter ou modifier le grade d'un staff.

### 🖥️ Méthode 1 : Via la Console du Serveur (Recommandé)
C'est la méthode idéale pour vous attribuer le grade suprême `boss` lors de l'installation ou quand aucun staff n'est en ligne.

Dans votre console serveur (sans le `/` devant la commande), tapez :
```cmd
setstaff [ID_Joueur] [Grade]
```
* **Exemple fondateur :** `setstaff 1 boss` (promeut l'ID 1 comme fondateur).
* **Exemple modérateur :** `setstaff 5 moderateur` (promeut l'ID 5 comme modérateur).

> [!NOTE]
> Le joueur ciblé **doit être connecté sur le serveur** pour que la commande console fonctionne.
> Si la commande réussit, vous verrez un message de confirmation vert dans la console et le joueur recevra une notification in-game.

### 💬 Méthode 2 : Via les commandes En Jeu (Chat / Console F8)
Si vous êtes déjà staff (avec le grade `boss` ou un grade possédant la permission `bl.staff`), vous pouvez gérer les staffs directement depuis le chat ou la console F8 du jeu.

Dans le chat de jeu :
```text
/setstaff [ID_Joueur] [Grade]
```
Dans la console F8 :
```text
setstaff [ID_Joueur] [Grade]
```
* **Exemple promotion :** `/setstaff 2 admin` (promeut le joueur ID `2` en tant qu'admin).
* **Exemple rétrogradation :** `/setstaff 2 user` (rétrograde le joueur ID `2` au rang de simple joueur et retire tous ses accès staff).

### 🗄️ Danger / Hors-ligne : Directement en Base de Données (SQL)
Si le joueur n'est pas connecté et que vous souhaitez lui attribuer ses accès staff à l'avance, vous devez insérer sa licence Rockstar directement dans la base de données.

1. Récupérez la licence Rockstar du joueur (au format `license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`).
2. Exécutez la requête SQL suivante dans votre logiciel de base de données (HeidiSQL, phpMyAdmin...) :
   ```sql
   INSERT INTO `bl_staff` (`identifier`, `grade`) 
   VALUES ('license:METTEZ_LA_LICENCE_ICI', 'boss') 
   ON DUPLICATE KEY UPDATE `grade` = 'boss';
   ```
3. Pour assurer une cohérence totale avec le framework ESX, mettez également à jour sa table `users` :
   ```sql
   UPDATE `users` SET `group` = 'boss' WHERE `identifier` = 'license:METTEZ_LA_LICENCE_ICI';
   ```
*(Remplacez `boss` par le grade souhaité : `superadmin`, `admin`, `moderateur`, `helper`, etc.)*

### 🎨 Méthode 4 : Via l'interface Graphique en Jeu (NUI)
Une fois en jeu avec le menu ouvert :
1. Appuyez sur **F10** pour ouvrir le menu BloodAdmin.
2. Rendez-vous dans l'onglet **Staff**.
3. Vous y trouverez la liste complète de l'équipe.
4. Cliquez sur le bouton pour **Ajouter un Staff** ou sélectionnez un joueur en ligne pour modifier instantanément son grade ou révoquer ses accès.

### ❌ Rétrogradation rapide (Retirer les accès)
Pour retirer définitivement les accès d'un membre du personnel :
* **Console ou Chat :** `/setstaff [ID] user`
* **Base de Données :**
  ```sql
  DELETE FROM `bl_staff` WHERE `identifier` = 'license:SA_LICENCE';
  UPDATE `users` SET `group` = 'user' WHERE `identifier` = 'license:SA_LICENCE';
  ```

---

## ⌨️ Commandes & Raccourcis

- **`admin` (Touche raccourcie : `F10`) :** Ouvre l'interface NUI BloodAdmin (si vous êtes enregistré comme staff).
- **`/report` :** Permet aux joueurs d'ouvrir l'interface de création de ticket d'aide en jeu.
- **`/admin_debug` :** Permet de diagnostiquer les erreurs de permissions SQL directement depuis la console du serveur ou le chat.

---

## 🛠️ Diagnostic & Résolution des Problèmes

### 🔴 Le menu ne s'ouvre pas avec F10 ou /admin :
1. **Vérifiez votre statut de staff :** Tapez `/admin_debug` en jeu et ouvrez votre console serveur (F8).
   * Si le statut indique `NON TROUVÉ`, votre licence Rockstar n'a pas été entrée correctement ou vous n'avez pas lié le bon identifiant. Copiez la licence affichée par la commande et insérez-la dans votre table `bl_staff` en suivant la **Méthode 3**.
2. **Vérifiez le démarrage :** Assurez-vous que la console n'affiche pas d'erreurs d'import SQL au démarrage du script.
3. **Vérifiez la table `bl_grades` :** Au tout premier démarrage, `bl_admin` insère automatiquement les configurations de permissions de votre `config.lua` dans la table `bl_grades`. Assurez-vous que cette table existe et est bien remplie.

---

## 📈 Performances

- 💤 **En veille :** `0.00 ms` dans le moniteur de ressources FiveM.
- ⚡ **En cours d'utilisation :** `0.01 ms` - `0.03 ms` (selon l'utilisation active du noclip, du spectate ou de l'invisibilité).

---

<div align="center">
  <p><i>Développé avec passion par <b>BloodLeak</b>. Des designs haut de gamme et des performances optimisées pour votre communauté FiveM.</i></p>
</div>


