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
   * `Rainbow Slime` przejmuje zsumowane statystyki wszystkich 6 połączonych Slime'ów (Suma `Max HP`, Suma `Attack`).
3. **Uwolnienie Slotów:**
   * Zwalnia się 5 miejsc w aktywnej drużynie, co pozwala graczowi kupić nowe Slime'y ze sklepu lub przenieść je z ławki rezerwowych.
4. **Pasywna Aura Rainbow Slime'a:**
   * `Rainbow Slime` posiada obszarową/drużynową pasywkę wzmacniającą obecne i nowo postawione Slime'y w drużynie.

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
* [ ] **Krok 3:** Implementacja skryptu sprawdzającego warunek fuzji 6 różnych Slime'ów po rundzie (`RunState` / `ShopScene`).
* [ ] **Krok 4:** Stworzenie szablonu oraz skryptu modyfikatora dla `Rainbow Slime`.
* [ ] **Krok 5:** Testy integracyjne i balans.
