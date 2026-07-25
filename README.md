# AutoBattlerDungeonGame

**AutoBattlerDungeonGame** to gra typu **asynchroniczny PvP auto-battler** (inspirowana grami typu Super Auto Pets / 9 Kings / TFT), rozwijana w silniku **Godot 4.7 (Forward Plus)** przy użyciu języka **GDScript**.

Gra łączy taktyczne zarządzanie drużyną jednostek w fazie sklepu z automatyczną symulacją starć w czasie rzeczywistym przeciwko snapshotom drużyn innych graczy.

---

## 🎮 Pętla Rozgrywki (Core Loop)

Rozgrywka opiera się na $N$ rundach podstawowych przeciwko snapshotom biegów graczy (którzy zakwalifikowali się do finału) oraz końcowej fazie **Deathmatch**:

1. **Faza sklepu (Shop)** – gracz zarządza złotem, kupuje jednostki i przedmioty, zarządza drużyną (siatka 2x3) oraz ławką rezerwowych (6 miejsc), zamraża (freeze) karty oraz ulepsza poziom sklepu. Ponadto ma wgląd w **podgląd nadchodzącego przeciwnika (jego drużyny, pozycjonowania i HP)** z możliwością wymiany rywala za pomocą eventów/przedmiotów. Obowiązuje tu zasada łączenia jednostek (mergowanie 3 identycznych jednostek tego samego poziomu w 1 silniejszy, max poziom 3).
2. **Faza walki (Battle)** – automatyczna symulacja starcia drużyny gracza ze snapshotem przeciwnika. Jednostki ładują swoje paski akcji na podstawie prędkości wykonania (`cast_speed`) i wykonują ataki lub aktywują modyfikatory. Obrażenia zadawane są do wspólnej puli HP drużyny. Porażka odejmuje 1 życie z puli (domyślnie 5 żyć).
3. **Faza Deathmatch** – gracze, którzy przetrwają $N$ rund podstawowych z zachowanym przynajmniej 1 życiem, przechodzą do finałowej fazy eliminacyjnej, staczając pojedynki aż do wyłonienia jedynego zwycięzcy.

---

## ⚙️ Kluczowe Mechaniki

### Podgląd i Trwałość Przeciwników

W fazie sklepu gracz widzi dokładny skład i stan zdrowia nadchodzącego przeciwnika. Wylosowani przeciwnicy pozostają stałymi rywalami i mogą zostać zamienieni wyłącznie:

- po ich wyeliminowaniu z gry (gdy ich HP/życia spadną do 0),
- za pomocą specjalnego przedmiotu / wyboru w evencie.

### Pozycjonowanie i Siatka 2x3

Pozycjonowanie ma kluczowe znaczenie strategiczne, ponieważ wiele modyfikatorów jednostek działa obszarowo (np. nakładanie tarczy na sąsiadujące sloty). Zależności pozycjonowania są rozwiązywane dynamicznie za pomocą klasy `TargetResolver`.

### Wspólne Punkty Życia Drużyny (Shared Team Health)

W walce jednostki nie posiadają indywidualnego paska HP.

- Przy starcie walki zdrowie wszystkich aktywnych jednostek sumuje się we wspólną pulę zdrowia drużyny (`health` oraz `max_health` klasy `BattleTeamModel`).
- Wszystkie otrzymywane obrażenia są odejmowane bezpośrednio od wspólnej puli zdrowia/tarczy całej drużyny.
- Porażka w rundzie następuje, gdy wspólne zdrowie drużyny spadnie do `0`.

### Statusy (Status Effects)

- **Poison (Trucizna):** Zadaje obrażenia równe liczbie ładunków co 1.0 sekundy.
- **Burn (Oparzenie):** Zadaje obrażenia równe liczbie ładunków co 0.5 sekundy, po czym zmniejsza liczbę ładunków o 1.
- **Electrocute (Porażenie):** Zwiększa otrzymywane obrażenia przez drużynę o wartość ładunku porażenia, gdy jednostka atakująca ma atak > 0.

### Typy Jednostek i Archetypy (Unit Types)

- **Earth:** Shield.
- **Plant:** Max HP.
- **Water:** Heal/Cleanse (usuwanie negatywnych statusów).
- **Dragon:** Unique mods (unikalne modyfikatory i mechaniki akcji).
- **Beast:** Physical Damage.
- **Toxic:** Poison.
- **Electric:** Electrocute.
- **Fire:** Burn.

### Obiektowy System Modyfikatorów

Każda zdolność jednostki, przedmiotu czy reliktu jest zaimplementowana jako modularny modyfikator dziedziczący po `UnitModifier`, `ItemModifier` lub `RelicModifier`.

- Zdolności definiują swoje wyzwalacze (np. `ON_BATTLE_START`, `ON_CAST`, `ON_DEATH`).
- Zachowanie modyfikatorów jest zhermetyzowane we własnych skryptach (folder `templates/modifiers/`), co ułatwia dodawanie nowej zawartości.

---

## 📁 Struktura Projektu

```text
src/
├── assets/                  # Grafiki, animacje i inne zasoby wizualne
├── core/                    # Główny kontroler gry (GameRoot) oraz stan rozgrywki (RunState)
├── features/                # Moduły funkcjonalne rozgrywki:
│   ├── battle/              # Logika symulacji walki, pętla czasu rzeczywistego (BattleScene, BattleTeamModel)
│   ├── compendium/          # Scena kompendium (CompendiumScene) prezentująca listę kart i reliktów
│   ├── items/               # System jedzenia i przedmiotów jednorazowych (ItemData, ItemInstance)
│   ├── relics/              # System pasywnych reliktów wpływających na przebieg walki (RelicData, RelicInstance)
│   ├── shop/                # Logika i interfejs sklepu (ShopScene, ShopCard, BenchPanel, TeamPanel, ShopHeaderBar)
│   └── units/               # Definicje jednostek, ich instancji oraz modyfikatorów (UnitData, UnitInstance)
└── shared/                  # Wspólne skrypty i zasoby pomocnicze:
    ├── localization/        # Wersje językowe i tłumaczenia tekstów
    ├── shaders/             # Cieniowanie interfejsu (np. obramowanie HP, kluczowanie koloru chroma key)
    ├── ui/                  # Motyw gry (game_theme.tres), dekoratory przycisków oraz tooltipy (CardTooltip)
    └── utils/               # Silnik modyfikatorów (ModifierEngine) oraz wyznaczanie celów (TargetResolver)
```

---

## 🚀 Uruchomienie Projektu

1. Pobierz silnik **Godot Engine 4.7** (wersja wspierająca rendering **Forward Plus**).
2. Zaimportuj projekt, wskazując plik [project.godot](file:///d:/Projekty/AutoBattlerDungeonGame/project.godot).
3. Uruchom główną scenę projektu: [game_root.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/game_root.tscn).

---

## 🗺️ Roadmapa Rozwoju

Szczegółowe plany rozwoju gry, podział na kamienie milowe (MVP/Alfa, Beta, Polerowanie, Balans/QA) oraz analizę ryzyk architektonicznych znajdziesz w pliku [project_road_map.md](file:///d:/Projekty/AutoBattlerDungeonGame/project_road_map.md).
