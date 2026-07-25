# TODO: Analiza i Plan Poprawek Projektu AutoBattlerDungeonGame (Posortowane według Priorytetu)

## 1. PRIORYTET 1: KRYTYCZNE BŁĘDY (Critical Bugs)

## Zadanie A [**ZROBIONE**]: Pusta drużyna gracza sprawia, że jest nieśmiertelny w walce (Dawne Zadanie 8)

- **Lokalizacja:** [battle_team_model.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_team_model.gd) (metoda `take_damage` linia 203), [battle_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_scene.gd) (metoda `trigger_battle_start`)
- **Krytyczne pytania & Problem:** Rozpoczęcie walki bez jednostek w drużynie ustawia `max_health` i `health` na 0. Sprawdzenie `max_health > 0 and health <= 0` w `take_damage()` nigdy nie wchodzi, co blokuje koniec walki. Gra zawiesza się w nieskończonej pętli.
- **Logiczne uzasadnienie:** Jeśli drużyna ma 0 HP (brak jednostek oraz brak bazowego HP), walka powinna natychmiast zakończyć się porażką. Jednakże, jeśli gracz ma bazowe HP (Zadanie K) oraz relikty pasywne, powinien móc walczyć bez jednostek (tzw. "relic-only build"). Dlatego NIE sprawdzamy liczby jednostek, a jedynie stan punktów życia (HP).
- **Sugerowana zmiana:**
  1. W `battle_team_model.gd` w metodzie `take_damage()` zmienić warunek porażki na:

     ```gdscript
     if health <= 0:
         team_defeated.emit()
     ```

  2. Na starcie bitwy (np. w `trigger_battle_start()`), jeśli początkowe `player_team.health <= 0` (brak jednostek i brak bazowego HP), wywołać natychmiastowy koniec bitwy:

     ```gdscript
     if player_team.health <= 0:
         show_battle_outcome("defeat")
         return
     ```

### Zadanie B [**ZROBIONE**]: Forest Guardian brak zmian w modyfikatorze na Poziomie 2 (Dawne Zadanie 15)

- **Lokalizacja:** [forest_guardian_modifier.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/templates/modifiers/forest_guardian_modifier.gd)
- **Krytyczne pytania & Problem:** Domyślne wartości tarczy (`value_1`, `value_2`, `value_3`) wynoszą `5` dla wszystkich trzech poziomów jednostki. Ulepszenie na poziom 2 nie daje silniejszego efektu.
- **Logiczne uzasadnienie:** Ulepszenie jednostki na wyższy poziom musi skalować jej zdolności. Na poziomie 2 wartość tarczy powinna wzrosnąć, a na poziomie 3 wartość pozostaje taka sama jak na poziomie 2, lecz zyskuje status permanentny.
- **Sugerowana zmiana:** Zmienić domyślne eksportowane wartości w skrypcie na: `@export var value_1: int = 5`, `@export var value_2: int = 10`, `@export var value_3: int = 10`. Upewnić się, że plik zasobu `.tres` nie nadpisuje tych wartości na sztywno.

---

## 2. PRIORYTET 2: KLUCZOWA PRZEBUDOWA SKLEPU (Core Shop Restructuring)

### Zadanie C [**ZROBIONE**]: Przebudowa sklepu: Cena na karcie i globalne zamrażanie sklepu (Dawne Zadanie 5)

- **Lokalizacja:** [shop_slot.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_slot.tscn), [shop_card_unit.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_unit.tscn), [shop_panel.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_panel.tscn), [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd)
- **Krytyczne pytania & Problem:** Każdy slot ma oddzielny przycisk "Freeze" i etykietę ceny na dole, co drastycznie zaśmieca UI sklepu. Dodatkowo sama karta potwora nie wyświetla swojej nazwy ani ceny bezpośrednio w swojej strukturze.
- **Logiczne uzasadnienie:** Przeniesienie ceny na kartę potwora/przedmiotu i dodanie jednego, globalnego przycisku "Zamroź Sklep" (Freeze Shop) znacznie uprości UI/UX. Dostosowanie wyglądu karty do przygotowanego makiety (mockupu) poprawi czytelność i profesjonalizm gry.
- **Wdrożone rozwiązanie:**
  1. **Struktura karty:** Przeniesiono cenę i nazwę bezpośrednio na stopkę karty ([shop_card_unit.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_unit.gd)).
  2. **Sterowanie slotami:** Usunięto przyciski zamrażania i etykiety cen z pojedynczych slotów.
  3. **Globalny Freeze:** W panelu sklepu ([shop_panel.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_panel.gd)) dodano przycisk "Freeze Shop".
  4. **Stan gry:** Zachowano tablicę `shop_frozen_statuses: Array[bool]` w [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd), co jest lepszym rozwiązaniem pod kątem UX (po zakupie jednostki nowo wylosowana karta w tym samym slocie nie jest automatycznie zamrażana). Globalny przycisk Freeze w UI odpowiednio synchronizuje stany w tablicy.

### Zadanie D [**ZROBIONE**]: Zwiększenie liczby kart w sklepie z 4 do 5 (Dawne Zadanie 7)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) (linia 6), [shop_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd) (linia 143)
- **Krytyczne pytania & Problem:** Liczba kart w sklepie jest na sztywno ustawiona na 4 w logice oraz w kodzie sceny sklepu.
- **Logiczne uzasadnienie:** Większy sklep (5 kart) ułatwia graczowi zbieranie par/trójek jednostek i stabilizuje pętlę gry, redukując negatywny wpływ losowości.
- **Wdrożone rozwiązanie:**
  1. Zwiększono stałą `MAX_SHOP_CARDS_SIZE` do `5` w [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) i dodano bezpieczną inicjalizację tablic w `_init()`.
  2. Zmieniono hardkodowany rozmiar w [shop_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd) na dynamiczny `run_state.shop_cards.size()`.

### Zadanie E [**ZROBIONE**]: Limit zakupów przedmiotów w sklepie i jednostki/relikty go modyfikujące (Dawne Zadanie 6)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) (metoda `roll_single_shop_card`, `apply_item`, `buy_clickable_item`), modyfikatory reliktów
- **Wdrożone rozwiązanie:**
  1. Wprowadzono zmienne `item_purchase_limit` (domyślnie 1) oraz `item_purchase_count` do stanu gry. Resetowanie licznika następuje przy nowym dniu w `complete_battle()`.
  2. Licznik `item_purchase_count` jest zwiększany po pomyślnym zakupie przedmiotu, co automatycznie wpływa na wylosowanie potwora na zwolnionym miejscu.
  3. Stworzono unikalny relikt **Shopping Bag** o rzadkości Rare, który w metodzie `on_acquire()` zwiększa limit `item_purchase_limit`.

### Zadanie F [**ZROBIONE**]: Dedykowane miejsce na przedmioty w sklepie - ostatni slot (Dawne Zadanie 4)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) (metoda `roll_single_shop_card` i wywołania w `roll_shop()`, `buy_unit()`, `apply_item()`, `buy_clickable_item()`, `change_shop_size()`)
- **Wdrożone rozwiązanie:**
  1. Metoda `roll_single_shop_card(slot_idx: int) -> Resource` przyjmuje i weryfikuje dynamiczny indeks slotu.
  2. Przedmioty losują się **wyłącznie** na ostatnim slocie sklepu (`slot_idx == shop_cards.size() - 1`) i tylko wtedy, gdy limit zakupów jedzenia nie został przekroczony.
  3. Pierwsze sloty zawsze losują potwory.
  4. Dodano mechanizm sprawdzający `has_any_item`, który zapobiega wylosowaniu drugiego przedmiotu (np. przy rozszerzaniu sklepu przez relikty, gdy zamrożony przedmiot przesunął się na wcześniejszą pozycję). Gwarantuje to obecność zawsze maksymalnie jednego przedmiotu w ofercie.

### Zadanie G [**ZROBIONE**]: Poprawa skalowania szans rzadkości w sklepie (Dawne Zadanie 14)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) (słownik `DAILY_SHOP_WEIGHTS`)
- **Krytyczne pytania & Problem:** Szanse na wylosowanie kart o rzadkości Rare/Epic/Legendary rosną bardzo wolno (Legendary pojawia się dopiero od 14 dnia z szansą 5%).
- **Logiczne uzasadnienie:** Gracz rzadko kiedy dociera do późnych dni, tracąc szansę na przetestowanie najciekawszych jednostek z wyższych tierów.
- **Sugerowana zmiana:** Zmodyfikować wagi w `DAILY_SHOP_WEIGHTS`. Przykładowo: Epic od dnia 4 (np. 5%), Legendary od dnia 7-8 (np. 5%), znacząco redukując szanse na Common w miarę upływu dni.

---

## 3. PRIORYTET 3: REFAKTORYZACJA ARCHITEKTURY (Architecture & Refactoring)

### Zadanie H [**ZROBIONE**]: Refaktoryzacja i odchudzenie RunState: Wprowadzenie Helperów (Dawne Zadanie 11)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd), [enemy_team_generator.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/utils/enemy_team_generator.gd), [team_helper.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/utils/team_helper.gd), [shop_helper.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/utils/shop_helper.gd)
- **Wdrożone rozwiązanie:**
  1. Stworzono `EnemyTeamGenerator.gd` z czystą metodą statyczną `generate_enemy_team(day, unit_templates)`.
  2. Stworzono `TeamHelper.gd` ze statycznymi metodami `check_and_merge_units`, `swap_units`, `sell_unit` i `sync_battle_team_stats`.
  3. Stworzono `ShopHelper.gd` ze statycznymi metodami obsługi losowania, kupowania potworów, jedzenia i zamrażania kart.
  4. W `RunState` zastąpiono złożoną logikę zwięzłymi fasadami delegującymi, zachowując 100% wstecznej kompatybilności API.

### Zadanie I [**ZROBIONE**]: Dodanie Enuma dla "damage_type" (Dawne Zadanie 3)

- **Lokalizacja:** [battle_team_model.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_team_model.gd) (metoda `take_damage` linia 153, oraz sygnał `damage_taken` linia 20), [status_effect.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/status/status_effect.gd) (metoda `modify_incoming_damage` linia 26)
- **Krytyczne pytania & Problem:** Typy obrażeń ("physical", "poison", "burn", "fatigue") przekazywane są jako zwykłe stringi, co grozi literówkami i utrudnia weryfikację typów.
- **Logiczne uzasadnienie:** Silnie typowane środowisko GDScript w projekcie wymaga wyeliminowania "magic strings" na rzecz enumów.
- **Sugerowana zmiana:**
  1. Zdefiniować enum w globalnie dostępnej klasie lub bezpośrednio w `BattleTeamModel`:

     ```gdscript
     enum DamageType { PHYSICAL, POISON, BURN, FATIGUE }
     ```

  2. Przekształcić sygnatury metod przyjmujących `damage_type: String` na typ enuma i zaktualizować warunki porównujące.

### Zadanie J: Przeniesienie stylu TooltipKeywordsBox do pliku sceny .tscn (Dawne Zadanie 16)

- **Lokalizacja:** [tooltip_keywords_box.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/tooltip_keywords_box.gd) (metoda `_create_keyword_panel`)
- **Krytyczne pytania & Problem:** Struktura panelu słowa kluczowego jest w całości tworzona i stylowana imperatywnie w kodzie, co utrudnia edycję wizualną.
- **Logiczne uzasadnienie:** UI powinno być konfigurowalne w edytorze Godota. Separacja kodu od prezentacji wizualnej ułatwia modyfikację stylów.
- **Sugerowana zmiana:**
  1. Stworzyć osobną miniaturową scenę `keyword_panel.tscn` w `src/shared/ui/components/`.
  2. Wystylizować w niej tło, marginesy, czcionki i ShaderBorderDecorator.
  3. W `tooltip_keywords_box.gd` załadować tę scenę i instancjonować ją za pomocą `instantiate()`, modyfikując tylko tekst.

### Zadanie Q [**ZROBIONE**]: Rozdzielenie kart na sklepowe i posiadane oraz wdrożenie kompozycji hierarchicznej

- **Lokalizacja:** [shop_card_unit.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_unit.gd) i [shop_card_unit.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_unit.tscn) (karta sklepowa), [unit_card.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/unit_card.tscn) i [unit_card.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/unit_card.gd) (karta posiadana), katalog `src/shared/ui/components/` (komponenty wizualne)
- **Krytyczne pytania & Problem:** W pierwotnym zamyśle jedna klasa obsługiwała oba typy kart. Wdrożono już dedykowane karty sklepowe (`ShopCardUnit`, `ShopCardItem`) oraz kartę posiadaną (`UnitCard`). Część komponentów (np. `card_sprite.tscn` oraz `card_portrait.tscn` będące odpowiednikiem `card_visuals`) również została wydzielona.
- **Wdrożone rozwiązanie:**
  1. **Mikro-komponenty:** Zweryfikowano sceny [card_sprite.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_sprite.tscn) oraz [card_portrait.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_portrait.tscn) – poprawnie odseparowują logikę wyświetlania od wyższych warstw.
  2. **Karta sklepowa:** Scena [shop_card_unit.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_unit.tscn) poprawnie importuje i używa `CardPortrait`, a także stopki z nazwą i ceną.
  3. **Karta posiadana:** Scena [unit_card.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/unit_card.tscn) korzysta z `CardPortrait`, wyświetla dynamiczne wskaźniki kierunków `DirectionIndicators` oparte na shaderze oraz w pełni obsługuje Drag & Drop poprzez `_get_drag_data()` w integracji z `DragManager`.

### Zadanie R [**ZROBIONE**]: Aktywacja TargetingLineOverlay oparta na zdarzeniach (Event-Driven Overlay)

- **Lokalizacja:** [targeting_line_overlay.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/targeting_line_overlay.gd), [shop_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd), [shop_card_item.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_item.gd)
- **Krytyczne pytania & Problem:** Nakładka `TargetingLineOverlay` istnieje cały czas w scenie i co klatkę sprawdza w `_process()` czy przeciągana karta to `ShopCardItem`, mimo że linia celowania potrzebna jest wyłącznie dla przedmiotów.
- **Logiczne uzasadnienie:** Przepisanie na architekturę opartą na zdarzeniach wyeliminuje zbędne odpytywanie typu karty w pętli dla kart jednostek (`UnitCard` / `ShopCardUnit`) i ograniczy działanie nakładki wyłącznie do aktywnego przeciągania przedmiotu.
- **Sugerowana zmiana:**
  1. Aktywować / włączać `TargetingLineOverlay` w [shop_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd) wyłącznie po odebraniu zdarzenia rozpoczęcia przeciągania z `ShopCardItem`.
  2. Wyłączać lub usuwać nakładkę natychmiast po zakończeniu przeciągania (`drag_ended`).

---

## 4. PRIORYTET 4: MECHANIKI ROZGRYWKI (Gameplay Mechanics)

### Zadanie K [**ZROBIONE**]: Bazowe HP drużyny oraz relikty zwiększające je (Dawne Zadanie 10)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd), [battle_team_model.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_team_model.gd) (metoda `load_team_units`)
- **Krytyczne pytania & Problem:** Wspólne HP drużyny w walce zależy wyłącznie od sumy zdrowia poszczególnych potworów. Brak stałego, bazowego HP dla całej drużyny.
- **Logiczne uzasadnienie:** Wprowadzenie bazowego HP drużyny (np. 100 HP) uniezależnia gracza od posiadania samych tanków i tworzy fundament pod relikty zwiększające bazowe HP całej drużyny.
- **Sugerowana zmiana:**
  1. Dodać w `RunState` zmienną `@export var base_health: int = 100` (wartość 100 HP zostaje zachowana jako początkowa/testowa, zgodnie z ustaleniami).
  2. W `battle_team_model.gd` w `load_team_units()` zainicjalizować `health = base_health` oraz `max_health = base_health` i dopiero potem dodawać wartości HP potworów.
  3. Stworzyć nowy relikt (np. `Elixir of Life`) dodający punkty do `base_health` w swojej metodzie `on_acquire()`.

---

## 5. PRIORYTET 5: ESTETYKA & UX (UX, Visuals & Polish)

### Zadanie M: Sprzedaż przeciąganej karty za pomocą Prawego Kliknięcia (Dawne Zadanie 9)

- **Lokalizacja:** [shop_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd) (metoda `_input`), [shop_panel.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_panel.gd) (tekst w overlayu)
- **Krytyczne pytania & Problem:** Gracz może sprzedać kartę tylko poprzez upuszczenie jej na panel sklepu.
- **Logiczne uzasadnienie:** Umożliwienie natychmiastowej sprzedaży poprzez prawy klik w trakcie przeciągania (drag) znacznie zwiększa dynamikę i komfort gry (QoL).
- **Sugerowana zmiana:**
  1. W `shop_scene.gd` nadpisać `_input(event: InputEvent) -> void`.
  2. Jeśli `event` to kliknięcie prawego przycisku myszy i `DragManager.dragged_card` nie jest nullem, a jego oryginalny slot nie był sklepem, wywołać `_on_sell_card_requested(...)` i zakończyć przeciąganie.
  3. W `shop_panel.gd` w powiadomieniu `NOTIFICATION_DRAG_BEGIN` zmienić tekst na: `"RELEASE OR RIGHT-CLICK TO SELL (+" + str(shop_card.price) + "g)"`.

### Zadanie N: Wyświetlanie HP drużyny w scenie sklepu (Dawne Zadanie 2)

- **Lokalizacja:** [shop_scene.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.tscn) (sekcja drużyny), [shop_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd) (metoda `populate_ui`)
- **Krytyczne pytania & Problem:** Sklep nie wyświetla sumarycznych punktów życia drużyny.
- **Logiczne uzasadnienie:** Zapewnia graczowi informację o aktualnym sumarycznym zdrowiu drużyny bezpośrednio w fazie zakupów.
- **Sugerowana zmiana:**
  1. Dodać węzeł `TeamHPLabel` (wraz z ikoną serca) w nagłówku panelu drużyny `TeamPanel`.
  2. W `shop_scene.gd` dodać helper liczący sumę HP: `run_state.base_health` + suma `max_health` wszystkich aktywnych potworów w `run_state.active_team`.
  3. Wywoływać tę kalkulację w `populate_ui()` oraz podpiąć pod sygnał `team_state_changed`.

### Zadanie O: Zmiana animacji scalania (merge) do samych sprite'ów jednostek (Dawne Zadanie 12)

- **Lokalizacja:** [shop_merge_animator.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/utils/shop_merge_animator.gd)
- **Krytyczne pytania & Problem:** Obecnie animacja mergowania odczepia z layoutu całe karty (z ramkami i tekstem), co wygląda nienaturalnie.
- **Logiczne uzasadnienie:** Animowanie samych grafik/sprite'ów jednostek latających i łączących się w punkcie centralnym wygląda o wiele czystej, profesjonalniej i dynamiczniej.
- **Sugerowana zmiana:**
  1. Zamiast odczepiać i animować całe węzły `ShopCard`, pobrać teksturę sprite'a z kart.
  2. Karty w slotach tymczasowo ukryć.
  3. Stworzyć tymczasowe, mniejsze węzły `TextureRect` ze sprite'ami potworów na globalnych pozycjach kart i je animować do środka, po czym wywołać błysk fuzji i w docelowym slocie odsłonić zaktualizowaną kartę.

### Zadanie P: Słowa kluczowe (keywords) dla Ongoing, Reliktów oraz Przedmiotów (Dawne Zadanie 13)

- **Lokalizacja:** [keyword_database.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/utils/keyword_database.gd), [tooltip_keywords_box.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/tooltip_keywords_box.gd), [card_tooltip.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_tooltip.gd)
- **Krytyczne pytania & Problem:** Słowa kluczowe wyświetlają się w tooltipie tylko po najechaniu na jednostki. Przedmioty i relikty nie wyświetlają definicji powiązanych z nimi mechanik.
- **Logiczne uzasadnienie:** Spójność informacji wymaga, aby najechanie na relikt lub przedmiot z klawiszem Shift wyświetlało te same słowa kluczowe (np. "Ongoing", "Shield", "Poison").
- **Sugerowana zmiana:**
  1. Dodać słowo kluczowe `"ongoing"` do bazy `KeywordDatabase.KEYWORD_MAP`.
  2. Dodać metody `build_keywords_for_item(item_instance)` oraz `build_keywords_for_relic(relic_instance)` w `TooltipKeywordsBox`.
  3. Zintegrować te wywołania w `card_tooltip.gd` w metodach `_setup_item_ui()` i `_setup_relic_ui()`.
