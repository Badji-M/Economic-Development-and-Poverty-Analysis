# Transferts monétaires, pauvreté et inégalités au Sénégal

Microsimulation de l'impact de programmes de transferts monétaires ciblés sur la pauvreté et les inégalités au Sénégal, à partir des données de l'EHCVM 2018.

**Auteur :** Pape Mamadou BADJI (ENSAE Dakar, AS2)
**Date :** juin 2025
**Cours :** Economic Development and Poverty Analysis
**Outil :** Stata

---

## Question

Pour un même transfert de 100 000 FCFA par ménage, quel ciblage réduit le plus la pauvreté et les inégalités, et à quel coût pour l'État ?

## Méthodologie

### 1. Projection des données à 2023

Les données EHCVM 2018 sont projetées en 2023 :

- poids des ménages ajustés selon la croissance démographique (facteur 1,153) ;
- dépenses par tête ajustées selon la croissance du PIB (facteur 1,258) ;
- seuil de pauvreté ajusté selon l'inflation (facteur 1,235).

### 2. Scénarios de ciblage

| Scénario | Ménages bénéficiaires |
|---|---|
| 1 | Tous les ménages (transfert universel) |
| 2 | Ménages ruraux |
| 3 | Ménages avec un enfant de moins de 2 ans |
| 4 | Ménages ruraux avec un enfant de moins de 2 ans |
| 5 | Ménages avec un enfant de moins de 5 ans |
| 6 | Ménages avec un enfant de moins de 18 ans |
| 7 | Ménages avec une personne de plus de 65 ans |
| 8 | Ménages avec une personne en situation de handicap |

### 3. Indicateurs d'évaluation

Pour la situation initiale (2018 et 2023) et pour chaque scénario :

- **Indices FGT** : incidence (P0), profondeur (P1) et sévérité (P2) de la pauvreté ;
- **Indice de Gini** ;
- **Coût budgétaire total** en FCFA et en pourcentage du PIB ;
- **Efficacité** : réduction de la pauvreté obtenue par unité de coût.

Tous les calculs sont pondérés au niveau individuel.

## Contenu du dépôt

| Fichier | Description |
|---|---|
| `BADJI_Poverty_Analysis_AS2_2025.do` | Script Stata complet |
| `BADJI_Poverty_Analysis_AS2_2025.pdf` | Rapport et interprétation des résultats |
| `ehcvm_welfare_SEN2018.dta` | Base bien-être des ménages (EHCVM 2018) |
| `ehcvm_individu_SEN2018.dta` | Base individus (EHCVM 2018) |

## Reproduire l'analyse

Le script charge les données directement depuis ce dépôt GitHub, sans configuration locale.

1. Ouvrir `BADJI_Poverty_Analysis_AS2_2025.do` dans Stata.
2. Exécuter le script. Le package `ineqdeco` est installé automatiquement s'il est absent.
3. Les résultats sont exportés dans `Résultats_TP01.xlsx`.

## Source des données

Agence Nationale de la Statistique et de la Démographie (ANSD), Enquête Harmonisée sur les Conditions de Vie des Ménages (EHCVM) 2018, Sénégal.
