---
name: sprite-generator
description: Generuje i dostarcza zbalansowane, spójne prompty do generowania sprite'ów jednostek, przedmiotów i reliktów 2D Pixel Art w stylu gier auto-battler (Super Auto Pets / 9 Kings / Pokemon).
---

# Generator Promptów Sprite'ów 2D Pixel Art

Używaj tego skilla, gdy użytkownik poprosi o przygotowanie promptu do wygenerowania nowego sprite'a jednostki (potwora), przedmiotu (itemu) lub reliktu do gry.

**Zasada Działania:** Twoim głównym zadaniem jest wygenerowanie i dostarczenie samych tekstowych promptów (w bloku kodu gotowym do skopiowania), dopasowanych do opisu użytkownika. NIE wywołuj generowania obrazów (`generate_image`), chyba że użytkownik wprost poprosi o testowe wygenerowanie grafiki.

## Zasady Tworzenia Promptów:

1. **Perspektywa:** Jednostki są zawsze skierowane w prawą stronę (`facing right`, `side profile view`).
2. **Kadr i Pozycja (Rozmiar):** 
   - **Duży (domyślny):** Zajmuje ~80% płótna (`filling 80% canvas height`).
   - **Mały / Kompaktowy (np. gałązka, mały przedmiot):** Zajmuje ~40% lub 50% płótna z dużym odstępem (`small sprite, compact size, filling 40% of canvas height, large white padding around`).
   - **Jednostka:** Usytuowana blisko dolnej krawędzi (`positioned low near bottom`).
   - **Przedmiot:** Wyśrodkowany (`centered on canvas`).
3. **Tło i Cienie:** Bez cieni na ziemi (`NO GROUND SHADOW`, `NO DROP SHADOW`), bez podłoża/podłogi, bez ramek. Wyłącznie jednolite białe tło (`PURE SOLID FLAT WHITE BACKGROUND ONLY`).
4. **Obrys (Outline):** Bardzo gruby, jednolicie 5-pikselowy czarny obrys krawędzi (`uniform 5-pixel thick solid black outer outline around the entire silhouette`, `heavy 5px black stroke contour`). Dla złożonych postaci unikać drobnych kropel/liści na zewnątrz i stosować zwięzłe bryły (`bold blocky shapes`), aby AI nie odchudzało obrysu.
5. **Styl i Poziom Szczegółów:** 2D Pixel Art (`16-bit retro style`, `crisp low-res pixel grid`), zbalansowany poziom szczegółów (`balanced moderate detail level, clean readable character design`), proste cieniowanie dwutonowe (`flat cell shading`).

---

## Szablony Promptów (Gotowe do skopiowania):

### 1. Jednostki / Potwory (Units):
```text
2D pixel art game sprite of [OPIS JEDNOSTKI], extra thick heavy black outer outline border, bold heavy black pixel border around the entire body, balanced moderate detail level, clean readable character design, matching the style and proportions of reference images. Crisp low-res pixel grid, facing right, side profile view, positioned low near the bottom, filling 80% canvas height. ABSOLUTELY NO GROUND SHADOW, NO DROP SHADOW, NO FLOOR, PURE SOLID FLAT WHITE BACKGROUND ONLY.
```

### 2. Przedmioty / Relikty (Items / Relics):
```text
2D pixel art icon of [OPIS PRZEDMIOTU], extra thick heavy black outer outline border, bold heavy black pixel border around the item, balanced moderate detail level, clean readable design, matching the style of reference images. Crisp low-res pixel grid, centered on canvas, filling 85% frame height. ABSOLUTELY NO GROUND SHADOW, NO DROP SHADOW, NO FLOOR, PURE SOLID FLAT WHITE BACKGROUND ONLY.
```

### 3. Małe Obiekty przy Dolnej Krawędzi (Small Bottom-Aligned Sprites):
```text
2D pixel art game sprite of [OPIS MAŁEGO OBIEKTU], small sprite, compact size, filling 40% of canvas height, positioned very low touching the bottom edge, extra thick heavy black outer outline border, bold heavy black pixel border around the item, balanced moderate detail level, clean readable design, matching the reference style. Crisp low-res pixel grid, horizontally centered. ABSOLUTELY NO GROUND SHADOW, NO DROP SHADOW, NO FLOOR, PURE SOLID FLAT WHITE BACKGROUND ONLY.
```
