extends "res://stage/stage_base.gd"
## Stazhi 1 - "Jehona e Parë". Lidhja me një individ: iriqi-milingonangrënës Gjemba.
## Çifti: Stazhi 10. Këtu kafsha thërret dhe lojtari përsërit (echo).

func _stage_config() -> Dictionary:
	return {
		"id": "1",
		"title": "Stazhi 1 - Jehona e Parë",
		"mirror": 1.0,
		"sky": Color(0.55, 0.78, 0.95),
		"ground": Color(0.45, 0.65, 0.4),
		"perch": Color(0.6, 0.45, 0.3),
		"gusts": false,
		"intro_cue": "Tri nota të trembura vijnë nga larg",
		"stations": {
			"prova3": {"id": "jehona", "mode": "echo", "motif": [0, 2, 1], "color": Color(0.55, 0.4, 0.3)},
			"kulmi": {"id": "kthesa", "mode": "echo", "motif": [1, 2, 0], "color": Color(0.55, 0.4, 0.3)},
		},
		"rewards": {
			"allies": ["gjemba"],
			"motifs": {"thirrja": [0, 2, 1], "pergjigjja": [1, 2, 0]},
			"flags": ["gjemba_te_beson"],
		},
		"outro": "Gjemba të beson. Do të të presë në hyrje të Stazhit 2 dhe do të ndihmojë në Lagunë.",
		"text": {
			"z_hyrje": "Dikush këndon larg. Space / A: rrih krahët për t'u ngritur.",
			"z_prova1": "Mbaje Space / A në rënie për të planuar. Shift / LB frenon para purtekës së vogël.",
			"z_cp1": "Pushim. Majtas: purtekat e larta (frenim). Djathtas: shtegu i rrënjëve (shmangie, C / B).",
			"z_rrugaA": "Purteka të vogla: freno në ajër dhe ulu butë.",
			"z_rrugaB": "Fshirëset lëvizin me rrahjen. Shmangu me C / B.",
			"z_cp2": "Rrugët bashkohen. Zëri është afër.",
			"z_prova3": "Dëgjo tri notat e Gjembës, pastaj përsëriti në ritëm: ● J/X  ▲ K/Y  ■ L/RB.",
			"z_kulmi": "Gjemba u tremb dhe iku. Ndiqe përtej fshirëses.",
			"z_fund": "Kthesa: Gjemba përgjigjet me motivin e vet. Dëgjoje dhe përsërite.",
		},
	}
