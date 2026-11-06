# U-Ride — Plateforme de Covoiturage Étudiant (Université de Saint-Boniface, Winnipeg)

> **"Your campus. Your ride. Your community."**

Ce dossier contient l'ensemble des livrables techniques et fonctionnels réalisés pour le projet **U-Ride**, conformément à la *Présentation Sommaire*, à la *Charte de Projet*, au *Cahier des Charges Fonctionnel et Technique*, et à la *Charte Graphique*.

---

## 1. Contenu du Projet

1. **`uride_app.html`** :
   - Application web interactive complète et autonome (MVP).
   - Intègre tous les flux utilisateurs (inscription, profils, publication de trajets, recherche avancée, algorithme SmartMatch, réservation en direct, messagerie instantanée, évaluations post-trajets, vérification étudiante USB).
   - Respecte à la lettre la charte graphique officielle :
     - **Bleu profond** : `#153B50` (navigation, titres, composants structurels)
     - **Turquoise** : `#167D8D` (boutons d'action, accents actifs)
     - **Vert doux** : `#5E9C76` (badges de vérification, disponibilité)
     - **Gris bleuté très pâle** : `#F0F6F7` (surfaces de fond, cartes)
     - **Anthracite** : `#2D3741` (typographie principale)
     - **Rouge alerte** : `#B42318` (statuts critiques, annulations)
   - Contient le bandeau de simulation multi-profils (Alexandre - Conducteur, Sophie - Passagère, Lucas - Conducteur) pour tester tous les rôles instantanément.

2. **`supabase_schema.sql`** :
   - Script SQL complet pour la base de données PostgreSQL de Supabase.
   - Tables : `profiles`, `rides`, `bookings`, `conversations`, `messages`, `reviews`.
   - Fonction stockée `calculate_smartmatch()` traduisant le score de correspondance.
   - Triggers automatiques de gestion du décompte des places de voiture.
   - Politiques de sécurité **Row Level Security (RLS)** pour protéger la vie privée des étudiants.

3. **`flutter_architecture_guide.md`** :
   - Guide d'architecture et arborescence de code recommandée pour la phase de portage mobile sous Flutter (Riverpod, Supabase Flutter SDK, GoRouter).

---

## 2. Matrice de couverture des exigences (F-01 à F-09)

| ID | Exigence du Cahier des Charges | Implémentation Prototype | Implémentation Backend (SQL) |
|---|---|---|---|
| **F-01** | Création de compte et session étudiante | Interface multi-utilisateurs & rôles | `auth.users` + table `profiles` |
| **F-02** | Gestion de profil (conducteur & passager) | Écran Profil, véhicule, préférences | Table `profiles` avec champs personnalisés |
| **F-03** | Vérification statut étudiant USB | Modal de validation `@ustboniface.ca` & badge officiel | Colonnes `is_verified`, `verified_at` |
| **F-04** | Publication de trajet régulier / ponctuel | Formulaire complet (quartiers, horaires, places, $ CAD) | Table `rides` avec type récurrent et array `days` |
| **F-05** | Recherche et filtrage des trajets | Filtres temps réel (quartiers de Winnipeg, heures, prix) | Requêtes filtrées indexées |
| **F-06** | SmartMatch (score de compatibilité) | Moteur de calcul affichant le score % et explications | Fonction PL/pgSQL `calculate_smartmatch()` |
| **F-07** | Demande & réservation de place | Gestion des statuts (en attente, confirmée, annulée) | Table `bookings` + trigger de décompte |
| **F-08** | Messagerie intégrée | Chat instantané avec réponses rapides étudiantes | Tables `conversations` et `messages` avec RLS |
| **F-09** | Évaluations & historique des trajets | Modal de notation 5 étoiles, tags et commentaires | Table `reviews` avec calcul de moyenne |

---

## 3. Lancement et Démonstration

Double-cliquez simplement sur le fichier `uride_app.html` dans n'importe quel navigateur moderne (Chrome, Edge, Safari, Firefox) ou affichez-le directement dans l'interface de prévisualisation Canvas.
