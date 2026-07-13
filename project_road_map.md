# Roadmapa Rozwoju i Analiza Architektoniczna: AutoBattlerDungeonGame

Dokument ten zawiera szczegółową analizę stanu obecnego projektu **AutoBattlerDungeonGame**, chronologiczny plan rozwoju (roadmapę) podzielony na kamienie milowe oraz ocenę ryzyka architektonicznego ze szczególnym uwzględnieniem restrykcyjnych reguł typowania w **Godot 4.7 (Forward Plus)**.

---

## 1. Analiza Stanu Obecnego

Na podstawie analizy kodu źródłowego w katalogu `src`, obecny stan projektu można podzielić na gotowe fundamenty oraz luki wymagające implementacji.

### A. Co stanowi fundament gry (Stan Gotowy)
*   **Główna pętla gry (Core Loop):** Klasa [GameRoot](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/game_root.gd) sprawnie zarządza przełączaniem scen między sklepem ([ShopScene](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd)) a walką ([BattleScene](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_scene.gd)) oraz przekazuje stan rozgrywki ([RunState](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd)) poprzez wstrzykiwanie zależności (`setup()`), unikając globalnych autoloadów.
*   **System Sklepu (Shop Mechanics):** Działa kupowanie jednostek (za 3g), zamrażanie (freeze) ofert, odświeżanie sklepu (roll za 1g), oraz sprzedaż jednostek z ławki lub drużyny. W pełni zaimplementowany jest algorytm łączenia jednostek (mergowanie 3 identycznych jednostek tego samego poziomu w jedną wyższego poziomu, maksymalnie do poziomu 3) w [RunState](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd).
*   **Pozycjonowanie i Siatka 2x3:** Logiczna siatka drużyny (6 slotów) i ławki (8 slotów). Zależności pozycjonowania są rozwiązywane przez helper [TargetResolver](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/utils/target_resolver.gd), co pozwala na precyzyjne nakładanie efektów (np. ADJACENT, HORIZONTAL, VERTICAL, UP, DOWN).
*   **Mechanika Wspólnego Zdrowia (Shared Health):** W walce jednostki nie posiadają indywidualnego paska HP. Ich punkty życia są sumowane do wspólnej puli drużyny ([BattleTeam](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_team.gd)). Obrażenia (zarówno fizyczne, jak i od statusów) są zadawane całej drużynie.
*   **Symulacja Walki:** System czasu rzeczywistego oparty o `cast_speed` każdej jednostki. Gdy pasek akcji się zapełni, jednostka wykonuje atak podstawowy, nakłada statusy lub leczy/nakłada tarcze. Zaimplementowano mechanikę zmęczenia (Fatigue) zadającą rosnące obrażenia Fibonacciego po 30 sekundach.
*   **System Modyfikatorów i Szablonów:** Modułowa struktura, w której każdy modyfikator (np. [AncientTitanModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/templates/modifiers/ancient_titan_modifier.gd)) dziedziczy po [UnitModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/unit_modifier.gd) i sam definiuje swoje działanie. Istnieje 8 gotowych szablonów potworów (`.tres`) oraz ich modyfikatorów.
*   **System Przedmiotów i Jedzenia (Item & Food System):** Wdrożono klasy bazowe [ItemData](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/item_data.gd), [ItemInstance](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/item_instance.gd) oraz [ItemModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/item_modifier.gd). Stworzono gotowe szablony jedzenia ([apple.tres](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/templates/apple.tres), [sword.tres](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/templates/sword.tres)), które spawnują się w sklepie (szansa 30%) i mogą być przeciągane na sojusznicze jednostki w celu stałego wzmocnienia statystyk.

### B. Obszary brakujące (Do Zaimplementowania)
*   **Relikty i Przedmioty Pasywne (Relics & Passive Items):** Choć jedzenie/przedmioty jednorazowe działają, brakuje reliktów (pasywnych modyfikatorów rozgrywki/walki wpływających na całą drużynę lub konkretne jednostki), które pomagają w rozgrywce (nie chodzi o tradycyjny ekwipunek typu hełm czy zbroja).
*   **Elementy Dungeon Crawler:** W tytule gry widnieje "Dungeon", lecz obecnie brakuje jakiejkolwiek eksploracji lochów. Gra to liniowy ciąg losowych walk dzień po dniu. Brakuje mapy lochu (np. rozgałęzionego drzewka z punktami), wydarzeń losowych (Dungeon Events) oraz walk z bossami.
*   **Typy Jednostek (Unit Types):** Klasa [UnitInstance](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/unit_instance.gd) pozwala na pobranie typów potwora (`get_types()`). Typy te nie będą zaimplementowane jako globalne, pasywne bonusy drużynowe (np. +X do ataku za posiadanie 3 potworów "Wodnych"). Zamiast tego będą wykorzystywane bezpośrednio wewnątrz modularnych modyfikatorów jednostek (np. +10 statystki "heal" dla sojusznika typu "Wodny").
*   **System Zapisywania Gry (Save/Load):** Cały stan gry istnieje wyłącznie w pamięci podręcznej. Zamknięcie okna gry powoduje utratę postępu rozgrywki.
*   **Dźwięk (Audio System):** Brak jakichkolwiek efektów dźwiękowych (SFX) dla kliknięć UI, przeciągania kart, ataków w walce, aktywacji modyfikatorów oraz muzyki w tle (BGM).
*   **Efekty Wizualne (VFX) i Animacje:** Brak dedykowanych animacji trafień, pocisków, efektów zaklęć, trzęsienia ekranu przy silnych ciosach czy płynnych przejść fazy sklepu w fazę walki.

---

## 2. Chronologiczna Roadmapa (Krok po Kroku)

Poniższa roadmapa została ustrukturyzowana tak, aby w pierwszej kolejności zamknąć podstawowe systemy rozgrywki, następnie rozbudować warstwę zawartości ("Dungeon"), a na końcu dopracować doznania audiowizualne.

### Kamień Milowy 1: Faza MVP / Alfa (Grywalny Szkielet Rozgrywki)
**Cel Główny:** Uruchomienie pełnego cyklu rozgrywki auto-battlera z działającymi przedmiotami oraz poprawkami typowania.

| Kategoria | Zadania do wykonania | Priorytet |
| :--- | :--- | :--- |
| **Mechanika** | **[x] Zunifikowany System Przedmiotów (Spawnowanie, Rzadkość i Modułowość):** Przebudowa przedmiotów na wzór potworów. Wdrożenie klas `ItemData`, `ItemInstance` oraz bazowej klasy `ItemModifier` (oddzielne skrypty dla efektów). Dodanie właściwości `is_draggable` (dla jedzenia/zwojów nakładanych na sojuszników) i `is_clickable` (dla natychmiastowych zakupów globalnych). Aktywacja generowania przedmiotów w sklepie (szansa 30% na slot przedmiotu) z przypisaną rzadkością (Rarity). | **Krytyczny** |
| **Mechanika** | **[x] Poziom Sklepu (Shop Level):** Zaimplementowanie mechaniki poziomów sklepu. Ulepszanie sklepu (automatycznie z każdym dniem) zmienia wagi prawdopodobieństwa (szanse procentowe) losowania rzadszych kart przy odświeżaniu sklepu. | **Krytyczny** |
| **UI / UX** | **[x] Tooltip Rzadkości Przedmiotów:** Dostosowanie tooltipu przedmiotu ([CardTooltip](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_tooltip.gd)), tak aby wyświetlał tekstową etykietę rzadkości (Common, Rare, Legendary) oraz zmieniał barwy obramowania i tekstów odpowiednio do rzadkości (na wzór kart jednostek). | **Krytyczny** |
| **Refaktor** | **[x] Model-View separation:** Zmiana architektury aktualizacji sklepu tak, aby to logiczny `RunState` decydował o zmianach, a UI tylko je odzwierciedlało (RunState jako źródło prawdy, eliminacja błędów wyścigu). Zaimplementowano reaktywne sygnały aktualizacji, a widoki sklepu i walki są całkowicie sterowane przez model. | **Krytyczny** |
| **Refaktor** | **[x] Poprawki Modyfikatorów (Typowanie i Null-Safety):** Dostosowanie istniejących skryptów modyfikatorów do ścisłego typowania w Godot 4.7 (bezpieczne rzutowanie `as UnitInstance` oraz guard clauses dla wartości `null` na wejściu). | **Krytyczny** |
| **Mechanika** | **[x] Relikty / Przedmioty Pasywne:** Rozbudowa systemu o relikty (pasywne modyfikatory wpływające globalnie na rozgrywkę/walkę). | Opcjonalny |
| **UI / UX** | **Galeria / Kompendium (Lista jednostek/przedmiotów/reliktów):** Nowa scena prezentująca listę wszystkich istniejących w grze jednostek, przedmiotów oraz reliktów wraz z ich statystykami i opisami (np. tymczasowo dostepna z widoku sklepu). | Opcjonalny |

---

### Kamień Milowy 2: Faza Beta (Dungeon Crawler i Skalowanie Zawartości)
**Cel Główny:** Dodanie elementu eksploracji lochów, urozmaicenie przeciwników i zaimplementowanie progresji trudności.

| Kategoria | Zadania do wykonania | Priorytet |
| :--- | :--- | :--- |
| **Mechanika** | **Generator Mapy Lochu (Node Map):** Stworzenie generowanej proceduralnie mapy (drzewo połączonych punktów) z różnymi typami lokacji: Walka, Sklep, Wydarzenie Losowe (Event), Skarb, Boss. | **Krytyczny** |
| **Mechanika** | **Wydarzenia Losowe (Events):** System tekstowych zdarzeń z wyborami (np. "Spotykasz rannego goblina. Oddaj 3 złota, by otrzymać losowy przedmiot lub zaatakuj go"). | **Krytyczny** |
| **Mechanika** | **Walki z Bossami:** Unikalne walki na koniec każdego lochu z bossami posiadającymi specjalne, wieloetapowe modyfikatory walki. | **Krytyczny** |
| **UI / UX** | **Ekran Mapy:** Interaktywny interfejs mapy lochów z płynnym przewijaniem i przejściami do odpowiednich scen. | **Krytyczny** |
| **UI / UX** | **Ekran Wydarzeń:** Czytelny panel dialogowy z ilustracjami generowanymi dynamicznie lub klimatyczną grafiką retro. | **Krytyczny** |
| **Mechanika** | **Nowe Jednostki i Modyfikatory:** Rozszerzenie puli potworów z 9 do 20+ oraz dodanie nowych mechanik celowania (np. atakowanie najsłabszego wroga, rykoszet). | Opcjonalny |
| **Mechanika** | **System Trudności (Ascension / Nowa Gra+):** Wybór poziomów trudności przed startem rozgrywki (np. wrogowie z wyższym HP/atakiem, mniejsze zarobki złota, szybsze zmęczenie Fatigue), znacząco wpływający na regrywalność. | Opcjonalny |

---

### Kamień Milowy 3: Polerowanie i Optymalizacja (UI/UX Premium, Muzyka, VFX)
**Cel Główny:** Doprowadzenie gry do poziomu "Premium UX" poprzez bogate animacje, efekty cząsteczkowe i zbalansowane udźwiękowienie.

| Kategoria | Zadania do wykonania | Priorytet |
| :--- | :--- | :--- |
| **UI / UX** | **Efekty Wizualne (VFX) w Walce:** Dodanie linii uderzeń, efektów cząsteczkowych przy trafieniach krytycznych i zaklęciach, oraz trzęsienia ekranu (Screen Shake) zależnego od siły ciosu. | **Krytyczny** |
| **UI / UX** | **Płynne Animacje UI:** Animowanie pojawiania się kart w sklepie, efektu zamrożenia (szron na karcie) oraz przejść między ekranami za pomocą biblioteki Tweens. | **Krytyczny** |
| **Refaktor** | **Optymalizacja Wydajności:** Profilowanie pętli walki. Cache'owanie wywołań shaderów, optymalizacja drawcalli poprzez łączenie elementów UI. | **Krytyczny** |
| **Refaktor** | **Optymalizacja pamięci:** Zapewnienie, że klonowane instancje jednostek w walce są poprawnie zwalniane z pamięci. | **Krytyczny** |
| **UI / UX** | **Statystyki Walki (Damage Meter):** Podsumowanie po bitwie wyświetlające graficzny raport/wykres (zadany atak, uleczone zdrowie, przyjęte tarcze) dla każdego potwora w drużynie. | Opcjonalny |

---

### Kamień Milowy 4: Wydanie (Balans i QA)
**Cel Główny:** Osiągnięcie idealnego balansu, usunięcie błędów, wdrożenie Menu Głównego oraz systemu zapisu gry dla stabilnej dystrybucji.

| Kategoria | Zadania do wykonania | Priorytet |
| :--- | :--- | :--- |
| **Mechanika** | **Balansowanie Statystyk:** Przetestowanie i zbalansowanie kosztów złota, przyrostu statystyk przy level-upach oraz siły modyfikatorów. | **Krytyczny** |
| **UI / UX** | **Menu Główne (Start Menu):** Stworzenie sceny startowej z logiem gry, przyciskami "Nowa Gra", "Kontynuuj" (aktywne tylko gdy istnieje zapis) oraz "Wyjdź". Integracja z `GameRoot` w celu przejścia do nowej gry lub załadowania istniejącej. | **Krytyczny** |
| **Mechanika** | **System Zapisu (Save/Load):** Napisanie menedżera zapisu, który serializuje obiekt `RunState` do pliku `user://savegame.json` lub `.tres` i wczytuje go przy starcie gry, umożliwiając kontynuację rozgrywki wywołaną przyciskiem "Kontynuuj". | **Krytyczny** |
| **UI / UX** | **Menu Ustawień (Settings Panel):** Implementacja panelu konfiguracji (suwaki głośności dla Muzyki/SFX, wybór trybu pełnoekranowego, rozdzielczości ekranu oraz zmiana języka). | **Krytyczny** |
| **UI / UX** | **Menedżer Dźwięku (Audio System):** Dodanie muzyki adaptacyjnej (spokojna w sklepie, dynamiczna w walce) oraz SFX (kupowanie, odświeżanie, uderzenie miecza, leczenie) na samym końcu prac nad grą. | **Krytyczny** |
| **Błędy / QA** | **Testy Automatyczne:** Napisanie testów jednostkowych (Unit Tests) symulujących 1000 automatycznych walk w tle w celu wykrycia ewentualnych nieskończonych pętli lub awarii silnika. | **Krytyczny** |
| **Refaktor** | **Finalna Weryfikacja Typowania:** Pełny przegląd kodu w poszukiwaniu ostrzeżeń kompilatora Godota w celu wyeliminowania ryzykownych rzutowań w locie. | **Krytyczny** |
| **UI / UX** | **Wersje Językowe (Localization):** Dokończenie systemu lokalizacji (polski/angielski) przy użyciu wbudowanego w Godot mechanizmu tłumaczeń. | Opcjonalny |

---

## 3. Przyszłe Rozszerzenia:

### **System reliktów**

Na podstawie wymagań projektowych zdefiniowano następujące źródła pozyskiwania reliktów w grze, do zrealizowania w kolejnych fazach rozwoju (np. przy wdrażaniu lochów/eventów):

1. **Zakup bezpośredni w sklepie (Wdrożone):**
   - Kupowanie klikalnych przedmiotów-skrzyń w sklepie, które po zakupie losują i dodają relikt o określonej rzadkości (`Common`, `Rare`, `Epic`, `Legendary`).
2. **Wydarzenia na mapie lochów (Kamień Milowy 2):**
   - Zdarzenia tekstowe / eventy generowane automatycznie co 3 dni na mapie lochów (np. oferujące graczowi wybór reliktu spośród kilku wylosowanych propozycji).
3. **Modyfikatory kart jednostek (Kamień Milowy 2 / Nowe modyfikatory):**
   - Zdolności potworów wyzwalane na koniec walki (np. *"On victory/defeat get a [Rarity] relic of [Level] level"*).

### **Zaawansowany System Statystyk (Stat Modifier Pattern)**
Jako przyszły refaktor w ramach rozwoju gry (np. przy wdrażaniu dziesiątek nakładających się efektów, aury i czasowych debufów w Kamieniu Milowym 3):
- **Wdrożenie modułowego systemu statystyk**: Przejście z uproszczonego podejścia "zmienna + dynamiczny getter" (np. `attack + ongoing_attack_bonus`) na pełny wzorzec **Stat Modifier**. Każda statystyka jednostki (zdrowie, atak, cast speed) stanie się osobnym obiektem (klasa `Stat`), który zarządza listą aktywnych modyfikatorów (`StatModifier` o typach FLAT i PERCENT) i automatycznie wylicza końcową wartość, co wyeliminuje ryzyko konfliktów przy nakładaniu się wielu różnych efektów.


