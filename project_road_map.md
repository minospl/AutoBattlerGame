# Roadmapa Rozwoju i Analiza Architektoniczna: AutoBattlerDungeonGame (Async PvP Auto-Battler)

Dokument ten zawiera szczegółową analizę stanu obecnego projektu **AutoBattlerDungeonGame**, chronologiczny plan rozwoju (roadmapę) dostosowany do trybu **Asynchronicznego PvP ($N$ Rund + Deathmatch)** oraz ocenę ryzyka architektonicznego ze szczególnym uwzględnieniem restrykcyjnych reguł typowania w **Godot 4.7 (Forward Plus)**.

---

## 1. Analiza Stanu Obecnego

Na podstawie analizy kodu źródłowego w katalogu `src`, obecny stan projektu można podzielić na gotowe fundamenty oraz luki wymagające implementacji w nowym trybie rozgrywki.

### A. Co stanowi fundament gry (Stan Gotowy)

* **Główna pętla gry (Core Loop):** Klasa [GameRoot](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/game_root.gd) sprawnie zarządza przełączaniem scen między sklepem ([ShopScene](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd)) a walką ([BattleScene](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_scene.gd)) oraz przekazuje stan rozgrywki ([RunState](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd)) poprzez wstrzykiwanie zależności (`setup()`), unikając globalnych autoloadów.
* **System Sklepu (Shop Mechanics):** Działa kupowanie jednostek (za 3g), zamrażanie (freeze) ofert, odświeżanie sklepu (roll za 1g), oraz sprzedaż jednostek z ławki lub drużyny. W pełni zaimplementowany jest algorytm łączenia jednostek (mergowanie 3 identycznych jednostek tego samego poziomu w jedną wyższego poziomu, maksymalnie do poziomu 3) w [RunState](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd).
* **Pozycjonowanie i Siatka 2x3:** Logiczna siatka drużyny (6 slotów) i ławki (6 slotów). Zależności pozycjonowania są rozwiązywane przez helper [TargetResolver](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/utils/target_resolver.gd), co pozwala na precyzyjne nakładanie efektów (np. ADJACENT, HORIZONTAL, VERTICAL, UP, DOWN).
* **Mechanika Wspólnego Zdrowia (Shared Health):** W walce jednostki nie posiadają indywidualnego paska HP. Ich punkty życia są sumowane do wspólnej puli drużyny ([BattleTeamModel](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_team_model.gd)). Obrażenia (zarówno fizyczne, jak i od statusów) są zadawane całej drużynie.
* **Symulacja Walki:** System czasu rzeczywistego oparto o `cast_speed` każdej jednostki. Gdy pasek akcji się zapełni, jednostka wykonuje atak podstawowy, nakłada statusy lub leczy/nakłada tarcze. Zaimplementowano mechanikę zmęczenia (Fatigue) zadającą rosnące obrażenia Fibonacciego po 30 sekundach.
* **System Modyfikatorów i Szablonów:** Modułowa struktura, w której każdy modyfikator (np. [AncientTitanModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/templates/modifiers/ancient_titan_modifier.gd)) dziedziczy po [UnitModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/unit_modifier.gd) i sam definiuje swoje działanie. Istnieje około 20 gotowych szablonów potworów (`.tres`) oraz ich modyfikatorów.
* **System Przedmiotów i Jedzenia (Item & Food System):** Wdrożono klasy bazowe [ItemData](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/item_data.gd), [ItemInstance](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/item_instance.gd) oraz [ItemModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/item_modifier.gd). Stworzono gotowe szablony jedzenia ([apple.tres](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/templates/apple.tres), [sword.tres](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/templates/sword.tres)), które zawsze pojawiają się w ostatnim slocie sklepu (chyba że wyczerpano limit zakupu) i mogą być przeciągane na sojusznicze jednostki w celu stałego wzmocnienia statystyk.
* **System Reliktów i Skrzyń (Relic & Chest System):** Wdrożono system pasywnych modyfikatorów rozgrywki/walki ([RelicData](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/relic_data.gd), [RelicInstance](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/relic_instance.gd) oraz [RelicModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/relic_modifier.gd)). Gracz może kupować skrzynie z reliktami o zróżnicowanej rzadkości w sklepie, a aktywne relikty modyfikują walkę, statystyki oraz zasady celowania.

### B. Nowy Kierunek Rozgrywki (Single Player & Async PvP)

* **Dwa Tryby Rozgrywki (Wzorzec Strategii):** Gra docelowo będzie wykorzystywać interfejs `OpponentProvider`, dzieląc się w 100% spójnie na dwa tryby:
  * **Single Player / Kampania:** Przeciwnicy generowani lokalnie (offline) na podstawie algorytmu i botów przez `OfflineOpponentProvider`.
  * **Multiplayer / Ranking:** Asynchroniczne starcia ze snapshotami prawdziwych graczy pobieranymi z chmury przez `NetworkOpponentProvider`.
* **System Żyć i Rund:** Gracz rozpoczyna rozgrywkę z pulą $N$ żyć (np. 5). Rozgrywka podstawowa trwa $N$ (np. 20) rund. Przegrana walka odejmuje 1 życie.
* **Pula Przeciwników i Faza Deathmatch:** Losowanych jest 7-8 rywali. W rundach 1–$N$ gracz walczy z ich historycznymi snapshotami, a po $N$. rundzie następuje faza finałowa eliminacyjna (Deathmatch).
* **Podgląd i Wybór Przeciwnika w Sklepie:** W fazie sklepu gracz ma wgląd w nadchodzącego przeciwnika (podgląd jego jednostek, pozycjonowania i wspólnego HP). Wylosowani rywale ulegają zmianie wyłącznie po ich wyeliminowaniu (0 HP) lub użyciu dedykowanego eventu/przedmiotu.
* **Serializacja Stanu Drużyny:** Przygotowanie metod eksportujących (`to_dict()`) i importujących (`from_dict()`) układ drużyny w [RunState](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) pod kątem przyszłego backendu.

---

## 2. Chronologiczna Roadmapa (Krok po Kroku)

### Kamień Milowy 1: Tryb Single Player / Kampania (Lokalna Emulacja)

**Cel Główny:** Przekształcenie trybu single-player w pętlę $N$ rund z systemem żyć i stworzenie w pełni grywalnej kampanii bez użycia sieci, opartej na lokalnym generatorze (`OfflineOpponentProvider`).

| Gotowe | Kategoria | Zadania do wykonania | Priorytet |
| :---: | :--- | :--- | :--- |
| [X] | **Mechanika** | **System Żyć i Licznika Rund (`RunState`):** *(Częściowo gotowe)* Zmienne `lives`, `day`, `trophies` i obsługa w `complete_battle()` istnieją w `RunState`. Wymagają dostosowania limitu do 5 żyć i $N$ rund podstawowych. | **Krytyczny** |
| [X] | **Mechanika** | **Architektura OpponentProvider (Single Player):** Wprowadzenie wzorca strategii dla wrogów (`BattleRuleset`). Stworzenie lokalnej implementacji `OfflineOpponentProvider`, dostarczając grywalny rdzeń offline. | **Krytyczny** |
| [X] | **Refaktor & Mechanika** | **Wyodrębnienie Silnika Bitwy (`BattleEngine` / Headless Simulator):** Ekstrakcja czystej logiki pętli czasu bitwy z `BattleScene` do niezależnej od UI klasy `BattleEngine`. Stworzenie pojedynczego źródła prawdy (Single Source of Truth), umożliwiającego zarówno animowaną walkę na arenie UI, jak i natychmiastową symulację walk w tle w ułamku milisekundy. | **Krytyczny** |
| [ ] | **Refaktor & Mechanika** | **Procesor Rozliczania Tury (`TurnProcessor`):** Stworzenie uniwersalnej logiki przejścia między dniami, wykonującej te same operacje dla gracza i botów bez graficznych wizualizacji (`floating text`): (1) rozliczenie efektów po-bitewnych (`ON_BATTLE_END`), (2) przydział złota (+10g podstawa + własna generacja z Mimiców/Reliktów), (3) automatyczne fuzje 3 kart na ★2/★3, (4) inicjalizacja startu sklepu (`ON_SHOP_START`). | **Krytyczny** |
| [ ] | **Mechanika** | **Ewolucja Drużyn i Archetypy Botów (Single Player):** Trwały zapis składu 7 botów (`OpponentProfile`). Przypisanie dwuelementowych archetypów (np. *Beast+Dragon*, *Fire+Earth*, *Plant+Water*). Bot dąży do zbierania jednostek z tych 2 typów, a stałe modyfikatory (`PERMANENT`) oraz ulepszenia nie resetują się między dniami. | **Krytyczny** |
| [ ] | **Mechanika** | **Inteligentne Pozycjonowanie AI w Siatce 2x3 (Single Player):** Heurystyka rozmieszczania jednostek: Jednostki kierunkowe (`UP`, `DOWN`, `LEFT`, `RIGHT`) lądują tam, gdzie mają sąsiada w tym kierunku, Jednostki obszarowe (`ADJACENT`, `ALL`) trafiają na środkowe sloty (1 i 4). | Wysoki |
| [ ] | **Mechanika** | **Symulacja Ekonomii i Sklepu Botów (Single Player):** Pełna symulacja fazy sklepu 1:1 z graczem oparta na `ShopRarityConfig`, dynamicznych cenach `UnitData.price`, limitach przedmiotów oraz cztero-stopniowej hierarchii zakupów z mechanizmem ochrony przed pechem (*Pity System*). Patrz szczegółowa specyfikacja w sekcji "Algorytm Symulacji Ekonomii i Sklepu Botów". | Wysoki |
| [X] | **Mechanika** | **Faza Deathmatch:** Zaimplementowano pętlę finałowych starć (Deathmatch) z użyciem `DeathmatchBattleRuleset`. | **Krytyczny** |
| [X] | **Mechanika** | **Serializacja Drużyny (`to_dict` / `from_dict`):** Dodano obsługę transformacji w `UnitInstance` i integrację z `OpponentProfile`. | **Krytyczny** |
| [X] | **Mechanika** | **Zunifikowany System Przedmiotów (Spawnowanie, Rzadkość i Modułowość):** Przebudowa przedmiotów na wzór potworów. | **Krytyczny** |
| [X] | **Mechanika** | **Poziom Sklepu (Shop Level):** Ulepszanie sklepu i wagi rzadkości. | **Krytyczny** |
| [X] | **UI / UX** | **Wskaźnik Żyć i Rund w Sklepie/Walce:** *(Częściowo gotowe)* `ShopHeaderBar` wyświetla już lives/day w sklepie. Należy dodać analogiczny wskaźnik do sceny walki `BattleScene` oraz powiadomienie o fazie Deathmatch. | **Krytyczny** |
| [ ] | **UI / UX & Mechanika** | **Panel Podglądu Przeciwnika w Sklepie (`OpponentPreviewModal`):** Otwierany z nagłówka sklepu (`ShopHeaderBar`) interaktywny modal podglądu rywala. Prezentuje snapshot bota **z momentu po zakończeniu poprzedniej walki (`post_battle_snapshot`)**: jego zycia (`lives`), sumaryczne HP, ułożenie siatki 2x3 z pełnymi tooltipami potworów, aktywne relikty oraz zgromadzone po walce złoto. | **Krytyczny** |
| [X] | **Refaktor** | **Model-View separation & Null-Safety:** Reaktywna architektura sklepu oraz poprawka typowania. | **Krytyczny** |
| [X] | **UI / UX** | **Galeria / Kompendium:** Scena kompendium prezentująca listę wszystkich istniejących w grze jednostek, przedmiotów i reliktów ([CompendiumScene](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/compendium/compendium_scene.gd)). | **Krytyczny** |

---

### Kamień Milowy 2: Rozbudowa Zawartości i Synergii

**Cel Główny:** Znaczące rozszerzenie puli potworów, przedmiotów i reliktów, zapobiegające powstawaniu jednej zdominowanej "mety".

| Gotowe | Kategoria | Zadania do wykonania | Priorytet |
| :---: | :--- | :--- | :--- |
| [ ] | **Mechanika** | **Rozbudowa Puli Potworów (do 25+):** Dodanie nowych potworów z unikalnymi modyfikatorami i mechanikami. | **Krytyczny** |
| [ ] | **Mechanika** | **Nowe Przedmioty i Relikty:** Dodanie 15+ nowych przedmiotów konsumpcyjnych i reliktów modyfikujących przebieg walki. | **Krytyczny** |
| [ ] | **UI / UX** | **Ekran Podsumowania Biegu (Run Summary):** Statystyki zebranych wygranych, wykres obrażeń (Damage Meter) i historia stoczonych walk. | Opcjonalny |

---

### Kamień Milowy 3: Polerowanie UI/UX, VFX i Audio

**Cel Główny:** Doprowadzenie gry do poziomu "Premium UX" – bogate animacje, efekty cząsteczkowe i oprawa dźwiękowa.

| Gotowe | Kategoria | Zadania do wykonania | Priorytet |
| :---: | :--- | :--- | :--- |
| [ ] | **UI / UX** | **Efekty Wizualne (VFX) w Walce:** Dodanie linii uderzeń, efektów cząsteczkowych przy trafieniach krytycznych i zaklęciach, oraz trzęsienia ekranu (Screen Shake). | **Krytyczny** |
| [ ] | **UI / UX** | **Płynne Animacje UI:** Animowanie pojawiania się kart w sklepie, zamrażania oraz przejść między ekranami za pomocą Tweens. | **Krytyczny** |
| [ ] | **Refaktor** | **Optymalizacja Wydajności i Pamięci:** *(Częściowo gotowe - wdrożono Object Pool dla latających tekstów)* Profilowanie walki, cache'owanie shaderów, czyszczenie instancji jednostek. | **Krytyczny** |
| [ ] | **UI / UX** | **Menedżer Dźwięku (Audio System):** Dodanie muzyki adaptacyjnej (Sklep/Walka/Deathmatch) i efektów SFX. | **Krytyczny** |

---

### Kamień Milowy 4: Tryb Multiplayer (Sieciowe Async PvP i Rankingi)

**Cel Główny:** Wdrożenie chmurowego backendu i trybu sieciowego (`NetworkOpponentProvider`), zbalansowanie rozgrywki i przygotowanie do pełnego wydania.

| Gotowe | Kategoria | Zadania do wykonania | Priorytet |
| :---: | :--- | :--- | :--- |
| [ ] | **Backend** | **NetworkOpponentProvider (Sieć / API):** Sieciowa implementacja interfejsu wrogów. Łączy się z backendem (np. Supabase), wysyła układ naszej drużyny po każdej wygranej bitwie i asynchronicznie pobiera snapshoty prawdziwych graczy na początku gry do puli. | **Krytyczny** |
| [ ] | **Backend & UI** | **System Rankingowy (Elo / Rangi):** Wdrożenie systemu punktacji Elo/MMR za ukończone biegi oraz podziału na graficzne rangi graczy (np. Bronze, Silver, Gold). | **Krytyczny** |
| [ ] | **Mechanika** | **Balansowanie Statystyk:** Przetestowanie i zbalansowanie $N$ rund, szans na rzadkości kart, przyrostów złota i siły reliktów. | **Krytyczny** |
| [ ] | **UI / UX** | **Menu Główne i Ustawienia:** *(Częściowo gotowe - zrealizowano modale opcji)* Stworzenie sceny startowej z logiem gry, przyciskami "Nowa Gra" oraz profil gracza. | **Krytyczny** |
| [ ] | **Błędy / QA** | **Testy Automatyczne:** Napisanie testów jednostkowych (Unit Tests) symulujących 1000 automatycznych walk w tle w celu wykrycia nieskończonych pętli lub awarii silnika. | **Krytyczny** |
| [ ] | **UI / UX** | **Lokalizacja (Localization):** Dokończenie systemu lokalizacji (polski/angielski). | Opcjonalny |

---

## 3. Przyszłe Rozszerzenia

### **System reliktów i nagród**

* Eventy (np. po 5., 10. i 15. rundzie) gdzie można dostać unikalne relikty/jednostki/gold/odnowic hp/zwiekszyc base health/itd...

### **Zaawansowany System Statystyk (Stat Modifier Pattern)**

Wzorce modyfikacji statystyk (`Stat` oraz `StatModifier` o typach FLAT i PERCENT) zapobiegające konfliktom przy nakładaniu dziesiątek równoległych efektów.

---

### **Algorytm Symulacji Ekonomii i Sklepu Botów**

Niski poziom logiki dla `OfflineOpponentProvider.simulate_bot_turn(bot: OpponentProfile, day: int)`:

1. **Timing, Aktywne Boty i Snapshoty (`post_battle_snapshot`):**
   * **Kiedy:** Faza sklepu botów wykonuje się na samym początku nowego Dnia (zanim gracz rozpocznie zakupy w sklepie).
   * **Obsługa:** W symulacji sklepu biorą udział wyłącznie **aktywne / żyjące boty (`lives > 0`)**. Proces ten działa nieprzerwanie również w fazie finałowej **Deathmatch (Dzień 20+)**, dopóki wszyscy przeciwnicy nie zostaną wyeliminowani.
   * **Snapshot dla Podglądu (`post_battle_snapshot`):** Przed rozpoczęciem zakupów na dany Dzień, `OpponentProfile` tworzy głęboką kopię `post_battle_snapshot = bot.clone()`. To dokładnie tę migawkę wyświetla graczowi `OpponentPreviewModal`.

2. **Bezpośrednia Symulacja Walk w Tle (`BattleEngine` / Headless Simulator):**
   * Do przeliczenia zysków zebranych przez bota w walce ze snapshotem gracza używamy czystego silnika **`BattleEngine.simulate_battle(bot_team, player_snapshot)`**.
   * **Bezpieczne Klonowanie Gracza (`player_snapshot`):** Snapshot gracza tworzony jest jako odizolowana kopia (`clone()`) kart z `run_state.active_team`, co zapobiega wyciekom modyfikacji statystyk na żywe potwory gracza.
   * **Brak Zgadywania (100% Prawdziwa Bitwa):** Funkcja przelicza bitwę w pętli `delta` (krok 0.05s) bez UI. Bierze pod uwagę 100% detali: `cast_speed`, statusy, tarcze, relikty, pozycjonowanie oraz rejestruje dokładne złoto wygenerowane przez umiejętności potworów (np. Mimic przy `ON_CAST`) i relikty.

3. **Przetwarzanie Przejścia Tury przez `TurnProcessor`:**
   * Po wywołaniu `BattleEngine` automatycznie wywoływany jest **`TurnProcessor.process_turn_end(bot)`**:
     * Aplikuje efekty po-bitewne (`ON_BATTLE_END`).
     * Przydziela budżet: `bot.gold += 10 (podstawa) + wygenerowane_złoto_z_bitwy`.
     * Wykonuje automatyczne fuzje 3 identycznych kart na ★2 / ★3.
     * Wyzwala modyfikatory startu sklepu (`ON_SHOP_START`).

4. **Zasada Utraty Żyć (`lives -= 1`):**
   * **Jedynie 1 wyznaczony na dany Dzień przeciwnik** (którego walka z graczem jest animowana na arenie `BattleScene`) traci 1 Życie (`lives -= 1`), jeśli przegra bezpośrednie starcie z graczem.
   * Pozostałe żyjące boty rozwijają się w tle i zbierają zyski ze swojej symulacji przez `TurnProcessor`, ale **NIE tracą żyć**.

5. **Konfiguracja Oferty Sklepu i Ławki (Bench):**
   * **Ławka Bota (`bench`):** Bot trzyma `active_team` (max 6) oraz **ławka zapasowa `bench` (max 6)** – dokładnie tak jak gracz. Pozwala to na kupowanie duplikatów potworów przy pełnym składzie (6/6) i czekanie na 3. kartę do wykonania fuzji bez osłabiania drużyny.
   * **Poziom Sklepu (`shop_level`):** Każdy bot posiada własną zmienną `shop_level` (start 1). Z każdym dniem wykonuje `shop_level += 1`. Dodatkowo poziom zwiększają przedmioty sklepowe (np. *Merchant Scroll*) i relikty.
   * **Wagi Rzadkości:** Pobierane z `ShopRarityConfig.get_weights_for_day(bot.shop_level)`.
   * **Struktura Oferty:** Sloty 0–3 zawierają jednostki, a Slot 4 zawiera przedmiot. Tak jak u gracza.

6. **Pętla Decyzyjna Bota (Główny Algorytm Zakupów):**
   Dopóki `bot.gold >= 1`:
   * **Priorytet 1 (Merchant Scroll / Skrzynia z Reliktem):** Jeśli w Slocie na przedmioty wylosowano *Merchant Scroll* LUB Skrzynię z Reliktem (`RelicData`), a `gold >= price` oraz nie przekroczono limitu – bot natychmiast kupuje przedmiot (`bot.shop_level += 1` lub dodaje relikt).
   * **Priorytet 2 (Jednostka z Archetypu lub Duplikat):** Bot skanuje Sloty 0–3 w poszukiwaniu potworów pasujących do jego **Archetypu Głównemu/Pobocznemu** LUB posiadanych już w drużynie. Jeśli `gold >= unit.price` – kupuje potwora (wstawia do `active_team` lub na `bench`) i wykonuje automatyczne **mergowanie 3 identycznych kart** do poziomu 2 lub 3 przez `TurnProcessor`.
   * **Priorytet 3 (Przedmiot Dokarmiający przy 6 Jednostkach):** Jeśli bot posiada komplet **6 potworów**, a w Slocie 4 znajduje się przedmiot wzmacniający (`ItemData`) – kupuje przedmiot i aplikuje jego stały bonus (`PERMANENT`) na swoją pierwszą/najsilniejszą jednostkę.
   * **Rolowanie Sklepu:** Jeśli brak pasujących zakupów w bieżącej ofercie, bot odejmuje 1g z budżetu i roluje całe 5 slotów sklepu na nowo.

7. **Mechanizm Ochrony przed Pechem (Pity Duplication System):**
   * Jeśli po wyczerpaniu całego złota (`gold < 1`) bot zakupił w danej rundzie **0 jednostek/przedmiotów** (cały budżet został utracony na nieudane rolowania):
   * Uruchamia się system ochrony: bot losowo wybiera jedną z istniejących w jego drużynie jednostek i darmowo otrzymuje jej duplikat 1-poziomowy (co wspiera proces ulepszania na ★2 / ★3).
