# Przegląd Projektu i Wytyczne: AutoBattlerDungeonGame

Ten dokument zawiera analizę projektu i służy jako baza wiedzy oraz zbiór reguł dla asystenta AI (Antigravity). Szczegółowy plan rozwoju (roadmapa) projektu z podziałem na kamienie milowe znajduje się w pliku [project_road_map.md](file:///d:/Projekty/AutoBattlerDungeonGame/project_road_map.md) w głównym katalogu projektu.


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

### Wspólne punkty życia drużyny (Shared Team Health)
W fazie walki jednostki nie otrzymują obrażeń indywidualnie:
*   **Sumowanie Zdrowia:** Przy starcie walki (`load_team_units()`), punkty zdrowia (`health`) wszystkich aktywnych jednostek w drużynie są sumowane w jedną wspólną pulę zdrowia drużyny (`health` oraz `max_health` klasy `BattleTeam`).
*   **Aplikowanie Obrażeń:** Wszystkie otrzymywane obrażenia (zarówno ataki fizyczne, jak i obrażenia od statusów Trucizny czy Oparzenia) są odejmowane bezpośrednio od wspólnej puli zdrowia/tarczy całej drużyny. Statystyki zdrowia poszczególnych potworów (`UnitInstance.health`) pozostają w trakcie walki nienaruszone przez otrzymywane obrażenia.
*   **Modyfikatory Statystyk:** Efekty modyfikatorów w walce (np. `BUFF_HEALTH`) mogą modyfikować statystyki konkretnej jednostki (`UnitInstance.health`) – jeśli zmiana ta ma charakter permanentny (`UnitModifier.Duration.PERMANENT`), to po zakończeniu walki zaktualizowana wartość zdrowia jednostki jest przepisywana z powrotem do stanu gry (`RunState`).
*   **Warunek Porażki:** Drużyna zostaje pokonana, a sygnał `team_defeated` wyemitowany, gdy wspólne zdrowie drużyny (`health`) spadnie do `0` lub poniżej.

### Obiektowy System Modyfikatorów (Modular Unit Modifiers)
Każda jednostka z unikalną zdolnością posiada przypisany modyfikator dziedziczący po klasie bazowej `UnitModifier` (`src/features/units/unit_modifier.gd`):
*   **Modułowość i Hermetyzacja**: Zamiast jednego centralnego silnika z instrukcją `match`, zachowanie modyfikatora (akcja w walce) definiuje się w dedykowanym skrypcie w folderze `src/features/units/templates/modifiers/` poprzez nadpisanie metody `apply_modifier(source_idx: int, team_obj: BattleTeam) -> void`.
*   **Dynamiczny Opis**: Modyfikatory nadpisują metodę `get_description() -> String` zwracającą sformatowany tekst tooltipu. Aby zachować spójność wizualną, do formatowania nazwy momentu aktywacji używa się metody klasy bazowej `get_trigger_name(p_trigger: Trigger = trigger) -> String` (np. `get_trigger_name()` lub `get_trigger_name(Trigger.ON_BATTLE_START)`).
*   **Zmienne Eksportowane (@export)**: Wszelkie wartości liczbowe modyfikatora (np. siła leczenia, wartość buffu) powinny być deklarowane jako `@export` klasy modyfikatora (np. `@export var health_buff: int = 5`). Umożliwia to łatwe zarządzanie nimi bezpośrednio z poziomu inspektora Godota w plikach szablonów `.tres`.



---

## 4. Wytyczne i Dobre Praktyki dla Asystenta AI (Antigravity)
Podczas edycji lub rozbudowy tego projektu muszę przestrzegać następujących reguł:

1.  **Ścisłe typowanie (Static Typing):** W pliku `project.godot` włączone są restrykcyjne ostrzeżenia kompilatora GDScript (`untyped_declaration=1`, `unsafe_property_access=1`, `inferred_declaration=1` itp.). Należy przestrzegać następujących zasad:
    *   **Brak wnioskowania typów (Inferred Types):** Nie używaj operatora wnioskowania `:=` (np. `var x := 5` lub `var inst := run_state.active_team[i]`). Wszystkie zmienne muszą mieć w pełni i jawnie zadeklarowany typ (np. `var x: int = 5`, `var inst: UnitInstance = ...`).
    *   **Typowanie iteratorów pętli:** Każdy iterator w pętli `for` musi mieć zadeklarowany typ (np. `for i: int in range(6):` lub `for slot: ShopCardSlot in slots:`).
    *   **Typowanie lambd/funkcji anonimowych:** Wszystkie lambdy przypisywane do zmiennych lub przekazywane jako Callables muszą mieć otypowane parametry oraz określony typ zwracany (np. `var find_template: Callable = func(p_name: String) -> UnitData:`).
    *   **Bezpieczny dostęp (Unsafe Access):** Unikaj ostrzeżeń `unsafe_property_access`. Przypisuj dynamicznie pobierane obiekty bezpośrednio do zmiennych z jawnym typem podklasy (np. `var card: ShopCard = slots[i].get_card()`), co jest dozwolone i bezpieczne dla obiektów z hierarchii klas bazowych. Używaj rzutowania `as` tylko przy odczycie pól typu `Variant` (np. `card.get("unit_instance") as UnitInstance`) lub przy rzutowaniu obiektów z typów dynamicznych.
    *   **Jawne rzutowanie typów:** Podczas wczytywania scen, skryptów lub zasobów zawsze rzutuj załadowany zasób (np. `load(path) as PackedScene` or `load(path) as Script`).
    *   **Bezpieczne rzutowanie ze słowników (Unsafe Casts):** Dla stałych słowników klasowych zawsze używaj silnego typowania generycznego (np. `var active_statuses: Dictionary[String, StatusEffect] = {}`). Zapobiega to zwracaniu typu `Variant` i ostrzeżeniom `UNSAFE_CAST` przy odczycie.
2.  **Dobre praktyki Godot 4.x & GDScript:**
    *   **Konwencje Nazewnictwa:** Klasy w PascalCase (`class_name MyClass`), zmienne i funkcje w snake_case (`func load_game()`), stałe w UPPER_SNAKE_CASE (`const MAX_SIZE = 6`).
    *   **Referencje do węzłów:** Do pobierania węzłów z drzewa sceny używaj mechanizmu unikalnych nazw (`%UniqueNodeName`) oraz słowa kluczowego `@onready` (np. `@onready var play_button = %PlayButton`). Zapobiega to psuciu się referencji po zmianie struktury sceny.
    *   **Zarządzanie Pamięcią:** Zawsze używaj `queue_free()` zamiast `free()` do bezpiecznego usuwania węzłów pod koniec klatki.
    *   **Wydajność:** Unikaj wywołań wyszukiwania węzłów (`get_node()` lub `$`) w pętlach i funkcjach cyklicznych takich jak `_process()` lub `_physics_process()`. Cache'uj referencje w zmiennych `@onready`.
    *   **Obsługa Sygnałów:** Preferuj łączenie sygnałów w kodzie za pomocą bezpiecznej składni Godot 4 (np. `button.pressed.connect(_on_button_pressed)`).
3.  **Architektura bez Autoloadów (Singletons):** Stan gry (`RunState`) nie jest singletonem. Jest przekazywany bezpośrednio między scenami w funkcjach `setup()`. Należy unikać wprowadzania globalnych autoloadów, chyba że jest to absolutnie konieczne.
4.  **Podział Logiki i UI:** Komponenty interfejsu (np. `ShopCardSlot`, `BattleCardSlot`) wizualizują stan logiczny obiektów typu `UnitInstance` i `ShopItemInstance`. Zmiany w UI muszą być synchronizowane z danymi w logicznych strukturach (funkcja `sync_data_from_ui()`).
5.  **Zachowanie Premium UI:** Zmiany wizualne powinny zachowywać estetyczny, spójny styl gry (ciemne tła, dopasowane kolory zdefiniowane w `GameColors`, płynne przejścia).
6.  **Minimalizacja halucynacji i weryfikacja kodu:** Zanim założysz istnienie jakiejkolwiek metody, zmiennej lub wartości enuma w klasach pomocniczych (np. `UnitModifier.Trigger`), ZAWSZE otwórz i przeanalizuj powiązane pliki źródłowe (.gd lub .tres) w celu weryfikacji ich rzeczywistej implementacji. Jeśli nie jesteś czegoś pewien, zbadaj bazę kodu zamiast zgadywać.
7.  **Zasada Szerokiej Analizy i Walka z Tunnel Vision:**
    *   **Analiza Konsekwencji:** Zanim wprowadzisz jakąś zmianę (np. ukryjesz panel lub zmodyfikujesz flagę), pomyśl o jej szerokich konsekwencjach. Czy powiązane zmienne, sygnatury metod pomocniczych lub węzły w scenach `.tscn` stają się niepotrzebne? Jeśli tak, usuń je zamiast pisać puste obejścia.
    *   **Brak Ślepego Kopiowania (No Boilerplate):** Kopiując wzorce (np. z jednostek do przedmiotów), zawsze upewnij się, że obiekt docelowy potrzebuje wszystkich tych mechanik (np. przedmioty nie potrzebują skalowania poziomów i `get_modifier_value`).
    *   **Zgodność Stylistyczna:** Wszystkie nowo generowane opisy, wartości i teksty UI muszą zachować formatowanie spójne z istniejącymi elementami (np. używanie kolorów BBCode `GameColors.DESC_HEALTH` w opisach).
    *   **Ujednolicone Szablony UI:** Wszelkie generyczne węzły matryc w `.tscn` (np. powielane w pętli) muszą mieć ogólne nazwy typu `StatPanel` czy `LabelTemplate`, a nie konkretne `AttackPanel`.
8.  **Spłaszczanie struktury kodu (Guard Clauses):** Unikaj głębokich zagnieżdżeń bloków `if` w logice gry i interfejsu. Dąż do zmniejszenia wcięć tabulacji poprzez stosowanie klauzul strażniczych (wczesnych powrotów `return` na początku funkcji).

