# Silver PARROT — prototip Godot 4.x

Aventurë 3D në vetën e tretë: një kakadu e bardhë me kreshtë të verdhë fluturon shkurt, ulet me saktësi dhe u flet kafshëve me një instrument me tela. Ky dorëzim përmban kontrolluesin e përbashkët dhe çiftin e plotë **Stazhi 1 ↔ Stazhi 10**.

## Nisja

1. Instalo Godot 4.2 ose më të ri (versioni standard, jo .NET) nga godotengine.org.
2. Hap Godot → **Import** → zgjidh `project.godot` në këtë dosje → **Import & Edit**.
3. Shtyp **F5**. Hapet menyja: Stazhi 1, Stazhi 10, opsionet e aksesueshmërisë.

## Kontrollet

| Veprimi | Tastierë | Gamepad |
|---|---|---|
| Lëvizje | W A S D | Leva e majtë |
| Kamera | Q / E, shigjetat, miu (kliko për ta kapur) | Leva e djathtë |
| Ngritje (3 rrahje krahësh) | Space | A |
| Planim | mbaj Space në rënie | mbaj A |
| Frenim / ulje precize | Shift | LB |
| Shmangie | C ose Ctrl | B |
| Nota ● ▲ ■ | J K L | X Y RB |
| Meny | Esc | Back |

## Provat funksionale

```
godot --headless --path . res://tests/test_runner.tscn
```

Kodi i daljes është 0 kur kalojnë të gjitha. Provat mbulojnë rrugën kritike të Stazhit 1 dhe 10 në të dyja rrugët, rifillimin nga checkpoint, kyçjen e tolerancës ritmike, shtresat e muzikës dhe pasojën midis stazheve.

**Gjendja: provat nuk janë ekzekutuar ende.** Mjedisi ku u shkrua kodi nuk kishte Godot, prandaj as kodi dhe as provat nuk janë nisur asnjëherë. Rezultati i parë i matur del kur të nisësh komandën më lart.

## Struktura

- `autoload/` — hyrjet, opsionet, fushata, telemetria, muzika adaptive
- `player/` — kontrolluesi, trupi i përkohshëm, kamera
- `stage/` — baza e stazheve, fraza muzikore, fshirësja, era
- `stages/` — Stazhi 1 dhe 10 (vetëm konfigurim mbi bazën e përbashkët)
- `ui/` — HUD me titra për çdo ngjarje zanore
- `tests/` — provat funksionale
- `docs/DOKUMENTIMI.md` — dizajni, hartat, tabelat e sinjaleve, kriteret e pranimit

Të dhënat ruhen te `user://` (campaign.json, telemetry.json, settings.json).
