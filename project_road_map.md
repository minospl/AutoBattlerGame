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
*   **System Modyfikatorów i Szablonów:** Modułowa struktura, w której każdy modyfikator (np. [AncientTitanModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/templates/modifiers/ancient_titan_modifier.gd)) dziedziczy po [UnitModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/unit_modifier.gd) i sam definiuje swoje działanie. Istnieje 9 gotowych szablonów potworów (`.tres`).

### B. Obszary brakujące (Do Zaimplementowania)
*   **System Przedmiotów i Jedzenia (Item System):** Choć struktury danych ([ShopItemInstance](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/utils/shop_item_instance.gd)) oraz interfejs przeciągania jedzenia na jednostki ([ShopCardSlot](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_slot.gd)) istnieją i działają (zwiększają statystyki jednostki), **przedmioty nie spawnują się w sklepie** (linia 317 w `shop_scene.gd` na sztywno wymusza tylko potwory: `Always spawn Unit Cards, items are disabled for now`). Brak również plików szablonów `.tres` dla przedmiotów oraz bardziej zaawansowanych efektów (np. ekwipunek pasywny aktywujący się w walce).
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
| **Mechanika** | **Poziom Sklepu (Shop Level / Tiers):** Zaimplementowanie mechaniki poziomów sklepu. Ulepszanie sklepu (za złoto lub automatycznie z każdym dniem) zmienia wagi prawdopodobieństwa (szanse procentowe) losowania rzadszych kart przy odświeżaniu sklepu. | **Krytyczny** |
| **UI / UX** | **[x] Tooltip Rzadkości Przedmiotów:** Dostosowanie tooltipu przedmiotu ([CardTooltip](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_tooltip.gd)), tak aby wyświetlał tekstową etykietę rzadkości (Common, Rare, Legendary) oraz zmieniał barwy obramowania i tekstów odpowiednio do rzadkości (na wzór kart jednostek). | **Krytyczny** |
| **Refaktor** | **Model-View separation:** Zmiana architektury aktualizacji sklepu tak, aby to logiczny `RunState` decydował o zmianach, a UI tylko je odzwierciedlało (eliminacja błędów wyścigu przy drag-and-drop). | **Krytyczny** |
| **Refaktor** | **Poprawki Modyfikatorów (Typowanie i Null-Safety):** Dostosowanie istniejących skryptów modyfikatorów do ścisłego typowania w Godot 4.7 (bezpieczne rzutowanie `as UnitInstance` oraz guard clauses dla wartości `null` na wejściu). | **Krytyczny** |
| **Mechanika** | **Przedmioty Ekwipowalne:** Rozbudowa `ShopItemInstance` o przedmioty, które można założyć na jednostkę (max 1-2 na jednostkę), a nie tylko natychmiastowo skonsumować. | Opcjonalny |

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

## 3. Zagrożenia Architektoniczne i Wytyczne Typowania

Podczas skalowania gry należy zwrócić szczególną uwagę na trzy kluczowe aspekty architektury, które przy restrykcyjnym typowaniu w Godot 4.7 mogą prowadzić do błędów kompilacji lub trudnych do debugowania zachowań w czasie rzeczywistym.

### Zagrożenie 1: Synchronizacja danych poprzez UI (`sync_data_from_ui()`)
Obecnie interfejs sklepu stosuje podejście, w którym fizyczne ułożenie kart w drzewie sceny (reprezentowane przez dzieci węzła `CardContainer`) jest źródłem prawdy dla logiki:
```gdscript
func sync_data_from_ui() -> void:
    for i: int in range(active_slot_count):
        active_team[i] = active_slots[i].get_unit_instance()
```
#### Ryzyko:
1.  **Asynchroniczność węzłów:** Metoda `queue_free()` usuwa węzły pod koniec klatki. Jeśli wywołamy `sync_data_from_ui()` natychmiast po usunięciu karty, `get_unit_instance()` może nadal zwrócić referencję do usuwanego obiektu lub wywołać błąd `Attempt to call function on a cleared instance`.
2.  **Operacje Drag & Drop:** Podczas przeciągania, karta tymczasowo zmienia rodzica (zostaje odpięta ze slotu). Jeśli w tym samym momencie wyzwolona zostanie synchronizacja, gra uzna, że slot jest pusty, co prowadzi do utraty jednostki.

#### Rekomendacja (Rozwiązanie):
Należy przejść na architekturę **Data-Driven (MVC)**.
*   Logiczny stan drużyny (`active_team` w `RunState`) musi być **jedynym źródłem prawdy**.
*   Wszelkie operacje (zakup, przesunięcie, sprzedaż) modyfikują najpierw tablicę w `RunState`.
*   UI powinno jedynie reagować na te zmiany (nasłuchiwać sygnałów z `RunState` i odświeżać widok kart). Dzięki temu UI staje się "głupią" warstwą prezentacji, a logika gry nie zależy od struktury drzewa sceny.

---

### Zagrożenie 2: Bez-Autoloadowa Architektura (State Passing)
Projekt celowo unika globalnych obiektów typu Singleton (Autoload), przekazując `RunState` bezpośrednio:
```gdscript
func setup(p_state: RunState, p_templates: Array[UnitData]) -> void:
    run_state = p_state
```
#### Ryzyko:
O ile izolacja stanu rozgrywki jest świetną praktyką ułatwiającą testowanie i pozwalającą na łatwy restart runs, o tyle przy wprowadzaniu systemów globalnych pojawia się problem:
1.  **Menedżer Audio (AudioManager):** Odtwarzanie dźwięków w tle nie powinno być przerywane przy przełączaniu sceny sklepu na walkę. Jeśli Audio będzie powiązane ze sceną sklepu/walki, muzyka będzie się ciągle restartować.
2.  **Menedżer Zapisów (SaveManager):** Wymóg wstrzykiwania go do każdej sceny, która potrzebuje zapisać stan gry, tworzy niepotrzebne powiązania kodu.

#### Rekomendacja (Rozwiązanie):
Należy zastosować podejście hybrydowe:
*   **Gameplay State (RunState):** Pozostaje lokalny i wstrzykiwany (brak Autoloada).
*   **Infrastruktura (Audio, VFX, Zapisy, Konfiguracja):** Zostaje wydzielona do dedykowanych Autoloadów (np. `AudioManager`, `VFXManager`, `SaveSystem`). Te obiekty nie przechowują logiki walki ani sklepu, a jedynie świadczą globalne usługi dla aktywnych scen.

---

### Zagrożenie 3: Ścisłe Typowanie w Godot 4.7 (Static Typing)
Włączone ostrzeżenia `untyped_declaration=1` oraz `unsafe_property_access=1` wymuszają pełne otypowanie kodu.

#### Ryzyko przy skalowaniu Modyfikatorów:
Obecnie każdy modyfikator wymaga stworzenia dedykowanej klasy GDScript dziedziczącej po `UnitModifier`. Ponieważ modyfikatory mają mieć pełną swobodę implementacji (nie tylko buffy statystyk, ale unikalne zachowania, sprawdzanie typów sojuszników, modyfikacja zasad), **dedykowane skrypty dla kart są najlepszym rozwiązaniem**. Przy 100+ jednostkach wyzwaniem staje się jednak utrzymanie czystości kodu oraz restrykcyjnego statycznego typowania w Godot 4.7.
Przykładowo, pobieranie sojuszników i sprawdzanie ich typów bez precyzyjnego rzutowania typów wygeneruje ostrzeżenia kompilatora o niebezpiecznym dostępie (`unsafe_property_access`). Tablica `shop_units: Array[Resource]` przechowująca różne typy zasobów również wymaga bezpiecznego filtrowania i jawnego rzutowania.

#### Rekomendacja (Rozwiązanie):
1.  **Jawne rzutowanie i typowanie kontenerów:** Zamiast mieszać typy w jednej tablicy `Array[Resource]`, lepiej rozdzielić je w strukturze danych (np. `shop_units: Array[UnitInstance]` i `shop_items: Array[ShopItemInstance]`). Jeśli typy muszą pozostać złączone, należy stworzyć wspólną klasę bazową (np. `class_name ShopPurchasable extends Resource`) i dziedziczyć z niej, aby zapewnić bezpieczny polimorfizm bez ciągłego rzutowania w dół.
2.  **Modularne, spersonalizowane skrypty modyfikatorów:** Zachowujemy pełną elastyczność i piszemy dedykowane skrypty modyfikatorów dla kart, ale dbamy o ich 100% type-safety (jawne rzutowanie typów przy pobieraniu sojuszników z `TargetResolver` i sprawdzaniu ich zasobów `UnitType` oraz rzutowanie na `BattleUnitInstance` przy modyfikacjach HP w walce).

---

## 4. Szczegółowe Przykłady Implementacji Kodu

Poniższe przykłady obrazują, jak proponowane koncepcje mogą zostać zaimplementowane w języku GDScript przy zachowaniu ścisłych reguł typowania w Godot 4.7.

### A. Architektura Data-Driven UI (MVC)
W architekturze zorientowanej na dane (MVC) stan jest zmieniany bezpośrednio w strukturze logicznej, a UI nasłuchuje zdarzeń i przeprowadza jednokierunkową aktualizację. Zapobiega to asynchronicznym problemom z usuwaniem węzłów z drzewa sceny (`queue_free()`) w trakcie trwania klatki fizyki lub rysowania.

#### Implementacja w warstwie danych (np. w rozszerzonym `RunState`):
```gdscript
# run_state.gd
signal state_changed

## Logiczne przesunięcie jednostki między slotami
func move_unit(from_bench: bool, from_idx: int, to_bench: bool, to_idx: int) -> void:
	var source_array: Array[UnitInstance] = bench if from_bench else active_team
	var target_array: Array[UnitInstance] = bench if to_bench else active_team
	
	if from_idx < 0 or from_idx >= source_array.size() or to_idx < 0 or to_idx >= target_array.size():
		return
		
	# Pobranie jednostek do zamiany
	var temp_source: UnitInstance = source_array[from_idx]
	var temp_target: UnitInstance = target_array[to_idx]
	
	# Dokonanie logicznej zamiany miejsc
	source_array[from_idx] = temp_target
	target_array[to_idx] = temp_source
	
	# Wyemitowanie sygnału powiadamiającego UI o zmianie danych
	state_changed.emit()
```

#### Implementacja w warstwie UI (np. w `ShopScene`):
```gdscript
# shop_scene.gd
# Zamiast odczytywać hierarchię węzłów i zapisywać stan, UI staje się reaktywne:

func _ready() -> void:
	# Połączenie sygnału z RunState do automatycznego odświeżania UI
	if run_state:
		run_state.state_changed.connect(_on_run_state_changed)

func _on_run_state_changed() -> void:
	# Odświeżenie widoku na podstawie stanu logicznego (Single Source of Truth)
	_populate_slots_from_data()

func _populate_slots_from_data() -> void:
	for i: int in range(active_slot_count):
		var logical_unit: UnitInstance = run_state.active_team[i]
		var slot: ShopCardSlot = active_slots[i]
		
		# Metoda display_unit tylko wizualizuje instancję, nie przechowuje logiki
		slot.display_unit(logical_unit) 
```

---

### B. Hybrydowe Autoloady (Global AudioManager)
Infrastrukturalne systemy globalne są rejestrowane jako Autoloady (Singletons), co zapewnia do nich dostęp z każdego poziomu scen, bez zakłócania cyklu życia lokalnych zasobów takich jak `RunState`.

#### Menedżer dźwięku z pełnym typowaniem statycznym:
```gdscript
# src/shared/autoloads/audio_manager.gd
# Plik skonfigurowany w Project Settings jako Autoload pod nazwą 'AudioManager'
class_name AudioManager
extends Node

# Type-safe preloader dla zasobów audio
const SFX_BUY_CARD: AudioStream = preload("res://src/assets/audio/sfx_buy.wav") as AudioStream
const SFX_FREEZE_SLOT: AudioStream = preload("res://src/assets/audio/sfx_freeze.wav") as AudioStream

var _sfx_player: AudioStreamPlayer
var _bgm_player: AudioStreamPlayer

func _ready() -> void:
	# Inicjalizacja stałych odtwarzaczy na poziomie korzenia (root viewport)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)
	
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Music"
	add_child(_bgm_player)

func play_sfx(sfx_stream: AudioStream) -> void:
	if not sfx_stream:
		return
	# Bezpieczne odtworzenie sfx
	_sfx_player.stream = sfx_stream
	_sfx_player.play()

func play_music(music_stream: AudioStream) -> void:
	if not music_stream or _bgm_player.stream == music_stream:
		return
	_bgm_player.stream = music_stream
	_bgm_player.play()
```

#### Przykład wywołania z UI sklepu (np. `shop_scene.gd`):
```gdscript
# shop_scene.gd
func _on_card_clicked(card: ShopCard) -> void:
	# Logika zakupu jednostki ...
	
	# Globalne wywołanie dźwięku zakupu. 
	# Dzięki rejestracji Autoloada klasa AudioManager jest dostępna globalnie:
	var audio: AudioManager = get_node("/root/AudioManager") as AudioManager
	if audio:
		audio.play_sfx(AudioManager.SFX_BUY_CARD)
```
