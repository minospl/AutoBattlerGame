# TODO: Analiza i Plan Poprawek Projektu AutoBattlerDungeonGame (Posortowane według Priorytetu)

## 1. PRIORYTET 1: KRYTYCZNE BŁĘDY (Critical Bugs)

## Zadanie A: Pusta drużyna gracza sprawia, że jest nieśmiertelny w walce (Dawne Zadanie 8)

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

### Zadanie C: Przebudowa sklepu: Cena na karcie i globalne zamrażanie sklepu (Dawne Zadanie 5)

- **Lokalizacja:** [shop_slot.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_slot.tscn), [shop_card_unit.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_unit.tscn), [shop_panel.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_panel.tscn), [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd)
- **Krytyczne pytania & Problem:** Każdy slot ma oddzielny przycisk "Freeze" i etykietę ceny na dole, co drastycznie zaśmieca UI sklepu. Dodatkowo sama karta potwora nie wyświetla swojej nazwy ani ceny bezpośrednio w swojej strukturze.
- **Logiczne uzasadnienie:** Przeniesienie ceny na kartę potwora/przedmiotu i dodanie jednego, globalnego przycisku "Zamroź Sklep" (Freeze Shop) znacznie uprości UI/UX. Dostosowanie wyglądu karty do przygotowanego makiety (mockupu) poprawi czytelność i profesjonalizm gry.
- **Sugerowana zmiana:**
  1. **Struktura karty (według makiety):**
     - **Górna sekcja (Portret):** Kontener z kolorowym tłem, zawierający sprite jednostki. Na dolnej krawędzi portretu na środku umieścić statystyki.
     - **Dolna sekcja (Stopka):** Ciemnoszary pasek na dole karty z HBoxContainer. Po lewej stronie nazwa potwora, a po prawej cena (np. "$15" or "3G").
     - *Uwaga spójności:* Zmianę tę należy zastosować zarówno dla potworów, jak i dla przedmiotów, aby zachować identyczny styl wizualny w sklepie.
  2. **Usunięcie sterowania ze slotów:** Usunąć z `shop_slot.tscn` węzeł `%ShopControls` (freeze i cena pod slotem).
  3. **Panel sklepu:** W `shop_panel.tscn` dodać przycisk "Freeze Shop" obok przycisku "Roll".
  4. **Stan gry:** W `RunState` zamienić `shop_frozen_statuses: Array[bool]` na pojedynczą zmienną `is_shop_frozen: bool`. Zaktualizować logiczne metody `roll_shop()` i `complete_battle()`.

### Zadanie D: Zwiększenie liczby kart w sklepie z 4 do 5 (Dawne Zadanie 7)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) (linia 6), [shop_scene.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd) (linia 143)
- **Krytyczne pytania & Problem:** Liczba kart w sklepie jest na sztywno ustawiona na 4 w logice oraz w kodzie sceny sklepu.
- **Logiczne uzasadnienie:** Większy sklep (5 kart) ułatwia graczowi zbieranie par/trójek jednostek i stabilizuje pętlę gry, redukując negatywny wpływ losowości.
- **Sugerowana zmiana:**
  1. W `run_state.gd` zmienić `const MAX_SHOP_CARDS_SIZE: int = 5`.
  2. W `shop_scene.gd` w metodzie `create_slots()` zmienić hardkodowane `shop_panel.create_slots(slot_scene, 4)` na dynamiczne `shop_panel.create_slots(slot_scene, run_state.shop_cards.size())`.

### Zadanie E: Limit zakupów przedmiotów w sklepie i jednostki/relikty go modyfikujące (Dawne Zadanie 6)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) (metoda `roll_single_shop_card`, `buy_unit`, `apply_item`, `buy_clickable_item`)
- **Krytyczne pytania & Problem:** Brak jakiegokolwiek limitu zakupów kart przedmiotów w sklepie na rundę. Gracz może w nieskończoność losować i kupować przedmioty.
- **Logiczne uzasadnienie:** Narzucenie limitu (np. domyślnie max 1 zakupiony przedmiot na rundę sklepową) i ukrywanie przedmiotów po wyczerpaniu limitu zbalansuje mechanikę jedzenia. Dodanie reliktów/jednostek podnoszących ten limit stworzy interesujące synergie.
- **Sugerowana zmiana:**
  1. Dodać w `RunState` zmienne: `max_item_purchases = 1` oraz `items_purchased_this_turn = 0`.
  2. Przy udanym zakupie przedmiotu inkrementować licznik zakupów. Resetować licznik na początku każdej rundy sklepu (przy przejściu dnia lub bezpłatnym odświeżeniu rundy).
  3. Stworzyć relikt/modyfikator potwora modyfikujący wartość `max_item_purchases` (np. o +1).

### Zadanie F: Dedykowane miejsce na przedmioty w sklepie - ostatni slot (Dawne Zadanie 4)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) (metoda `roll_single_shop_card` i pętla w `roll_shop()`)
- **Krytyczne pytania & Problem:** Losowe pojawianie się przedmiotów w dowolnym slocie sklepu wprowadza zbyt duży chaos i blokuje losowanie potworów w kluczowych miejscach.
- **Logiczne uzasadnienie:** Zastąpienie losowości stałym układem: pierwsze 4 sloty (indeksy 0-3) zawsze oferują jednostki potworów, a ostatni (indeks 4) zawsze oferuje przedmiot (jedzenie), dopóki nie zostanie wyczerpany limit zakupów przedmiotów z Zadania E. Po wyczerpaniu limitu ostatni slot oferuje potwora (lub pozostaje pusty).
- **Sugerowana zmiana:**
  1. Zmodyfikować logikę losowania kart w sklepie w `run_state.gd`. Metoda `roll_single_shop_card(slot_idx: int)` powinna przyjmować indeks slotu.
  2. Jeśli `slot_idx == 4` (ostatni slot) oraz `items_purchased_this_turn < max_item_purchases`, ustawić na sztywno `spawn_item = true`.
  3. Dla wszystkich pozostałych indeksów (`0`, `1`, `2`, `3`) ustawić `spawn_item = false` (zawsze losować potwora).
  4. Jeśli limit zakupów przedmiotów został osiągnięty (`items_purchased_this_turn >= max_item_purchases`), ostatni slot (indeks 4) również powinien losować jednostkę (potwora), co sprawi, że przedmioty przestaną się pojawiać.
  5. *Uwaga wyścigu stanów:* Inkrementacja licznika `items_purchased_this_turn` musi odbywać się bezwzględnie **przed** wywołaniem natychmiastowego uzupełnienia slotu w `apply_item()` / `buy_clickable_item()`, aby nowe losowanie poprawnie rozpoznało osiągnięcie limitu.

### Zadanie G: Poprawa skalowania szans rzadkości w sklepie (Dawne Zadanie 14)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) (słownik `DAILY_SHOP_WEIGHTS`)
- **Krytyczne pytania & Problem:** Szanse na wylosowanie kart o rzadkości Rare/Epic/Legendary rosną bardzo wolno (Legendary pojawia się dopiero od 14 dnia z szansą 5%).
- **Logiczne uzasadnienie:** Gracz rzadko kiedy dociera do późnych dni, tracąc szansę na przetestowanie najciekawszych jednostek z wyższych tierów.
- **Sugerowana zmiana:** Zmodyfikować wagi w `DAILY_SHOP_WEIGHTS`. Przykładowo: Epic od dnia 4 (np. 5%), Legendary od dnia 7-8 (np. 5%), znacząco redukując szanse na Common w miarę upływu dni.

---

## 3. PRIORYTET 3: REFAKTORYZACJA ARCHITEKTURY (Architecture & Refactoring)

### Zadanie H: Refaktoryzacja i odchudzenie RunState: Wprowadzenie Helperów (Dawne Zadanie 11)

- **Lokalizacja:** [run_state.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd)
- **Krytyczne pytania & Problem:** Plik `run_state.gd` zawiera ponad 580 linii kodu i miesza czysty stan gry z logiką generowania przeciwników, mergowania jednostek oraz całą logiką sklepu.
- **Logiczne uzasadnienie:** `RunState` powinien być przede wszystkim strukturą danych (Modelem). Przeniesienie skomplikowanej logiki biznesowej do dedykowanych helperów (statycznych lub jako komponenty) poprawi czytelność kodu i ułatwi jego testowanie.
- **Sugerowana zmiana:**
  1. Stworzyć `EnemyTeamGenerator.gd` i wydzielić tam metodę `generate_enemy_team()`.
  2. Stworzyć `TeamHelper.gd` i przenieść tam metodę mergowania jednostek `check_and_merge_units()`.
  3. Stworzyć `ShopHelper.gd` i przenieść tam logikę losowania, kupowania oraz nakładania przedmiotów.
  4. *Architektura:* Wszystkie metody pomocnicze w helperach powinny być zadeklarowane jako **statyczne** (np. `static func ...`) i przyjmować `RunState` jako argument (Dependency Injection), co zapobiegnie powstawaniu cyklicznych referencji i wyciekom pamięci w Godocie.

### Zadanie I: Dodanie Enuma dla "damage_type" (Dawne Zadanie 3)

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

### Zadanie Q [Częściowo wdrożone / W toku]: Rozdzielenie kart na sklepowe i posiadane oraz wdrożenie kompozycji hierarchicznej

- **Lokalizacja:** [shop_card_unit.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_unit.gd) i [shop_card_unit.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_unit.tscn) (karta sklepowa), [unit_card.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/unit_card.tscn) i [unit_card.gd](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/unit_card.gd) (karta posiadana), katalog `src/shared/ui/components/` (komponenty wizualne)
- **Krytyczne pytania & Problem:** W pierwotnym zamyśle jedna klasa obsługiwała oba typy kart. Wdrożono już dedykowane karty sklepowe (`ShopCardUnit`, `ShopCardItem`) oraz kartę posiadaną (`UnitCard`). Część komponentów (np. `card_sprite.tscn` oraz `card_portrait.tscn` będące odpowiednikiem `card_visuals`) również została wydzielona.
- **Logiczne uzasadnienie:** Rozdzielenie logiki i prezentacji kart sklepowych i posiadanych ułatwia ich stylowanie (Zadanie C) oraz zarządzanie logiką Drag & Drop. Należy dokończyć reorganizację i refaktor pozostałych elementów zgodnie z tą hierarchią.
- **Sugerowana zmiana:**
  1. **Mikro-komponenty (Poziom 1):** Zweryfikować i dopracować niezależne sceny [card_sprite.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_sprite.tscn) oraz [card_portrait.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/ui/components/card_portrait.tscn).
  2. **Karta sklepowa (Poziom 3):** Dostosować [shop_card_unit.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/shop_card_unit.tscn) tak, aby poprawnie korzystała z `CardPortrait` oraz stopki z nazwą i ceną według makiety z Zadania C.
  3. **Karta posiadana (Poziom 3):** Upewnić się, że [unit_card.tscn](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/components/unit_card.tscn) korzysta z `CardPortrait` oraz poprawnie wyświetla indykatory kierunków (korzystające z shadera) i obsługuje Drag & Drop.

---

## 4. PRIORYTET 4: MECHANIKI ROZGRYWKI (Gameplay Mechanics)

### Zadanie K: Bazowe HP drużyny oraz relikty zwiększające je (Dawne Zadanie 10)

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
