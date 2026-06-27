# Przegląd Projektu i Wytyczne: AutoBattlerDungeonGame

Ten dokument zawiera analizę projektu i służy jako baza wiedzy oraz zbiór reguł dla asystenta AI (Antigravity).

## 1. Czym jest ten projekt?
**AutoBattlerDungeonGame** to gra typu auto-battler z elementami dungeon crawler, rozwijana w silniku **Godot 4.7 (Forward Plus)** przy użyciu języka **GDScript**.

Główna pętla gry składa się z dwóch naprzemiennych faz:
1. **Faza sklepu (Shop)** – gracz zarządza zasobami (złotem), kupuje potwory oraz przedmioty (np. Apple, Sword), umieszcza je w aktywnej drużynie (siatka 2x3) lub na ławce rezerwowych (8 miejsc) oraz może zamrażać (freeze) oferty.
2. **Faza walki (Battle)** – automatyczna symulacja starcia drużyny gracza z drużyną przeciwnika. Jednostki automatycznie ładują swoje paski akcji i wykonują akcje, nakładając statusy i wyzwalając modyfikatory.

---

## 2. Architektura i Struktura Plików
Kod projektu jest podzielony modularnie w katalogu `src`:

*   `src/core/` – Serce gry:
    *   `game_root.gd` – Główny kontroler gry zarządzający przełączaniem scen między sklepem a walką.
    *   `run_state.gd` – Zasób (Resource) przechowujący stan trwającej rozgrywki (złoto, życia, dni, trofea, stan drużyny i ławki).
*   `src/features/units/` – System jednostek/potworów:
    *   `unit_data.gd` – Definicja szablonu jednostki (UnitData) jako zasób (Resource): statystyki bazowe, typy, rzadkość, prędkość ładowania, umiejętności.
    *   `unit_instance.gd` – Instancja jednostki w czasie rzeczywistym.
    *   `unit_modifier.gd` – System zdolności (modyfikatorów), określający wyzwalacze (Trigger), cele (TargetType) oraz efekty (EffectType).
    *   `templates/` – Gotowe szablony potworów (np. `ancient_titan.tres`, `wild_wolf.tres`, `river_crab.tres`).
*   `src/features/shop/` – Mechanika sklepu:
    *   `shop_scene.gd` – Główny interfejs i logika sklepu.
    *   `components/` – Elementy UI sklepu: nagłówek (ShopHeaderBar), panele ławki i drużyny (BenchPanel, TeamPanel), sloty i karty (ShopCardSlot, ShopCard, ShopCardItem), oraz linia celowania modyfikatorów (TargetingLineOverlay).
*   `src/features/battle/` – Logika starć:
    *   `battle_scene.gd` – Kontroler symulacji walki, pętla czasu rzeczywistego, zmęczenie, skalowanie prędkości (1x, 2x, 3x).
    *   `battle_team.gd` – Stan zdrowia i statusów całej drużyny w trakcie walki oraz aplikowanie efektów.
*   `src/shared/` – Elementy wspólne:
    *   `utils/` – Silnik modyfikatorów (`modifier_engine.gd`), wyznaczanie celów (`target_resolver.gd`) oraz pomocnik UI (`card_ui_helper.gd`).
    *   `ui/` – Skórki interfejsu (game_theme.tres), dekoratory i komponenty tooltipów.
    *   `shaders/` – Cieniowanie interfejsu (np. `hp_border.gdshader`).

---

## 3. Kluczowe Mechaniki Rozgrywki

### Pozycjonowanie (Siatka 2x3)
Aktywna drużyna jest ułożona w siatkę o wymiarach 2 wiersze na 3 kolumny:
*   **Rząd górny (Row 0):** Sloty `0` (lewy), `1` (środkowy), `2` (prawy)
*   **Rząd dolny (Row 1):** Sloty `3` (lewy), `4` (środkowy), `5` (prawy)

Pozycjonowanie wpływa bezpośrednio na to, jak działają modyfikatory jednostek (np. nakładanie tarcz na sąsiadów, wzmacnianie jednostki powyżej/poniżej). Celowanie jest rozwiązywane przez `target_resolver.gd`.

### Walka i Czas Wykonania Akcji (Cast Speed)
Walka odbywa się automatycznie w czasie rzeczywistym:
*   Każdy potwór ma parametr `cast_speed` (w sekundach).
*   Gdy stoper danej jednostki osiągnie tę wartość, wykonuje ona swoją kolejną **akcję**, wywołując wszystkie powiązane efekty, takie jak:
    *   Bazowy atak (zadaje obrażenia wrogiej drużynie).
    *   Efekty statusów (Poison, Burn, Electrocute) na wrogów.
    *   Samoleczenie (Heal) lub tarczę (Shield) dla swojej drużyny.
    *   Wyzwalacz modyfikatora `ON_CAST` (po wykonaniu akcji).

### Statusy (Status Effects)
*   **Poison (Trucizna):** Zadaje obrażenia równe liczbie ładunków trucizny co 1.0 sekundy.
*   **Burn (Oparzenie):** Zadaje obrażenia równe liczbie ładunków oparzenia co 0.5 sekundy, po czym liczba ładunków oparzenia zmniejsza się o 1.
*   **Electrocute (Porażenie):** Zwiększa kolejne otrzymywane obrażenia przez drużynę o wartość ładunku porażenia.

### Zmęczenie (Fatigue)
*   Czas trwania walki wynosi 30 sekund. Po tym czasie co 1 sekundę obie drużyny otrzymują obrażenia fatigue, które rosną z każdym krokiem zgodnie z ciągiem Fibonacciego.

---

## 4. Wytyczne i Dobre Praktyki dla Asystenta AI (Antigravity)
Podczas edycji lub rozbudowy tego projektu muszę przestrzegać następujących reguł:

1.  **Ścisłe typowanie (Static Typing):** W pliku `project.godot` włączone są ostrzeżenia dotyczące braku typowania (`untyped_declaration=1`, `unsafe_property_access=1` itp.). Każda zmienna, funkcja, wartość zwracana oraz elementy tablic muszą mieć jawnie określony typ (np. `var x: int = 5`, `var team: Array[UnitInstance] = []`, `func foo() -> void`).
2.  **Dobre praktyki Godot 4.x & GDScript:**
    *   **Konwencje Nazewnictwa:** Klasy w PascalCase (`class_name MyClass`), zmienne i funkcje w snake_case (`func load_game()`), stałe w UPPER_SNAKE_CASE (`const MAX_SIZE = 6`).
    *   **Referencje do węzłów:** Do pobierania węzłów z drzewa sceny używaj mechanizmu unikalnych nazw (`%UniqueNodeName`) oraz słowa kluczowego `@onready` (np. `@onready var play_button = %PlayButton`). Zapobiega to psuciu się referencji po zmianie struktury sceny.
    *   **Zarządzanie Pamięcią:** Zawsze używaj `queue_free()` zamiast `free()` do bezpiecznego usuwania węzłów pod koniec klatki.
    *   **Wydajność:** Unikaj wywołań wyszukiwania węzłów (`get_node()` lub `$`) w pętlach i funkcjach cyklicznych takich jak `_process()` lub `_physics_process()`. Cache'uj referencje w zmiennych `@onready`.
    *   **Obsługa Sygnałów:** Preferuj łączenie sygnałów w kodzie za pomocą bezpiecznej składni Godot 4 (np. `button.pressed.connect(_on_button_pressed)`).
3.  **Architektura bez Autoloadów (Singletons):** Stan gry (`RunState`) nie jest singletonem. Jest przekazywany bezpośrednio między scenami w funkcjach `setup()`. Należy unikać wprowadzania globalnych autoloadów, chyba że jest to absolutnie konieczne.
4.  **Podział Logiki i UI:** Komponenty interfejsu (np. `ShopCardSlot`, `BattleCardSlot`) wizualizują stan logiczny obiektów typu `UnitInstance` i `ShopItemInstance`. Zmiany w UI muszą być synchronizowane z danymi w logicznych strukturach (funkcja `sync_data_from_ui()`).
5.  **Zachowanie Premium UI:** Zmiany wizualne powinny zachowywać estetyczny, spójny styl gry (ciemne tła, dopasowane kolory zdefiniowane w `GameColors`, płynne przejścia).
