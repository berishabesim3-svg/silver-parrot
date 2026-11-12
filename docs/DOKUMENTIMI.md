# Silver PARROT — Dokumentimi i dorëzimit të parë

Data: 12 nëntor 2026 · Motori: Godot 4.x (GDScript) · Shtrirja: kontrolluesi i përbashkët + çifti 1 ↔ 10

## 1. Çfarë u ndërtua

| Pjesa | Skedari | Gjendja |
|---|---|---|
| Kontrollues i përbashkët (ngritje, planim, frenim, ulje, shmangie, nota) | `player/cockatoo.gd` | i shkruar, i paekzekutuar |
| Trup i përkohshëm me sy, kreshtë dhe peshë komike | `player/cockatoo_visual.gd` | i përkohshëm, pret referencat |
| Kamera me horizont të drejtë | `player/follow_camera.gd` | i shkruar, i paekzekutuar |
| Baza e stazheve + Stazhi 1 + Stazhi 10 | `stage/`, `stages/` | i shkruar, i paekzekutuar |
| Muzikë adaptive me 4 shtresa, e sintetizuar në kod | `autoload/audio_director.gd` | i shkruar, i paekzekutuar |
| Aksesueshmëri, fushatë, telemetri | `autoload/` | i shkruar, i paekzekutuar |
| Prova funksionale (rreth 70 kontrolle) | `tests/test_runner.gd` | të shkruara, të paekzekutuara |

Asgjë nuk është nisur në Godot. Çdo numër më poshtë është vlerë dizajni, jo matje.

## 2. Kontrolluesi

| Veprimi | Rregulli | Vlera |
|---|---|---|
| Ngritje | çdo shtypje jep shtytje lart; 3 rrahje, rimbushen në tokë | 8.5 m/s, rreth 1.6 m për rrahje |
| Planim | mbaj butonin në rënie | rënia kufizohet në 2.2 m/s |
| Frenim | ndal lëvizjen horizontale, në ajër edhe hap krahët | 18 m/s² |
| Ulje precize | prek tokën nën 3.5 m/s | mbi këtë: pengim 0.35 s dhe shtypje e trupit |
| Shmangie | hov anësor pa lëndim | 0.28 s, pushim 0.9 s |
| Nota | tri nota: La, Do, Mi | ● ▲ ■ |

Loja i mëson veprimet me situata: hendeku i parë kërkon ngritje, hendeku i gjatë kërkon planim, purteka e vogël kërkon frenim, shtegu i rrënjëve kërkon shmangie.

## 3. Ritmi i përbashkët i çiftit 1 ↔ 10

Të dy stazhet kanë të njëjtin skelet: **Prova 1 → pushim → Prova 2 me dy rrugë → ribashkim → Prova 3 → Kulmi me kthesë**. Sfidat janë menduar për 20–40 sekonda, me platformë pushimi midis tyre. Synimi i kalimit të parë është 4–6 minuta.

### Harta e rrugëve (pamje nga lart, lojtari ecën poshtë)

```
            [ HYRJA ]  start
                |
   Prova 1: 3 hendeqe + purtekë e vogël
                |
            [ CP1 ]  pushim, degëzimi
           /         \
  Rruga A             Rruga B
  4 purteka të larta  shteg i ulët 34 m
  frenim + ulje       3 fshirëse në ritëm
           \         /
            [ CP2 ]  ribashkimi
                |
   Prova 3: fraza e parë  →  CP3
                |
   Kulmi: purtekë, fshirëse, purtekë
                |
            [ FUNDI ]  fraza me kthesë
```

Stazhi 10 përdor të njëjtën hartë të pasqyruar majtas-djathtas, me dy shtjella ere shtesë.

### Si lidhen dy stazhet

| | Stazhi 1 — Jehona e Parë | Stazhi 10 — Kori i Lagunës |
|---|---|---|
| Me kë lidhet lojtari | një individ: Gjemba, iriq i trembur | një ekosistem: bretkosa, gjinkalla, zogj |
| Roli në frazë | kafsha thërret, lojtari përsërit | lojtari e nis nga kujtesa, laguna përgjigjet |
| Prova 3 | motivi La–Mi–Do | i njëjti motiv, pa thirrje |
| Kthesa e kulmit | Gjemba përgjigjet me motiv të ri: Do–Mi–La | lojtari bashkon të dy motivet, 6 nota |
| Rreziku shtesë | asnjë | erë 4 rrahje ndezur, 4 fikur |
| Pasoja | Gjemba bëhet aleate, dy motive ruhen | laguna zgjohet |

**Pasoja që ndihet më pas.** Nëse Gjemba është ndihmuar, në Stazhin 10 shfaqet një urë e vogël në mes të kulmit dhe notat e Provës 3 tregohen që në fillim. Pa të, ura mungon dhe lojtari duhet ta kujtojë motivin vetë. Për Stazhin 2 ruhet flamuri `gjemba_te_beson`.

## 4. Tabela e sinjaleve

Çdo ngjarje zanore ka edhe sinjal vizual.

| Ngjarja | Tingulli | Sinjali vizual | Kur |
|---|---|---|---|
| Rrahja | pulsi i shtresës bazë | katrori lart djathtas ndizet | çdo rrahje, 96 BPM |
| Nota e kafshës | tel i ulët | ikonë e zbehtë ● ▲ ■ | në rrahje, gjatë thirrjes |
| Çasti për t'u përgjigjur | — | ikona ndizet plotësisht | në rrahjen e pritur |
| Nota e lojtarit | tel i lartë | ikonë e gjelbër | kur pranohet |
| Hyrje në provë | shtresa e rrezikut | titër + përqindja e shtresës | në rrahjen e radhës |
| Erë | — | titër një rrahje përpara, pastaj kuti e tejdukshme | cikël 8 rrahjesh |
| Fshirëse | lëviz me rrahjen | kub i kuq | periudhë 2 ose 4 rrahje |
| Dështim | titër "tingull rënieje" | flash i kuq (ose vetëm tekst) + emri i pengesës | menjëherë |
| Rikuperim | shtresa e rikuperimit, 4 rrahje | përqindja e shtresës | pas rifillimit |
| Checkpoint | titër | mesazh i gjelbër | në hyrje |

Shtresat e muzikës: **bazë** gjithmonë, **rrezik** sipas zonës (0–100%), **bashkëpunim** gjatë dhe pas frazave, **rikuperim** pas çdo rifillimi.

## 5. Emocioni për çdo skenë

| Skena | Emocioni | Çfarë e shkakton | Sytë | Kreshta | Qëndrimi | Tingulli | Kamera |
|---|---|---|---|---|---|---|---|
| Hyrja | kureshtje | dëgjon notat larg | të hapur | gjysmë e ngritur | pak përpara | vetëm baza | 6.5 m |
| Prova 1, rruga A | fokus | hendeqe, purteka të vogla | të ngushtuar | e shtrirë | fort përpara | rrezik 50–70% | 7 m |
| Rruga B, kulmi | alarm | fshirëse, erë | shumë të hapur | plotësisht lart | mbrapa | rrezik 80–100% | 8 m |
| Pushimet | lehtësim | arrin checkpoint | normalë | e lëshuar | drejt | rreziku bie | 6 m |
| Ulje precize | krenari | prek tokën butë | normalë | lart | gjoksi jashtë | titër "ulje e butë" | 5.5 m |
| Frazat, fundi | butësi | kafsha përgjigjet | të butë | poshtë | pak përpara | bashkëpunim 60–100% | 5 m |

## 6. Aksesueshmëria dhe drejtësia

- **Redukto lëkundjen**: kamera nuk dridhet fare.
- **Redukto flash-et**: dështimi tregohet vetëm me tekst.
- **Tolerancë më e gjerë ritmike**: dritarja rritet nga ±0.22 s në ±0.42 s.
- Toleranca lexohet vetëm kur nis përgjigjja. Ndryshimi i opsionit në mes të një fraze hyn në fuqi në provën tjetër.
- Fshirëset dhe era ndjekin orën e muzikës dhe nuk ndryshojnë shpejtësi.
- Kamera nuk rrotullohet anash dhe nuk ia merr kontrollin lojtarit.
- Rifillimi: 0.45 s nga dështimi te checkpoint-i.

## 7. Matjet (telemetry.json)

- dështimet sipas pengesës (`fshirese_2`, `rënie:z_prova1`, `fraze:jehona`)
- koha nga dështimi te riprovimi
- sa herë u mor rruga A dhe B
- çasti kur lojtari e parashikon sinjalin: në echo, kur të gjitha notat bien para ikonës; në lead, kur e kryen pa ndihmë

## 8. Kriteret e pranimit

| # | Kriteri | Si verifikohet |
|---|---|---|
| 1 | Çdo stazh ka dy rrugë, ribashkim, 4 checkpoint-e, tri prova, kulm | prova automatike |
| 2 | Rruga kritike kryhet në të dyja rrugët | prova automatike |
| 3 | Rifillimi nga checkpoint nën 1 s | prova automatike |
| 4 | Toleranca nuk ndryshon në mes të veprimit | prova automatike |
| 5 | Shtresa e rrezikut hyn dhe del në rrahje | prova automatike |
| 6 | Stazhi 1 ruan aleaten dhe motivet; Stazhi 10 i përdor | prova automatike |
| 7 | Kalimi i parë zgjat 4–6 minuta | lojë me dorë, 3 lojtarë të rinj |
| 8 | Rrugët A dhe B kanë vështirësi të krahasueshme | telemetri: dështime për rrugë |
| 9 | Çdo veprim mësohet pa tekst shpjegues | vëzhgim i lojës |
| 10 | Kakaduja përputhet me referencat | pas marrjes së imazheve |

Kriteret 1–6 kanë prova të shkruara por të paekzekutuara. Kriteret 7–10 kërkojnë lojë me dorë.

## 9. Tetë stazhet e tjera (dizajn, ende pa kod)

| Çifti | Tema | I pari | I dyti |
|---|---|---|---|
| 2 ↔ 9 | besimi | i beson një aleati të vetëm | koordinon një grup |
| 3 ↔ 8 | balanca nën presion | pasagjer | udhëheqës |
| 4 ↔ 7 | e njëjta trajektore | hedhje | kapje |
| 5 ↔ 6 | gjeometri e pasqyruar | nisja e lëvizjes | frenimi i saj |

Baza `stage_base.gd` e ka skeletin tri-prova-plus-kulm, kështu që çdo çift i ri shton vetëm mekanikën e vet dhe konfigurimin.

## 10. Çfarë mbetet

1. Të instalohet Godot dhe të nisen provat; gabimet e para të sintaksës ose të fizikës priten këtu.
2. Të dërgohen referencat e kakadusë për modelin përfundimtar.
3. Të rregullohen largësitë e hendeqeve pas lojës së parë me dorë.
4. Çiftet 2↔9 deri 5↔6.
