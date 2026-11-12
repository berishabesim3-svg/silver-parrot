extends "res://stage/stage_base.gd"
## Stazhi 10 - "Kori i Lagunës". Lidhja me një ekosistem të tërë.
## Çifti: Stazhi 1, me gjeometri të pasqyruar dhe rol të kthyer:
## tani lojtari e nis motivin nga kujtesa (lead) dhe laguna përgjigjet.

func _stage_config() -> Dictionary:
	var thirrja := Campaign.get_motif("thirrja", [0, 2, 1])
	var pergjigjja := Campaign.get_motif("pergjigjja", [1, 2, 0])
	var kori: Array = thirrja.duplicate()
	kori.append_array(pergjigjja)
	var helped := Campaign.has_ally("gjemba")
	return {
		"id": "10",
		"title": "Stazhi 10 - Kori i Lagunës",
		"mirror": -1.0,
		"sky": Color(0.95, 0.75, 0.55),
		"ground": Color(0.3, 0.55, 0.5),
		"perch": Color(0.5, 0.4, 0.55),
		"gusts": true,
		"ally_bridge": "gjemba",
		"intro_cue": "Laguna hesht. Pret dikë që ta nisë këngën",
		"stations": {
			# Nëse Gjemba është ndihmuar në Stazhin 1, ajo i tregon notat që në fillim.
			"prova3": {"id": "bretkosat", "mode": "lead", "motif": thirrja, "assist_from_start": helped, "color": Color(0.3, 0.7, 0.35)},
			"kulmi": {"id": "kori", "mode": "lead", "motif": kori, "color": Color(0.9, 0.8, 0.4)},
		},
		"rewards": {
			"allies": ["laguna"],
			"motifs": {"kori": kori},
			"flags": ["laguna_zgjuar"],
		},
		"outro": "Bretkosat, gjinkallat dhe zogjtë këndojnë bashkë. Laguna u zgjua.",
		"text": {
			"z_hyrje": "Laguna pret. Ti e di këngën tashmë.",
			"z_prova1": "Era fryn 4 rrahje dhe pushon 4. Kalo kur shtjella zhduket ose drejtohu kundër saj.",
			"z_cp1": "Pushim. Djathtas: purtekat e kallamave. Majtas: gurët e ujit me fshirëse.",
			"z_rrugaA": "Purteka të vogla mbi ujë: freno dhe ulu butë.",
			"z_rrugaB": "Bishtat fshijnë gurët me rrahjen. Shmangu.",
			"z_cp2": "Rrugët bashkohen te bregu i bretkosave.",
			"z_prova3": "Nise ti thirrjen e Gjembës nga kujtesa. Bretkosat do të përgjigjen.",
			"z_kulmi": "Erë dhe fshirëse bashkë. Laguna të ndjek me sy.",
			"z_fund": "Kthesa: udhëhiq korin. Thirrja dhe përgjigjja, gjashtë nota pa ndalur.",
		},
	}
