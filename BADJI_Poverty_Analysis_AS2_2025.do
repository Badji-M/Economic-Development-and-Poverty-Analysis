
*********************************************
***			Title  : TP01 - AS2 - Economic Development and Poverty Analysis
***			Files  : "EHCVM-2018"
***			Date   : 20 JUIN 2025
***	 		Author : Pape Mamadou BADJI
***                  Élève Analyste Statisticien (AS2) à l'ENSAE Dakar
***                  Email : papemamadoubadji82@gmail.com
*********************************************



*______________________________________________________________________________

/* ===========================================================================
   Étape 1 : Configuration et Chargement de la Base 2018
   ===========================================================================
*/

* Define root
global chemin ="https://raw.githubusercontent.com/Badji-M/Economic-Development-and-Poverty-Analysis/main"


/* Charger la base principale (2018) */
use "${chemin}/ehcvm_welfare_SEN2018.dta",clear


/* ===========================================================================
   Étape 2 : Définition des Taux de Croissance
   ===========================================================================
*/
global pop_growth = 1.153      
global gdp_growth = 1.258     
global cpi_growth = 1.235    

/* ===========================================================================
   Étape 3 : Aging vers 2023
   ===========================================================================
*/
gen hhweight_23 = hhweight * $pop_growth 
replace pcexp   = dtot / (hhsize * def_spa * def_temp) 
gen pcexp_23    = pcexp * $gdp_growth        
gen zref_23     = zref  * $cpi_growth         
       

/* Sauvegarde de la base agée pour 2023 */
save base_2023.dta, replace


/* ===========================================================================
   Étape 4 : Fusion avec les Données Individuelles
   ===========================================================================
*/

use "${chemin}/ehcvm_individu_SEN2018.dta",clear

// Création des indicateurs
gen under5   = (age < 5)
gen under2   = (age < 2)
gen under18  = (age < 18)
gen elder    = (age > 65)
gen handicap = (handig == 1)

// Agrégation au niveau du ménage 
collapse (max) under5 under2 under18 elder handicap, by(hhid)
saveold temp_individu.dta, replace version(11)

/* Recharger la base agée et fusionner avec les indicateurs agrégés */
use base_2023.dta, clear
merge 1:1 hhid using temp_individu.dta
drop _merge

/* ===========================================================================
   Étape 5 : Définition des Scénarios de Transferts
   ===========================================================================
*/
gen scenario1 = 1                          
gen scenario2 = (milieu == 2)              
gen scenario3 = (under2 == 1)              
gen scenario4 = (milieu == 2 & under2 == 1) 
gen scenario5 = (under5 == 1)              
gen scenario6 = (under18 == 1)             
gen scenario7 = (elder == 1)               
gen scenario8 = (handicap == 1)            

/* ===========================================================================
   Étape 6 : Application des Transferts sur la Base agée (2023)
   ===========================================================================
*/
foreach i in 1 2 3 4 5 6 7 8 {
    // Montant du transfert pour chaque ménage éligible
    gen cout_transfer`i' = scenario`i' * 100000

    // Dépense par tête après transfert
    gen pcexp_tran`i' = pcexp_23 + (cout_transfer`i' / (hhsize * def_spa * def_temp))

    // Dépense totale après transfert
    gen dtot_transfer`i' = pcexp_tran`i' * hhsize * def_spa * def_temp

    // Coût total dépensé par le gouvernement pour ce ménage
    gen cout_total_menage`i' = cout_transfer`i' * hhweight_23
}


/* ===========================================================================
   Étape 7 : Calcul du Coût Total du Gouvernement par Scénario
   ===========================================================================
*/
foreach i in 1 2 3 4 5 6 7 8 {
    quietly sum cout_total_menage`i' 
    di "Coût total du gouvernement pour le scénario `i' : " ///
	%20.0f r(sum) " FCFA"
	di "     ➤ En milliards :                  " %20.0f r(sum)/1e9 " Milliards de FCFA"
	di "     ➤ En pourcentage du PIB : " %4.2f (r(sum) * 100) / 18619500000000 " %"
}

/* ===========================================================================
   Étape 8 : Sauvegarde de la Base Finale avec les Nouvelles Variables
   ===========================================================================
*/
gen poids = hhweight * hhsize
gen poids_23 = hhweight_23 * hhsize 
saveold base_finale_2023.dta, replace version(11)

clear
use "base_finale_2023.dta", replace

/* ===========================================================================
	Sauvegarde : Préparation export Excel
 ===========================================================================
 */
 
putexcel set "Résultats_TP01.xlsx", replace



/* ========================================================================
   Étape 9.01 : Indices FTG - GINI 6 Efficacité avant les transferts 
						(situation initiale - 2018)
   ======================================================================== */

	   capture which ineqdeco
	if _rc {
		display as text " Le package 'ineqdeco' n'est pas installé. Installation en cours..."
		ssc install ineqdeco, replace
	} 
	else {
		display as result " Le package 'ineqdeco' est déjà installé."
	}

   * Définition du seuil de pauvreté
global zref = 333440.5

   
	di "====================== SITUATION INITIALE - 2018 ======================"

	gen pauvre00 = pcexp < $zref
	gen gap1_00 = pauvre00 * (($zref - pcexp) / $zref)
	gen gap2_00 = pauvre00 * (($zref - pcexp) / $zref)^2

	//	Pondérations totales
	qui sum poids
	scalar total_wt18 = r(sum)
	
	//	Composantes pondérées
	gen wg0_00 = poids * pauvre00
	gen wg1_00= poids * gap1_00
	gen wg2_00= poids * gap2_00

	qui sum wg0_00
	scalar P0_00 = r(sum) / total_wt18

	qui sum wg1_00
	scalar P1_00 = r(sum) / total_wt18

	qui sum wg2_00
	scalar P2_00 = r(sum) / total_wt18

	//	Indices FTG (P0,P1,P2)
	di "Taux de pauvreté (P0)     = " %6.4f P0_00 * 100
	di "Profondeur pauvreté (P1)  = " %6.4f P1_00 * 100
	di "Sévérité pauvreté (P2)    = " %6.4f P2_00 * 100

	//	Indice de Gini
	qui ineqdeco pcexp [aw=poids]
	scalar Gini_18 = r(gini)
	di "Gini avant transfert = " %6.4f r(gini)
	
	di "=============================================================="

	// 	Export situation initiale 2018
	putexcel set "Résultats_TP01.xlsx", sheet("Initial_2018") modify
	putexcel A1=("Indicateur") B1=("Valeur")
	putexcel A2=("P0") B2=(P0_00*100)
	putexcel A3=("P1") B3=(P1_00*100)
	putexcel A4=("P2") B4=(P2_00*100)
	putexcel A5=("Gini") B5=(Gini_18)
	
	
	
/* ========================================================================
   Étape 9.02 : Indices FTG - GINI 6 Efficacité avant les transferts 
						(situation initiale - 2023)
   ======================================================================== */

   // Définition du seuil de pauvreté
global zref_23 = 411799

   
	di "====================== SITUATION INITIALE - 2023 ======================"

	gen pauvre0 = pcexp_23 < $zref_23
	gen gap1_0 = pauvre0 * (($zref_23 - pcexp_23) / $zref_23)
	gen gap2_0 = pauvre0 * (($zref_23 - pcexp_23) / $zref_23)^2

	//	Pondérations totales
	qui sum poids_23
	scalar total_wt = r(sum)
	
	//	Composantes pondérées
	gen wg0_0 = poids_23 * pauvre0
	gen wg1_0 = poids_23 * gap1_0
	gen wg2_0 = poids_23 * gap2_0

	qui sum wg0_0
	scalar P0_0 = r(sum) / total_wt

	qui sum wg1_0
	scalar P1_0 = r(sum) / total_wt

	qui sum wg2_0
	scalar P2_0 = r(sum) / total_wt

	//	Indices FTG (P0,P1,P2)
	di "Taux de pauvreté (P0)     = " %6.4f P0_0 * 100
	di "Profondeur pauvreté (P1)  = " %6.4f P1_0 * 100
	di "Sévérité pauvreté (P2)    = " %6.4f P2_0 * 100

	//	Indice de Gini
	qui ineqdeco pcexp_23 [aw=poids_23]
	scalar Gini_23 = r(gini)
	di "Gini avant transfert = " %6.4f r(gini)
	
	di "=============================================================="

	// 	Export situation initiale 2023
	putexcel set "Résultats_TP01.xlsx", sheet("Initial_2023") modify
	putexcel A1=("Indicateur") B1=("Valeur")
	putexcel A2=("P0") B2=(P0_0*100)
	putexcel A3=("P1") B3=(P1_0*100)
	putexcel A4=("P2") B4=(P2_0*100)
	putexcel A5=("Gini") B5=(Gini_23)


/* ========================================================================
   Étape 9 : Calcul des Indices FGT (P0, P1, P2) et Gini
					(Pour chaque scenario)
   ======================================================================== */

	//  Initialisation matrice résultats
matrix RES = J(8,8,.)
local noms "Universal Rural_only Children<2 Rural+<2 Children<5 Children<18 Elderly Disabled"

local row = 1 
//  Boucle sur les 8 scénarios
foreach i in 1 2 3 4 5 6 7 8 {

    di "========================= SCÉNARIO `i' ========================="

    // Variables auxiliaires
    gen pauvre`i' = pcexp_tran`i' < $zref_23
    gen gap1_`i'  = pauvre`i' * (($zref_23 - pcexp_tran`i') / $zref_23)
    gen gap2_`i'  = pauvre`i' * (($zref_23 - pcexp_tran`i') / $zref_23)^2

    // Composantes pondérées
    gen wg0_`i' = poids_23 * pauvre`i'
    gen wg1_`i' = poids_23 * gap1_`i'
    gen wg2_`i' = poids_23 * gap2_`i'

    qui sum wg0_`i'
    scalar P0_`i' = r(sum) / total_wt

    qui sum wg1_`i'
    scalar P1_`i' = r(sum) / total_wt

    qui sum wg2_`i'
    scalar P2_`i' = r(sum) / total_wt

	// Coût total du scénario
    qui sum cout_total_menage`i'
    scalar cout`i' = r(sum)

	//	Indices FTG (P0,P1,P2)
    di "Taux de pauvreté (P0)     = " %6.4f P0_`i' * 100
    di "Profondeur pauvreté (P1)  = " %6.4f P1_`i' * 100
    di "Sévérité pauvreté (P2)    = " %6.4f P2_`i' * 100
	
	//	Reduction de la pauvreté :
	di "Gain sur P0 = " %6.4f (P0_0 - P0_`i') 
	di "Gain sur P1 = " %6.4f (P1_0 - P1_`i')  
	di "Gain sur P2 = " %6.4f (P2_0 - P2_`i') 
	
	 // Efficacité
  
    di "    ➤ Efficacité brute              = " %22.20f ((P1_0 - P1_`i') / cout`i') 
    di "    ➤ Efficacité par milliard FCFA  = " %15.6f ((P1_0 - P1_`i') / cout`i') * 1e9
	
    qui ineqdeco pcexp_tran`i' [aw=poids_23]
    scalar Gini_`i' = r(gini)
    di "Gini après transfert scénario `i' = " %6.4f Gini_`i'

	matrix RES[`row',1] = P0_`i'*100
    matrix RES[`row',2] = P1_`i'*100
    matrix RES[`row',3] = P2_`i'*100
    matrix RES[`row',4] = (P0_0 - P0_`i')*100
    matrix RES[`row',5] = (P1_0 - P1_`i')*100
    matrix RES[`row',6] = (P2_0 - P2_`i')*100
    matrix RES[`row',7] = ((P1_0 - P1_`i') / cout`i') * 1e9
    matrix RES[`row',8] = Gini_`i'

    local ++row
    di "=============================================================="
}

	// Export des résultats nationaux
		putexcel set "Résultats_TP01.xlsx", sheet("Résumé_national") modify
		putexcel A1=("Scénario") B1=("P0") C1=("P1") D1=("P2") E1=("Gain P0") 
		putexcel F1=("Gain P1") G1=("Gain P2") H1=("Efficacité par Mds FCFA") 
		putexcel I1=("Gini")
		
		local r = 2
		foreach s in `noms' {
			putexcel A`r'="`s'"
			local ++r
		}
		
		putexcel B2 = matrix(RES)
		
		
	// 	Export coûts seuls
		putexcel set "Résultats_TP01.xlsx", sheet("Coûts") modify
		putexcel A1=("Scénario") B1=("Coût total (milliards FCFA)")
		local r = 2
		local i = 1
		foreach s in `noms' {
			scalar cout_final = cout`i' / 1e9
			putexcel A`r' = "`s'"
			putexcel B`r' = cout_final
			local ++r
			local ++i
		}
		
		
		
		
		
		
		
/* ========================================================================
   Étape 10 : Calcul des Indices FGT (P0, P1, P2) et Gini 
					par milieu (URBAIN ET RURAL)
   ======================================================================== */


use "base_finale_2023.dta", replace


// Liste des milieux pour boucle : 1 = Urbain, 2 = Rural
local milieux 1 2
local m_index = 1
foreach milieu of local milieux {

    // Recharger la base complète à chaque itération
    use "base_finale_2023.dta", clear

    // Garder uniquement le milieu courant
    keep if milieu == `milieu'

    di "================= Analyse pour milieu = `milieu' ================="

    // Calcul poids total pour ce milieu
    sum poids_23
    scalar total_wt = r(sum)

    // Situation initiale 2023 (avant transfert)
    gen pauvre0 = pcexp_23 < $zref_23
    gen gap1_0 = pauvre0 * (($zref_23 - pcexp_23) / $zref_23)
    gen gap2_0 = pauvre0 * (($zref_23 - pcexp_23) / $zref_23)^2

    gen wg0_0 = poids_23 * pauvre0
    gen wg1_0 = poids_23 * gap1_0
    gen wg2_0 = poids_23 * gap2_0

    qui sum wg0_0
    scalar P0_0 = r(sum) / total_wt
    qui sum wg1_0
    scalar P1_0 = r(sum) / total_wt
    qui sum wg2_0
    scalar P2_0 = r(sum) / total_wt

    qui ineqdeco pcexp_23 [aw=poids_23]
    scalar Gini_0 = r(gini)

    di "Situation initiale 2023 - Milieu `milieu'"
    di "Taux de pauvreté (P0)     = " %6.4f P0_0 * 100
    di "Profondeur pauvreté (P1)  = " %6.4f P1_0 * 100
    di "Sévérité pauvreté (P2)    = " %6.4f P2_0 * 100
    di "Indice de Gini             = " %6.4f Gini_0

	// Initialisation matrice par milieu
		matrix RESM = J(8,8,.)
		local noms "Universal Rural_only Children<2 Rural+<2 Children<5 Children<18 Elderly Disabled"
		
		
    // Boucle sur les 8 scénarios
	local row = 1
    forvalues i = 1/8 {
        gen pauvre`i' = pcexp_tran`i' < $zref_23
        gen gap1_`i'  = pauvre`i' * (($zref_23 - pcexp_tran`i') / $zref_23)
        gen gap2_`i'  = pauvre`i' * (($zref_23 - pcexp_tran`i') / $zref_23)^2

        gen wg0_`i' = poids_23 * pauvre`i'
        gen wg1_`i' = poids_23 * gap1_`i'
        gen wg2_`i' = poids_23 * gap2_`i'

        qui sum wg0_`i'
        scalar P0_`i' = r(sum) / total_wt
        qui sum wg1_`i'
        scalar P1_`i' = r(sum) / total_wt
        qui sum wg2_`i'
        scalar P2_`i' = r(sum) / total_wt

        qui sum cout_total_menage`i'
        scalar cout`i' = r(sum)

        qui ineqdeco pcexp_tran`i' [aw=poids_23]
        scalar Gini_`i' = r(gini)

        di "-------- Scénario `i' pour milieu `milieu' --------"
        di "Taux de pauvreté (P0)     = " %6.4f P0_`i' * 100
        di "Profondeur pauvreté (P1)  = " %6.4f P1_`i' * 100
        di "Sévérité pauvreté (P2)    = " %6.4f P2_`i' * 100
        di "Gain sur P0 = " %6.4f (P0_0 - P0_`i') 
        di "Gain sur P1 = " %6.4f (P1_0 - P1_`i')  
        di "Gain sur P2 = " %6.4f (P2_0 - P2_`i') 
        di "Efficacité brute              = " %22.20f ((P1_0 - P1_`i') / cout`i') 
        di "Efficacité par milliard FCFA  = " %15.6f ((P1_0 - P1_`i') / cout`i') * 1e9
        di "Gini après transfert scénario `i' = " %6.4f Gini_`i'
		
		di "=============================================================="
		
		matrix RESM[`row',1] = P0_`i'*100
        matrix RESM[`row',2] = P1_`i'*100
        matrix RESM[`row',3] = P2_`i'*100
        matrix RESM[`row',4] = (P0_0 - P0_`i')*100
        matrix RESM[`row',5] = (P1_0 - P1_`i')*100
        matrix RESM[`row',6] = (P2_0 - P2_`i')*100
        matrix RESM[`row',7] = ((P1_0 - P1_`i') / cout`i') * 1e9
        matrix RESM[`row',8] = Gini_`i'

        local ++row
    }
		local feuille : word `m_index' of `milieux'
		putexcel set "Résultats_TP01.xlsx", sheet("Milieu_`feuille'") modify
		putexcel A1=("Scénario") B1=("P0") C1=("P1") D1=("P2") E1=("Gain P0")
		putexcel F1=("Gain P1") G1=("Gain P2") H1=("Efficacité par Mds FCFA")
		putexcel I1=("Gini")

		local r = 2
		foreach s in `noms' {
			putexcel A`r' = "`s'"
			local ++r
		}

		putexcel B2 = matrix(RESM)

		local ++m_index

    di "=============================================================="
}
 
 
  di "le fichier de sortie excel ainsi que certaines bases sont dans :" 
  pwd