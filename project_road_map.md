# Roadmapa Rozwoju i Analiza Architektoniczna: AutoBattlerDungeonGame (Async PvP Auto-Battler)

Dokument ten zawiera szczegółową analizę stanu obecnego projektu **AutoBattlerDungeonGame**, chronologiczny plan rozwoju (roadmapę) dostosowany do trybu **Asynchronicznego PvP ($N$ Rund + Deathmatch)** oraz ocenę ryzyka architektonicznego ze szczególnym uwzględnieniem restrykcyjnych reguł typowania w **Godot 4.7 (Forward Plus)**.

---

## 1. Analiza Stanu Obecnego

Na podstawie analizy kodu źródłowego w katalogu `src`, obecny stan projektu można podzielić na gotowe fundamenty oraz luki wymagające implementacji w nowym trybie rozgrywki.

### A. Co stanowi fundament gry (Stan Gotowy)

* **Główna pętla gry (Core Loop):** Klasa [GameRoot](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/game_root.gd) sprawnie zarządza przełączaniem scen między sklepem ([ShopScene](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/shop/shop_scene.gd)) a walką ([BattleScene](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_scene.gd)) oraz przekazuje stan rozgrywki ([RunState](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd)) poprzez wstrzykiwanie zależności (`setup()`), unikając globalnych autoloadów.
* **System Sklepu (Shop Mechanics):** Działa kupowanie jednostek (za 3g), zamrażanie (freeze) ofert, odświeżanie sklepu (roll za 1g), oraz sprzedaż jednostek z ławki lub drużyny. W pełni zaimplementowany jest algorytm łączenia jednostek (mergowanie 3 identycznych jednostek tego samego poziomu w jedną wyższego poziomu, maksymalnie do poziomu 3) w [RunState](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd).
* **Pozycjonowanie i Siatka 2x3:** Logiczna siatka drużyny (6 slotów) i ławki (8 slotów). Zależności pozycjonowania są rozwiązywane przez helper [TargetResolver](file:///d:/Projekty/AutoBattlerDungeonGame/src/shared/utils/target_resolver.gd), co pozwala na precyzyjne nakładanie efektów (np. ADJACENT, HORIZONTAL, VERTICAL, UP, DOWN).
* **Mechanika Wspólnego Zdrowia (Shared Health):** W walce jednostki nie posiadają indywidualnego paska HP. Ich punkty życia są sumowane do wspólnej puli drużyny ([BattleTeamModel](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/battle/battle_team_model.gd)). Obrażenia (zarówno fizyczne, jak i od statusów) są zadawane całej drużynie.
* **Symulacja Walki:** System czasu rzeczywistego oparto o `cast_speed` każdej jednostki. Gdy pasek akcji się zapełni, jednostka wykonuje atak podstawowy, nakłada statusy lub leczy/nakłada tarcze. Zaimplementowano mechanikę zmęczenia (Fatigue) zadającą rosnące obrażenia Fibonacciego po 30 sekundach.
* **System Modyfikatorów i Szablonów:** Modułowa struktura, w której każdy modyfikator (np. [AncientTitanModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/templates/modifiers/ancient_titan_modifier.gd)) dziedziczy po [UnitModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/units/unit_modifier.gd) i sam definiuje swoje działanie. Istnieje 8 gotowych szablonów potworów (`.tres`) oraz ich modyfikatorów.
* **System Przedmiotów i Jedzenia (Item & Food System):** Wdrożono klasy bazowe [ItemData](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/item_data.gd), [ItemInstance](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/item_instance.gd) oraz [ItemModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/item_modifier.gd). Stworzono gotowe szablony jedzenia ([apple.tres](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/templates/apple.tres), [sword.tres](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/items/templates/sword.tres)), które spawnują się w sklepie (szansa 30%) i mogą być przeciągane na sojusznicze jednostki w celu stałego wzmocnienia statystyk.
* **System Reliktów i Skrzyń (Relic & Chest System):** Wdrożono system pasywnych modyfikatorów rozgrywki/walki ([RelicData](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/relic_data.gd), [RelicInstance](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/relic_instance.gd) oraz [RelicModifier](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/relics/relic_modifier.gd)). Gracz może kupować skrzynie z reliktami o zróżnicowanej rzadkości w sklepie, a aktywne relikty modyfikują walkę, statystyki oraz zasady celowania.

### B. Nowy Kierunek Rozgrywki (Async PvP: $N$ Rund + Deathmatch)

* **System Żyć i Rund:** Gracz rozpoczyna rozgrywkę z pulą $N$ żyć (np. 5). Rozgrywka podstawowa trwa $N$ (np. 20) rund. Przegrana walka odejmuje 1 życie.
* **Pula Przeciwników (Biegi Finalistów):** Przy rozpoczęciu nowej gry losowanych jest 7-8 przeciwników spośród graczy, którzy w swoich rozgrywkach **zdołali dotrzeć do fazy Deathmatch**. W rundach 1–$N$ walczysz z ich snapshotami z odpowiednich rund, a po $N$. rundzie staczasz finałowe starcia Deathmatch z ich ostatecznymi składami.
* **Podgląd i Wybór Przeciwnika w Sklepie:** W fazie sklepu gracz ma wgląd w nadchodzącego przeciwnika (podgląd jego jednostek, pozycjonowania i wspólnego HP). Wylosowani rywale pozostają stałymi przeciwnikami i **mogą zostać zamienieni wyłącznie za pomocą specjalnego eventu/przedmiotu lub w momencie, gdy zostaną całkowicie pokonani/wyeliminowani z gry (stracą całe HP/życia).** Przeciwnicy są emulowani lokalnie z puli gotowych botów/buildów symulujących graczy docierających do Deathmatcha (bez backendu).
* **Serializacja Stanu Drużyny:** Przygotowanie metod eksportujących (`to_dict()`) i importujących (`from_dict()`) układ drużyny w [RunState](file:///d:/Projekty/AutoBattlerDungeonGame/src/core/run_state.gd) pod kątem przyszłego backendu.

---

## 2. Chronologiczna Roadmapa (Krok po Kroku)

### Kamień Milowy 1: Faza MVP / Alfa (Pętla Async PvP z Lokalną Emulacją)

**Cel Główny:** Przekształcenie trybu single-player w pętlę $N$ rund z systemem żyć, lokalnym generatorem snapshotów przeciwników i fazą Deathmatch.

| Kategoria | Zadania do wykonania | Priorytet |
| :--- | :--- | :--- |
| **Mechanika** | **System Żyć i Licznika Rund (`RunState`):** *(Częściowo gotowe)* Zmienne `lives`, `day`, `trophies` i obsługa w `complete_battle()` istnieją w `RunState`. Wymagają dostosowania limitu do 5 żyć i $N$ rund podstawowych. | **Krytyczny** |
| **Mechanika** | **Lokalny Generator Snapshotów (Opponent Emulator):** Stworzenie klasy emulującej 7-8 przeciwników pobieranych na start gry – wyłącznie spośród biegów graczy (botów), którzy dotarli do fazy Deathmatch. Generator dostarcza ich snapshoty z rund 1-$N$. | **Krytyczny** |
| **Mechanika** | **Faza Deathmatch:** Logika przejścia po $N$. rundzie do finałowych starć eliminacyjnych (Deathmatch) z przetrwałymi przeciwnikami wybranymi na początku biegu. | **Krytyczny** |
| **Mechanika** | **Serializacja Drużyny (`to_dict` / `from_dict`):** Dodanie obsługi przekształcania `RunState` i `UnitInstance` do/z formatu Dictionary/JSON pod kątem łatwego wysyłania/pobierania danych drużyn. | **Krytyczny** |
| **Mechanika** | **[x] Zunifikowany System Przedmiotów (Spawnowanie, Rzadkość i Modułowość):** Przebudowa przedmiotów na wzór potworów. | **Zrobione** |
| **Mechanika** | **[x] Poziom Sklepu (Shop Level):** Ulepszanie sklepu i wagi rzadkości. | **Zrobione** |
| **UI / UX** | **Wskaźnik Żyć i Rund w Sklepie/Walce:** *(Częściowo gotowe)* `ShopHeaderBar` wyświetla już lives/day w sklepie. Należy dodać analogiczny wskaźnik do sceny walki `BattleScene` oraz powiadomienie o fazie Deathmatch. | **Krytyczny** |
| **UI / UX & Mechanika** | **Panel Podglądu i Wyboru Przeciwnika w Sklepie:** Przycisk/panel w sklepie pozwalający podejrzeć skład, pozycjonowanie i HP rywala. Wylosowani przeciwnicy pozostają w puli i ulegają zmianie wyłącznie po ich wyeliminowaniu (0 HP) lub użyciu dedykowanego przedmiotu/eventu. | **Krytyczny** |
| **Refaktor** | **[x] Model-View separation & Null-Safety:** Reaktywna architektura sklepu oraz poprawka typowania. | **Zrobione** |
| **UI / UX** | **[x] Galeria / Kompendium:** Scena kompendium prezentująca listę wszystkich istniejących w grze jednostek, przedmiotów i reliktów ([CompendiumScene](file:///d:/Projekty/AutoBattlerDungeonGame/src/features/compendium/compendium_scene.gd)). | **Zrobione** |

---

### Kamień Milowy 2: Rozbudowa Zawartości i Synergii

**Cel Główny:** Znaczące rozszerzenie puli potworów, przedmiotów i reliktów, zapobiegające powstawaniu jednej zdominowanej "mety".

| Kategoria | Zadania do wykonania | Priorytet |
| :--- | :--- | :--- |
| **Mechanika** | **Rozbudowa Puli Potworów (do 25+):** Dodanie nowych potworów z unikalnymi modyfikatorami i mechanikami. | **Krytyczny** |
| **Mechanika** | **Nowe Przedmioty i Relikty:** Dodanie 15+ nowych przedmiotów konsumpcyjnych i reliktów modyfikujących przebieg walki. | **Krytyczny** |
| **UI / UX** | **Ekran Podsumowania Biegu (Run Summary):** Statystyki zebranych wygranych, wykres obrażeń (Damage Meter) i historia stoczonych walk. | Opcjonalny |

---

### Kamień Milowy 3: Polerowanie UI/UX, VFX i Audio

**Cel Główny:** Doprowadzenie gry do poziomu "Premium UX" – bogate animacje, efekty cząsteczkowe i oprawa dźwiękowa.

| Kategoria | Zadania do wykonania | Priorytet |
| :--- | :--- | :--- |
| **UI / UX** | **Efekty Wizualne (VFX) w Walce:** Dodanie linii uderzeń, efektów cząsteczkowych przy trafieniach krytycznych i zaklęciach, oraz trzęsienia ekranu (Screen Shake). | **Krytyczny** |
| **UI / UX** | **Płynne Animacje UI:** Animowanie pojawiania się kart w sklepie, zamrażania oraz przejść między ekranami za pomocą Tweens. | **Krytyczny** |
| **Refaktor** | **Optymalizacja Wydajności i Pamięci:** Profilowanie walki, cache'owanie shaderów, czyszczenie instancji jednostek. | **Krytyczny** |
| **UI / UX** | **Menedżer Dźwięku (Audio System):** Dodanie muzyki adaptacyjnej (Sklep/Walka/Deathmatch) i efektów SFX. | **Krytyczny** |

---

### Kamień Milowy 4: Serwer Backend, Balans i Wydanie

**Cel Główny:** Wdrożenie prawdziwego chmurowego backendu dla snapshotów graczy, zbalansowanie rozgrywki i dystrybucja.

| Kategoria | Zadania do wykonania | Priorytet |
| :--- | :--- | :--- |
| **Backend** | **Moduł Komunikacji Chmurowej (Network / API):** Integracja z backendem (np. Supabase / REST API). Przy rozpoczęciu gry pobieranie 7-8 biegów graczy zakwalifikowanych do Deathmatcha. Wysyłanie snapshotu własnej drużyny na serwer po ukończeniu rund. | **Krytyczny** |
| **Mechanika** | **Balansowanie Statystyk:** Przetestowanie i zbalansowanie $N$ rund, szans na rzadkości kart, przyrostów złota i siły reliktów. | **Krytyczny** |
| **UI / UX** | **Menu Główne i Ustawienia:** Stworzenie sceny startowej z logiem gry, przyciskami "Nowa Gra", profil gracza oraz opcjami audio/wideo. | **Krytyczny** |
| **Błędy / QA** | **Testy Automatyczne:** Napisanie testów jednostkowych (Unit Tests) symulujących 1000 automatycznych walk w tle w celu wykrycia nieskończonych pętli lub awarii silnika. | **Krytyczny** |
| **UI / UX** | **Lokalizacja (Localization):** Dokończenie systemu lokalizacji (polski/angielski). | Opcjonalny |

---

## 3. Przyszłe Rozszerzenia

### **System reliktów i nagród**

* Eventy (np. po 5., 10. i 15. rundzie) gdzie można dostać unikalne relikty/jednostki/gold/odnowic hp/zwiekszyc base health/itd...

### **Zaawansowany System Statystyk (Stat Modifier Pattern)**

Wzorce modyfikacji statystyk (`Stat` oraz `StatModifier` o typach FLAT i PERCENT) zapobiegające konfliktom przy nakładaniu dziesiątek równoległych efektów.
