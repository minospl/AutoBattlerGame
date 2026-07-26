# Specyfikacja i Plan Wdrożenia Typu Slime (Slime Combine Build)

## 1. Koncepcja Typu Slime

* **Standardowy UnitType:** Slime jest pełnoprawnym, 9. typem jednostki (obok Earth, Plant, Water, Dragon, Beast, Toxic, Electric, Fire).
* **Typy:** Wszystkie warianty (np. *Electric Slime*, *Toxic Slime*, *Fire Slime*) posiadają typ `Slime` i dodatkowy typ np. `Electric`.
* **Różnorodność wariantów:** Poszczególne Slime'y różnią się nazwą, statystykami oraz unikalnymi modyfikatorami akcji (np. jeden nakłada Poison, inny Electrocute, kolejny Shield).

---

## 2. Mechanika Fuzji (Rainbow Slime Evolve)

1. **Warunek Aktywacji:** Po zakończeniu walki (w fazie sklepu / przy podsumowaniu rundy), jeśli w aktywnej drużynie (siatka 2x3) znajduje się **6 różnych jednostek o typie Slime**.
2. **Fuzja i Statystyki:**
   * Wszystkie 6 Slime'ów scala się w 1 nową jednostkę: **Rainbow Slime**.
   * `Rainbow Slime` przejmuje zsumowane statystyki wszystkich 6 połączonych Slime'ów (Wartość - Bazowa wartość, bez cast speed).
3. **Kumulatywne Modyfikatory Rainbow Slime'a:**
   * Po scaleniu Slime'ów, `Rainbow Slime` uzyskuje wszystkie modyfikatory połączonych Slime'ów wraz z ich indywidualnymi poziomami (levelami).
   * Wykonuje sekwencyjnie wszystkie przejęte modyfikatory z zachowaniem ich właściwych poziomów.
   * **Ogólna Mechanika Słowa Kluczowego EXCLUSIVE (Dla Wszystkich Kart w Grze):** `EXCLUSIVE` to uniwersalne słowo kluczowe opisujące dowolną kartę/jednostkę w grze. Modyfikatory oznaczone tagiem `EXCLUSIVE` (używane m.in. u `Dragon Slime`) nie kumulują się. Jeśli w aktywnej drużynie (lub wśród scalanych jednostek w `Rainbow Slime`) znajduje się więcej niż jedna karta z tym samym modyfikatorem `EXCLUSIVE`, efekt wywołuje się **TYLKO RAZ** – wyłącznie z instancji o najwyższym poziomie (level).
   * **Rejestracja Słowa Kluczowego:** Należy dodać `EXCLUSIVE` jako ogólne słowo kluczowe w `KeywordDatabase` (title: `"EXCLUSIVE"`, desc: `"Exclusive effects do not stack in the team. Only one effect triggers — from the unit with the highest level (LVL)."`).

---

## 3. Przykładowe Warianty Jednostek Typu Slime

* **Earth Slime** (Earth / Slime)
* **Plant Slime** (Plant / Slime)
* **Water Slime** (Water / Slime)
* **Toxic Slime** (Toxic / Slime)
* **Electric Slime** (Electric / Slime)
* **Fire Slime** (Fire / Slime)
* **Dragon Slime** (Dragon / Slime)
* **Beast Slime** (Beast / Slime)

---

## 4. Etapy Implementacji

* [x] **Krok 1:** Utworzenie pliku zasobu typu `slime.tres` w `src/features/units/types/`.
* [x] **Krok 2:** Utworzenie szablonów i skryptów modyfikatorów wariantów Slime'ów w `src/features/units/templates/` (Earth, Plant, Water, Dragon, Beast, Toxic, Electric, Fire).
* [ ] **Krok 3:** Rejestracja słowa kluczowego `EXCLUSIVE` w `KeywordDatabase` oraz oznaczenie nim `Dragon Slime`.
* [ ] **Krok 4:** Implementacja skryptu sprawdzającego warunek fuzji 6 różnych Slime'ów po rundzie (`RunState` / `ShopScene`).
* [ ] **Krok 5:** Stworzenie szablonu oraz skryptu modyfikatora dla `Rainbow Slime` z obsługą sekwencyjnego wykonywania modyfikatorów oraz respektowania zasady `EXCLUSIVE`.
* [ ] **Krok 6:** Testy integracyjne i balans.
