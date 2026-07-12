# Raport z Audytu Kodu i Architektury (Poprawiona Lista Problemów)

Ten dokument zawiera pełną listę zidentyfikowanych problemów architektonicznych, wydajnościowych oraz czystości kodu w projekcie AutoBattlerDungeonGame, zaktualizowaną o decyzje projektowe podjęte przez użytkownika.

---

### 1. [ROZWIĄZANE] Wycieki pamięci przez cykle referencji (Reference Cycles) w modyfikatorach reliktów
- **Lokalizacja:** 
  - [healing_herb_relic.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/templates/modifiers/healing_herb_relic.gd), linia 9, funkcja `on_battle_start`
  - [poisonous_fangs_relic.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/templates/modifiers/poisonous_fangs_relic.gd), linia 9, funkcja `on_battle_start`
  - [thiefs_glove_relic.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/templates/modifiers/thiefs_glove_relic.gd), linia 11, funkcja `on_battle_start`
  - [shield_battery_relic.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/templates/modifiers/shield_battery_relic.gd), linia 8, funkcja `on_battle_start`
- **Krytyczne pytania & Problem:** Czy te lambda-funkcje nie powodują wycieku pamięci? Klasa `BattleTeam` dziedziczy po `RefCounted` (kontrolowanej przez licznik referencji). Kiedy modyfikator łączy sygnał `player_team.unit_casted.connect(func(...) -> void)` i w ciele tej anonimowej funkcji odwołuje się bezpośrednio do zmiennej `player_team` (lub `enemy_team`), kompilator GDScript automatycznie przechwytuje silną referencję (strong reference) do tego obiektu w domknięciu (closure) lambdy. Powstaje cykl referencji: `player_team` -> połączenie sygnału -> lambda -> `player_team`.
- **Logiczne uzasadnienie:** Ponieważ `BattleTeam` nie jest węzłem sceny (`Node`) usuwanym za pomocą `queue_free()`, lecz obiektem typu `RefCounted`, jego pamięć zostanie zwolniona tylko wtedy, gdy licznik referencji spadnie do zera. Cykl referencyjny blokuje to na zawsze, powodując wyciek pamięci instancji `BattleTeam` oraz powiązanych zasobów przy każdej pojedynczej walce.
- **Sugerowana zmiana:** Użyj słabej referencji (`WeakRef`), aby przełamać cykl referencji.
- **Status:** **[ROZWIĄZANE]** Zdecydowano o zastosowaniu bardziej eleganckiego, centralnego podejścia. W klasie `BattleTeamModel` dodano metodę `cleanup()`, która przy niszczeniu sceny walki (`_exit_tree()` w `battle_scene.gd`) wymazuje statusy oraz automatycznie odłącza wszystkie sygnały przy użyciu `get_signal_connection_list()`. Powoduje to zniszczenie anonimowych lambd i uwalnia silne referencje, pozwalając na całkowite i czyste zwolnienie pamięci obu modeli drużyn przy zachowaniu czystego kodu reliktów bez ostrzeżeń kompilatora.

---

### 2. Niewydajność i alokacja pamięci w pętli procesowej Tooltipu
- **Lokalizacja:** [card_tooltip.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_tooltip.gd), linia 256, funkcja `update_stats()` (oraz jej wywołanie w [battle_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_scene.gd), linia 295, funkcja `_process`)
- **Krytyczne pytania & Problem:** Dlaczego w każdym kroku pętli procesowej (co klatkę!) usuwane są i od nowa powielane węzły interfejsu użytkownika? W metodzie `update_stats()` wywoływana jest pętla czyszcząca stare dzieci z `stats_grid` (`child.queue_free()`), a następnie dla każdej statystyki tworzony jest nowy węzeł poprzez `stat_label_template.duplicate() as RichTextLabel` i dodawany za pomocą `add_child()`.
- **Logiczne uzasadnienie:** Ponieważ `battle_scene.gd` w pętli `_process` co klatkę wywołuje `preview_tooltip.update_stats()`, gra wykonuje kilkanaście operacji alokacji i zwalniania węzłów interfejsu na sekundę. Generuje to narzut na Garbage Collector, powodując mikro-przycięcia (garbage collector spikes) oraz drastycznie obniżając wydajność gry.
- **Sugerowana zmiana:** Zaimplementuj wielokrotne używanie istniejących węzłów (Object Pooling / Node Reuse). Aktualizuj właściwość `text` istniejących etykiet w `stats_grid`, ukrywaj nadmiarowe i twórz nowe za pomocą `duplicate()` tylko wtedy, gdy w gridzie jest ich za mało.

---

### 3. Złamanie zasady separacji Model-View-Controller w logice resetowania gry
- **Lokalizacja:** [shop_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd), linie 263–274, funkcja `_on_restart_requested`
- **Krytyczne pytania & Problem:** Dlaczego kontroler interfejsu sklepu bezpośrednio modyfikuje wewnętrzne tablice i stany modelu rozgrywki (`RunState`), czyszcząc modyfikatory ceny oraz wag i ręcznie emitując sygnały stanu?
- **Logiczne uzasadnienie:** Klasa `ShopScene` powinna być wyłącznie widokiem/kontrolerem prezentacji. Bezpośrednie czyszczenie pól `run_state.relics.clear()`, `run_state.price_modifiers.clear()`, `run_state.shop_weights_modifiers.clear()` i samodzielne wywoływanie `run_state.relics_changed.emit()` łamie zasadę hermetyzacji. Jeśli w przyszłości struktura danych `RunState` ulegnie zmianie, poprawki będą musiały być nanoszone bezpośrednio w skryptach UI sklepu.
- **Sugerowana zmiana:** Przenieś całą logikę czyszczenia i resetu stanu do dedykowanej metody wewnątrz `RunState` (np. `run_state.reset_for_new_run()`), która zajmie się modyfikacją stanu i wyemituje powiązane sygnały. W `shop_scene.gd` wywołuj wyłącznie tę jedną metodę.

---

### 4. Wyciek logiki losowania reliktów do klasy UI sklepu
- **Lokalizacja:** [shop_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd), linie 244–260, funkcja `_on_add_relic_requested`
- **Krytyczne pytania & Problem:** Dlaczego algorytm filtrowania unikalnych reliktów i losowania z listy szablonów znajduje się bezpośrednio w kontrolerze interfejsu?
- **Logiczne uzasadnienie:** Filtrowanie reliktów pod kątem tego, czy są unikalne (`is_unique`) oraz czy gracz już je posiada (`run_state.has_relic()`), a także losowanie za pomocą `randi()` to czysta logika gry (Model). `ShopScene` powinien jedynie wysyłać zapytanie o dodanie reliktu, natomiast to model powinien decydować, jaki relikt zostanie wylosowany i dodany do stanu rozgrywki.
- **Sugerowana zmiana:** Zaimplementuj funkcję `roll_and_add_random_relic()` bezpośrednio w klasie `RunState` i wywołaj ją z poziomu `ShopScene`.

---

### 5. Brak skalowalności i sztywno zakodowane ładowanie zasobów (Resource Eager Loading)
- **Lokalizacja:** [game_root.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/game_root.gd), linie 40–60, funkcje `_load_item_templates` i `_load_relic_templates`
- **Krytyczne pytania & Problem:** Czy ładowanie każdego szablonu przedmiotu i reliktu na stałe w kodzie za pomocą `preload()` jest skalowalne?
- **Logiczne uzasadnienie:** Jeśli projekt rozrośnie się do dużej liczby przedmiotów i reliktów, lista `preload` w `game_root.gd` stanie się olbrzymia, a silnik będzie musiał załadować wszystkie te zasoby do pamięci RAM już podczas uruchamiania gry.
- **Sugerowana zmiana:** Zaimplementuj dynamiczne skanowanie katalogu z zasobami (przy użyciu klasy `DirAccess`) lub stwórz jeden główny plik bazy danych zasobów (`ItemDatabase.tres`, `RelicDatabase.tres`), który będzie ładowany leniwie (Lazy Loading) lub w tle.

---

### 6. Programowe tworzenie przycisku reliktu oraz obejście systemu typów dekoratora
- **Lokalizacja:** [shop_header_bar.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_header_bar.gd), linie 44–61, funkcja `_ready`
- **Krytyczne pytania & Problem:** Dlaczego przycisk "Add Random Relic" oraz jego dekorator (`GameButtonDecorator`) są tworzone i konfigurowane programowo w kodzie (w dodatku z użyciem `load()` i `set_script()`), zamiast zostać dodane bezpośrednio w scenie `shop_header_bar.tscn`?
- **Logiczne uzasadnienie:** 
  1. Tworzenie elementów interfejsu w kodzie zmniejsza jego czytelność i utrudnia pracę z edytorem wizualnym Godota.
  2. Ręczne ładowanie skryptu z dysku i wywoływanie `set_script()` na surowym obiekcie `Node.new()` omija silny system typowania Godota (`class_name GameButtonDecorator`).
  Przeniesienie przycisku do sceny eliminuje oba te problemy jednocześnie – przycisk i jego dekorator będą zdefiniowane w scenie, a cały powiązany kod dynamiczny zostanie usunięty.
- **Sugerowana zmiana:** Przenieś przycisk `AddRelicButton` bezpośrednio do sceny [shop_header_bar.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_header_bar.tscn) (między `AddUnitButton` a `RestartButton`), dodając do niego dziecko `GameButtonDecorator` w edytorze. W skrypcie [shop_header_bar.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_header_bar.gd) zadeklaruj go jako `@onready var add_relic_btn: Button = %AddRelicButton` i połącz jego sygnał w `_ready()`, usuwając cały blok dynamicznego tworzenia (linie 44-61).

---

### 7. Niepotrzebna dynamiczna alokacja Callable w krytycznej ścieżce wyszukiwania celów
- **Lokalizacja:** [target_resolver.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/utils/target_resolver.gd), linie 24–27, zmienna lokalna `get_idx`
- **Krytyczne pytania & Problem:** Dlaczego wewnątrz metody statycznej `get_target_indices` deklarowana jest lokalna lambda `get_idx: Callable` przy każdym wywołaniu funkcji?
- **Logiczne uzasadnienie:** Metoda `get_target_indices` jest wywoływana bardzo często (np. przy rysowaniu linii celowania, hoverowaniu kart, symulacji walki). Alokowanie nowej lambdy w pamięci przy każdym jej wywołaniu narzuca niepotrzebny koszt wydajnościowy.
- **Sugerowana zmiana:** Zastąp lambdę zwykłym wyrażeniem matematycznym bezpośrednio w kodzie lub zadeklaruj `_get_idx` jako osobną, prywatną funkcję statyczną w tej samej klasie:
  ```gdscript
  static func _get_idx(r: int, c: int) -> int:
      if r >= 0 and r < 2 and c >= 0 and c < 3:
          return r * 3 + c
      return -1
  ```

---

### 8. Martwy kod (Zombie Properties) w RunState
- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd), linie 26–27, zmienne `price_modifiers` i `shop_weights_modifiers`
- **Krytyczne pytania & Problem:** Jaki jest sens istnienia zmiennych `price_modifiers` oraz `shop_weights_modifiers`, skoro w całym projekcie nie ma kodu dodającego do nich jakiekolwiek wartości?
- **Logiczne uzasadnienie:** Zmienne te zajmują pamięć, są niepotrzebnie serializowane przy zapisie stanu gry, a ich czyszczenie w `shop_scene.gd` wprowadza zbędne instrukcje. W szczególności `price_modifiers` nie jest w ogóle odczytywane w logice obliczania ceny zakupu przedmiotów w sklepie.
- **Sugerowana zmiana:** Usuń te właściwości lub przenieś je do roadmapy, aby nie zaśmiecały głównej klasy stanu gry.

---

### 9. Bezpośrednie przekazywanie mutowalnych referencji stanu do symulacji walki
- **Lokalizacja:** [battle_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_scene.gd), linie 206–207, funkcja `load_battle_team`
- **Krytyczne pytania & Problem:** Dlaczego usunięto klonowanie reliktów i przypisano tablicę reliktów z `RunState` bezpośrednio jako referencję do `player_team.active_relics = run_state.relics`?
- **Logiczne uzasadnienie:** Jeśli dowolny relikt lub jego stan (np. liczba ładunków, wewnętrzne zmienne dynamiczne modyfikatora) ulegnie zmianie w trakcie symulacji walki, zmiana ta bezpośrednio zmodyfikuje stan całej rozgrywki (`RunState`). Ponadto, jeśli w walce podłączane są jakiekolwiek sygnały do instancji reliktów (lub ich modyfikatorów), to powrót do sklepu pozostawi te połączenia aktywne.
- **Sugerowana zmiana:** Przywróć klonowanie instancji reliktów przed rozpoczęciem symulacji walki, aby zagwarantować pełną izolację środowiska bitwy od stanu rozgrywki.

---

### 10. Powielona inicjalizacja shadera efektu wizualnego (DRY Violation)
- **Lokalizacja:** [card_tooltip.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_tooltip.gd), linie 200–203 oraz 222–225, funkcja `update_sprite`
- **Krytyczne pytania & Problem:** Dlaczego ten sam kod tworzenia `ShaderMaterial` i przypisywania shadera `CHROMA_KEY_SHADER` występuje dwukrotnie wewnątrz tej samej metody?
- **Logiczne uzasadnienie:** Powoduje to niepotrzebne powielenie kodu (DRY Violation). Dodatkowo, shader ten mógłby zostać przypisany raz na stałe w edytorze bezpośrednio do właściwości `material` węzła `sprite_rect` w pliku `.tscn`.
- **Sugerowana zmiana:** Usuń dynamiczną kreację shadera z funkcji `update_sprite()` i przypisz `chroma_key.gdshader` jako domyślny materiał węzła w scenie `card_tooltip.tscn`.

---

### 11. Ograniczenie bazy słów kluczowych (Keyword Database) wyłącznie do jednostek
- **Lokalizacja:** [card_tooltip.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_tooltip.gd), linie 73–75 oraz 83–85, funkcje `setup_for_item` i `setup_for_relic`
- **Krytyczne pytania & Problem:** Dlaczego przy wyświetlaniu tooltipu dla reliktu lub przedmiotu całkowicie pomijane jest generowanie słów kluczowych?
- **Logiczne uzasadnienie:** Niektóre relikty i przedmioty nakładają na drużynę statusy takie jak trucizna (`Poison`) czy oparzenie (`Burn`). Ponieważ jednak baza słów kluczowych `KeywordDatabase` obsługuje wyłącznie jednostki (`get_keywords_for_unit`), to gracz po najechaniu na relikt nakładający oparzenie (np. Fire Opal) nie otrzyma podglądu z wyjaśnieniem, czym jest i jak działa status "Burn".
- **Sugerowana zmiana:** Zrefaktoryzuj `KeywordDatabase`, aby mogła przyjmować instancję dowolnego modyfikatora i ekstrahować z niego powiązane słowa kluczowe (np. poprzez sprawdzenie metody `get_implied_keywords()` na modyfikatorze reliktu).

---

### 12. Wadliwy fallback i ignorowanie ograniczenia unikalności reliktów
- **Lokalizacja:** [relic_chest_modifier.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/templates/modifiers/relic_chest_modifier.gd), linie 18–22, funkcja `apply_shop_effect`
- **Krytyczne pytania & Problem:** Dlaczego w przypadku braku dostępnych reliktów o danej rzadkości system pozwala na ponowne wylosowanie i zduplikowanie reliktów oznaczonych jako `is_unique = true`?
- **Logiczne uzasadnienie:** Fallback ten całkowicie niweczy znaczenie flagi `is_unique` zadeklarowanej w `RelicData`. Jeśli gracz posiada już wszystkie relikty z danej puli rzadkości, a gra wylosuje duplikat reliktu unikalnego (np. Magnetic Core), to metoda `add_relic` w `run_state.gd` po prostu zwiększy jego liczbę stosów (`stacks += 1`). Jednak unikalne relikty nie posiadają skalowania na poziomie kodu modyfikatorów, co spowoduje marnowanie zasobów gracza na bezużyteczne stosy.
- **Sugerowana zmiana:** W sytuacji krytycznej (brak wolnych reliktów danej rzadkości) system powinien wylosować relikt o innej rzadkości lub zwrócić złoto graczowi, zamiast generować niefunkcjonalne duplikaty reliktów unikalnych.

---

### 13. Modyfikatory "On Battle Start" nie odpalają się dla przeciwnej drużyny (Enemy Team)
- **Lokalizacja:** [battle_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_scene.gd), funkcja `trigger_battle_start()` (linia 194)
- **Krytyczne pytania & Problem:** Dlaczego w momencie rozpoczęcia walki modyfikatory typu `ON_BATTLE_START` są wyzwalane wyłącznie dla drużyny gracza (`player_team`), a drużyna przeciwna (`enemy_team`) jest całkowicie pomijana?
- **Logiczne uzasadnienie:** Jeśli przeciwnik posiada w swojej drużynie potwory ze zdolnościami aktywowanymi na początku walki (np. Wild Wolf, który daje sąsiednim jednostkom buffa do ataku), zdolności te nigdy się nie uruchamiają dla przeciwnika. Sprawia to, że walka z wrogiem posiadającym takie jednostki nie odzwierciedla poprawnie jego faktycznej siły bojowej.
- **Sugerowana zmiana:** Wewnątrz funkcji `trigger_battle_start()` dodaj wywołanie wyzwalacza również dla `enemy_team`:
  ```gdscript
  for i: int in range(MAX_TEAM_SIZE):
      if player_team.units[i]:
          ModifierEngine.trigger_unit_modifier(i, player_team, UnitModifier.Trigger.ON_BATTLE_START)
      if enemy_team.units[i]:
          ModifierEngine.trigger_unit_modifier(i, enemy_team, UnitModifier.Trigger.ON_BATTLE_START)
  ```
