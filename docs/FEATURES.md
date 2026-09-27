## Suivi des epics

Refonte selon le prototype `weather_prototype.html` (5 onglets : Accueil,
Prévisions, Carte, Villes, Réglages). Données réelles : Open-Meteo (météo,
qualité de l'air, géocodage), RainViewer (radar), fonds CARTO/OpenStreetMap.
Les alertes sont déduites des prévisions (orages, rafales, fortes pluies,
neige, verglas, chaleur, froid, UV) et historisées 48 h par ville.

Source de vérité : `spec/Epics_UserStories_Meteo.xlsx`.

| Epic | Fonctionnalité | Stories | Statut |
|---|---|---:|---|
| E01 | Météo locale en temps réel | US01-US05 | ✅ implémenté |
| E02 | Alertes météo et catastrophes naturelles | US06-US09 | 🟨 en cours (push FCM à configurer) |
| E03 | Prévisions météo sur 24 heures | US10-US12 | ✅ implémenté |
| E04 | Prévisions météo sur 10 jours | US13-US15 | ✅ implémenté |
| E05 | Probabilité de pluie sur 10 jours | US16-US17 | ✅ implémenté |
| E06 | Direction et vitesse du vent sur 10 jours | US18 | ✅ implémenté |
| E07 | Qualité de l'air | US19-US20 | ✅ implémenté |
| E08 | Carte radar météo | US21-US23 | ✅ implémenté |
| E09 | Lever / coucher du soleil et phases lunaires | US24-US25 | ✅ implémenté |
| E10 | Gestion des villes | US26-US29 | ✅ implémenté |
| E11 | Paramètres d'unités et de formats | US30-US32 | ✅ implémenté |
| E12 | Notifications et widgets d'écran d'accueil | US33-US34 | 🟨 réglages + aperçu (widget natif à faire) |

## E01 - Météo locale en temps réel

| Story | Statut |
|---|---|
| US01 - Température et condition météo à l'ouverture | ✅ implémenté |
| US02 - Vent, humidité et pression | ✅ implémenté |
| US03 - UV, visibilité, point de rosée et élévation | ✅ implémenté |
| US04 - Actualisation manuelle | ✅ implémenté |
| US05 - Dernière donnée hors connexion | ✅ implémenté |

## E02 - Alertes météo et catastrophes naturelles

| Story | Statut |
|---|---|
| US06 - Notification push sur alerte de zone | 🟨 FCM intégré, fichiers Firebase à ajouter |
| US07 - Détail complet d'une alerte | ✅ implémenté |
| US08 - Tri par gravité | ✅ implémenté |
| US09 - Historique des 48 dernières heures | ✅ implémenté |

## E03 - Prévisions météo sur 24 heures

| Story | Statut |
|---|---|
| US10 - Prévisions heure par heure | ✅ implémenté |
| US11 - Probabilités de pluie, neige ou verglas | ✅ implémenté |
| US12 - Vent, rafales et direction heure par heure | ✅ implémenté |

## E04 - Prévisions météo sur 10 jours

| Story | Statut |
|---|---|
| US13 - Prévisions journalières sur 10 jours | ✅ implémenté |
| US14 - Probabilités pluie, neige, verglas et foudre | ✅ implémenté |
| US15 - Heure du coucher du soleil | ✅ implémenté |

## E05 - Probabilité de pluie sur 10 jours

| Story | Statut |
|---|---|
| US16 - Graphique à barres des probabilités | ✅ implémenté |
| US17 - Accès au radar de pluie animé | ✅ implémenté |

## E06 - Direction et vitesse du vent sur 10 jours

| Story | Statut |
|---|---|
| US18 - Courbe de direction et vitesse du vent | ✅ implémenté |

## E07 - Qualité de l'air

| Story | Statut |
|---|---|
| US19 - Niveau global de qualité de l'air | ✅ implémenté |
| US20 - Détail des six polluants | ✅ implémenté |

## E08 - Carte radar météo

| Story | Statut |
|---|---|
| US21 - Carte radar dynamique | ✅ implémenté |
| US22 - Sélection des couches météo | ✅ implémenté |
| US23 - Lecture / pause de l'animation radar | ✅ implémenté |

## E09 - Lever / coucher du soleil et phases lunaires

| Story | Statut |
|---|---|
| US24 - Cycle jour / nuit et horaires précis | ✅ implémenté |
| US25 - Phase lunaire du jour | ✅ implémenté |

## E10 - Gestion des villes

| Story | Statut |
|---|---|
| US26 - Rechercher et ajouter une ville | ✅ implémenté |
| US27 - Sélectionner la ville active | ✅ implémenté |
| US28 - Gérer les villes favorites | ✅ implémenté |
| US29 - Supprimer une ville enregistrée | ✅ implémenté |

## E11 - Paramètres d'unités et de formats

| Story | Statut |
|---|---|
| US30 - Unités température, précipitations, visibilité, vent, pression | ✅ implémenté |
| US31 - Format de l'heure (12 h / 24 h) | ✅ implémenté |
| US32 - Format de date | ✅ implémenté |

## E12 - Notifications et widgets d'écran d'accueil

| Story | Statut |
|---|---|
| US33 - Activer/désactiver alertes et résumé quotidien | 🟨 préférences enregistrées ; envoi du résumé non planifié |
| US34 - Widget d'écran d'accueil | 🟨 aperçu dans Réglages ; widget natif iOS/Android à développer |
