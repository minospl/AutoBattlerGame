# AutoBattlerDungeonGame

**AutoBattlerDungeonGame** to gra typu auto-battler z elementami dungeon crawlera, rozwijana w silniku **Godot 4.7 (Forward Plus)** przy użyciu języka **GDScript**.

Gra łączy taktyczne zarządzanie drużyną jednostek w fazie sklepu z automatyczną symulacją starć w czasie rzeczywistym.

---

## 🎮 Pętla Rozgrywki (Core Loop)

Rozgrywka opiera się na dwóch naprzemiennych fazach:
1. **Faza sklepu (Shop)** – gracz zarządza złotem, kupuje i sprzedaje jednostki, kupuje jedzenie/przedmioty jednorazowe w celu ulepszenia statystyk jednostek oraz kupuje relikty (pasywne modyfikatory). Może także odświeżać ofertę (roll) oraz zamrażać (freeze) wybrane karty na kolejny dzień. Obowiązuje tu zasada łączenia jednostek (mergowanie 3 takich samych jednostek tego samego poziomu w 1 silniejszy, max poziom 3).
2. **Faza walki (Battle)** – automatyczna symulacja starcia drużyny gracza z drużyną przeciwnika. Jednostki automatycznie ładują swoje paski akcji na podstawie prędkości wykonania (`cast_speed`) i wykonują ataki lub aktywują modyfikatory.

---

## ⚙️ Kluczowe Mechaniki

### Pozycjonowanie i Siatka 2x3
Pozycjonowanie ma kluczowe znaczenie strategiczne, ponieważ wiele modyfikatorów jednostek działa obszarowo (np. nakładanie tarczy na sąsiadujące sloty). Zależności pozycjonowania są rozwiązywane dynamicznie za pomocą klasy `TargetResolver`.

### Wspólne Punkty Życia Drużyny (Shared Team Health)
W walce jednostki nie posiadają indywidualnego paska HP.
- Przy starcie walki zdrowie wszystkich aktywnych jednostek sumuje się we wspólną pulę zdrowia drużyny (`health` oraz `max_health` klasy `BattleTeam`).
- Wszystkie otrzymywane obrażenia są odejmowane bezpośrednio od wspólnej puli zdrowia/tarczy całej drużyny.
- Przegrana następuje, gdy wspólne zdrowie drużyny spadnie do `0`.

### Statusy (Status Effects)
- **Poison (Trucizna):** Zadaje obrażenia równe liczbie ładunków co 1.0 sekundy.
- **Burn (Oparzenie):** Zadaje obrażenia równe liczbie ładunków co 0.5 sekundy, po czym zmniejsza liczbę ładunków o 1.
- **Electrocute (Porażenie):** Zwiększa otrzymywane obrażenia przez drużynę o wartość ładunku porażenia, gdy jednostka atakująca ma atak > 0.

### Obiektowy System Modyfikatorów
Każda zdolność jednostki, przedmiotu czy reliktu jest zaimplementowana jako modularny modyfikator dziedziczący po `UnitModifier`, `ItemModifier` lub `RelicModifier`.
- Zdolności definiują swoje wyzwalacze (np. `ON_BATTLE_START`, `ON_CAST`, `ON_DEATH`).
- Zamiast centralnego kodu z instrukcją `match`, zachowanie modyfikatorów jest w pełni hermetyzowane we własnych skryptach (folder `templates/modifiers/`), co ułatwia dodawanie nowej zawartości.

---

## 📁 Struktura Projektu

```
src/
├── assets/                  # Grafiki, animacje i inne zasoby wizualne
├── core/                    # Główny kontroler gry (GameRoot) oraz stan rozgrywki (RunState)
├── features/                # Moduły funkcjonalne rozgrywki:
│   ├── battle/              # Logika symulacji walki, pętla czasu rzeczywistego (BattleScene, BattleTeam)
│   ├── items/               # System jedzenia i przedmiotów jednorazowych (ItemData, ItemInstance)
│   ├── relics/              # System pasywnych reliktów wpływających na przebieg walki (RelicData, RelicInstance)
│   ├── shop/                # Logika i interfejs sklepu (ShopScene, ShopCard, BenchPanel, TeamPanel)
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

Szczegółowe plany rozwoju gry, podział na kamienie milowe (MVP/Alfa, Beta, Polerowanie, Balans/QA) oraz analizę ryzyk architektonicznych znajdziesz w pliku [project_road_map.md](file:///d:/Projekty/AutoBattlerDungeonGame/project_road_map.md). Aktualna lista zadań do wykonania oraz audytów kodu znajduje się w pliku [todo.md](file:///d:/Projekty/AutoBattlerDungeonGame/todo.md).
