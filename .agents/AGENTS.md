# Przegląd Projektu i Wytyczne: AutoBattlerDungeonGame

Ten dokument zawiera analizę projektu i służy jako baza wiedzy oraz zbiór reguł dla asystenta AI (Antigravity). Szczegółowy plan rozwoju (roadmapa) projektu z podziałem na kamienie milowe znajduje się w pliku [project_road_map.md](file:///d:/Projekty/AutoBattlerDungeonGame/project_road_map.md) w głównym katalogu projektu.

## Weryfikacja kodu i zapobieganie błędom

Podczas edycji i analizy kodu zawsze przestrzegaj tych zasad:

* **Minimalizacja halucynacji i weryfikacja kodu** Zanim założysz istnienie jakiejkolwiek metody, zmiennej lub wartości enuma w klasach pomocniczych i zasobach, ZAWSZE otwórz i przeanalizuj powiązane pliki źródłowe (`.gd` lub `.tres`) w celu weryfikacji ich rzeczywistej implementacji.
* **Spłaszczanie struktury kodu (Guard Clauses):** Unikaj głębokich zagnieżdżeń bloków `if` w logice gry i interfejsu. Dąż do zmniejszenia wcięć tabulacji poprzez stosowanie klauzul strażniczych (wczesnych powrotów `return` na początku funkcji).
* **Zasada Szerokiej Analizy i Walka z Tunnel Vision:**
  * **Analiza Konsekwencji:** Zanim wprowadzisz jakąś zmianę, pomyśl o jej szerokich konsekwencjach. Czy powiązane zmienne, sygnatury metod pomocniczych lub węzły w scenach `.tscn` stają się niepotrzebne? Jeśli tak, usuń je zamiast pisać puste obejścia.
  * **Brak Ślepego Kopiowania (No Boilerplate):** Kopiując wzorce, zawsze upewnij się, że obiekt docelowy potrzebuje wszystkich tych mechanik (nie twórz nadmiarowych metod i pól).
  * **Zgodność Stylistyczna i Zasada Tooltipów:** Wszystkie nowo generowane opisy, wartości i teksty UI muszą zachować formatowanie spójne z istniejącymi elementami. **Zasada Tooltipów:** Wszelkie kolorowane słowa kluczowe, nazwy statystyk (np. `ATK`, `HP`, `HEAL`, `SHIELD`, `POISON`, `BURN`, `ELECTROCUTE`), wyzwalacze oraz cele ujęte w znaczniki `[color=...]` ZAWSZE muszą być napisane w 100% WIELKIMI LITERAMI.
  * **Ujednolicone Szablony UI:** Wszelkie generyczne węzły i szablony w plikach `.tscn` (np. powielane w pętli) muszą mieć ogólne nazwy klasowe/funkcjonalne, a nie powiązane z konkretnymi wariantami danych.
* **Eliminacja nadmiarowych warunków obronnych (Universal Rule):** Unikaj pisania redundantnych/nadgorliwych sprawdzeń `if` i `null`. Zawsze klasyfikuj dane przed dodaniem warunku:
  * **Statyczna Konfiguracja (Zasoby `.tres`, szablony jednostek/przedmiotów/reliktów):** Zakładamy, że są w 100% poprawnie wypełnione w edytorze przez projektanta. Brak przypisania rzadkości, typu czy ikony w Inspektorze to błąd konfiguracji (designer error), a nie błąd runtime. Kod NIE powinien przed tym bronić (programowanie kontraktowe / fail-fast).
  * **Dynamiczny Stan Rozgrywki (Drużyna, ławka, sloty w sklepie, obiekty na scenie):** Te elementy mogą ulegać zmianie w czasie rzeczywistym i być puste (np. brak jednostki w drużynie, zniszczony obiekt). W tych przypadkach warunek sprawdzający obecność (`if object:`) jest logicznie uzasadniony i wymagany.
  * **Myślowy Test Kontraktu:** Zanim zaproponujesz lub dodasz warunek obronny, zadaj sobie pytanie: *„Czy ten obiekt/właściwość jest elementem statycznej konfiguracji edytora, czy dynamicznym stanem gry?”*. Jeśli to konfiguracja – nie pisz null-checka.

## 1. Czym jest ten projekt?

**AutoBattlerDungeonGame** to gra typu **asynchroniczny PvP auto-battler** (inspirowana grami typu Super Auto Pets / 9 Kings / TFT), rozwijana w silniku **Godot 4.7 (Forward Plus)** przy użyciu języka **GDScript**.
Główna pętla gry opiera się na $N$ rundach podstawowych przeciwko snapshotom biegów graczy (którzy dotarli do fazy finałowej) oraz finałowej fazie **Deathmatch**:

1. **Faza sklepu (Shop)** – gracz zarządza złotem, kupuje potwory i przedmioty, buduje drużynę (siatka 2x3), zarządza ławką (6 miejsc), zamraża oferty oraz **posiada podgląd nadchodzącego przeciwnika (jego drużyny, pozycjonowania i HP)** z możliwością wymiany rywala za pomocą eventów/przedmiotów.
2. **Faza walki (Battle)** – automatyczna symulacja starcia drużyny gracza ze snapshotem przeciwnika. Obrażenia zadawane są do wspólnego HP drużyny. Porażka odejmuje 1 życie z puli (domyślnie 5 żyć). Po przetrwaniu $N$ rund następuje faza finałowa **Deathmatch**.

---

## 2. Architektura i Struktura Plików

Kod projektu jest podzielony modularnie w katalogu `src`:

* `src/core/` – Serce gry:
  * `game_root.gd` – Główny kontroler gry zarządzający przełączaniem scen między sklepem a walką.
  * `run_state.gd` – Zasób (Resource) przechowujący stan trwającej rozgrywki (złoto, życia, dni, trofea, stan drużyny i ławki).
* `src/features/units/` – System jednostek/potworów:
  * `unit_data.gd` – Definicja szablonu jednostki (UnitData) jako zasób (Resource): statystyki bazowe, typy, rzadkość, prędkość ładowania, umiejętności.
  * `unit_instance.gd` – Instancja jednostki w czasie rzeczywistym.
  * `unit_modifier.gd` – System zdolności (modyfikatorów), określający wyzwalacze (Trigger), cele (TargetType).
  * `rarity.gd`, `unit_type.gd` – Definicje pomocnicze rzadkości i typu potwora.
  * `templates/` – Gotowe szablony potworów (np. `ancient_titan.tres`, `wild_wolf.tres`, `river_crab.tres`).
* `src/features/items/` – System przedmiotów/konsumabiliów kupowanych w sklepie:
  * `item_data.gd` – Dane statyczne przedmiotu.
  * `item_instance.gd` – Instancja zakupionego przedmiotu.
  * `item_modifier.gd` – Efekty aplikowane na jednostkę przy użyciu przedmiotu.
* `src/features/relics/` – System reliktów (pasywnych modyfikatorów gry):
  * `relic_data.gd` – Dane statyczne reliktu.
  * `relic_instance.gd` – Instancja posiadanego reliktu z liczbą ładunków/poziomem.
  * `relic_modifier.gd` – Logika modyfikacji zasad na początku walki lub przy zdobyciu reliktu.
* `src/features/shop/` – Mechanika sklepu:
  * `shop_scene.gd` – Główny interfejs i logika sklepu.
  * `components/` – Elementy UI sklepu: nagłówek (ShopHeaderBar), panele ławki i drużyny (BenchPanel, TeamPanel), sloty i karty (ShopCardSlot, ShopCard, ShopCardItem), oraz linia celowania modyfikatorów (TargetingLineOverlay).
* `src/features/battle/` – Logika starć:
  * `battle_scene.gd` – Kontroler symulacji walki, pętla czasu rzeczywistego, zmęczenie, skalowanie prędkości (1x, 2x, 3x).
  * `battle_team_model.gd` – Stan zdrowia, statusów, pasywnych reliktów całej drużyny w trakcie walki oraz aplikowanie efektów.
  * `battle_unit_instance.gd` – Dynamiczny wrapper jednostki w walce, przechowujący stan tymczasowych bonusów walki.
* `src/shared/` – Elementy wspólne:
  * `utils/` – Silnik modyfikatorów (`modifier_engine.gd`), wyznaczanie celów (`target_resolver.gd`), pomocnik UI (`card_ui_helper.gd`), globalna baza słów kluczowych (`keyword_database.gd`) oraz pomocnik formatowania liczb (`number_formatter.gd`).
  * `ui/` – Skórki interfejsu (game_theme.tres), dekoratory i komponenty tooltipów.
  * `shaders/` – Cieniowanie interfejsu (np. `hp_border.gdshader`).

---

## 3. Kluczowe Mechaniki Rozgrywki

### Pozycjonowanie (Siatka 2x3)

Pozycjonowanie wpływa bezpośrednio na to, jak działają modyfikatory jednostek (np. nakładanie tarcz na sąsiadów, wzmacnianie jednostki powyżej/poniżej). Celowanie jest rozwiązywane przez `target_resolver.gd`.
Aktywna drużyna jest ułożona w siatkę o wymiarach 2 wiersze na 3 kolumny:

* Sloty `0` (lewy), `1` (środkowy), `2` (prawy)
* Sloty `3` (lewy), `4` (środkowy), `5` (prawy)

Posiadane przez drużynę relikty mogą modyfikować zasięg i zachowanie celowania w `target_resolver.gd`:

* **Magnetic Core**: Zmienia typ celowania `ADJACENT` (sąsiedzi) na `ALL` (wszyscy pozostali członkowie drużyny).
* **Focusing Lens**: Zwiększa zasięg celowania liniowego: `LEFT` -> `LEFT_PLUS`, `RIGHT` -> `RIGHT_PLUS`, `HORIZONTAL` -> `HORIZONTAL_PLUS`.

### Walka i Czas Wykonania Akcji (Cast Speed)

Walka odbywa się automatycznie w czasie rzeczywistym:

* Każdy potwór ma parametr `cast_speed` (w sekundach).
* Gdy stoper danej jednostki osiągnie tę wartość, wykonuje ona swoją kolejną **akcję**, wywołując wszystkie powiązane efekty, takie jak:
  * Bazowy atak (zadaje obrażenia wrogiej drużynie).
  * Efekty statusów (Poison, Burn, Electrocute) na wrogów.
  * Samoleczenie (Heal) lub tarczę (Shield) dla swojej drużyny.
  * Wyzwalacz modyfikatora `ON_CAST` (po wykonaniu akcji).

### Statusy (Status Effects)

* **Poison (Trucizna):** Zadaje obrażenia równe liczbie ładunków co 1.0 sekundy.
* **Burn (Oparzenie):** Zadaje obrażenia równe liczbie ładunków co 0.5 sekundy, po czym zmniejsza liczbę ładunków o 1.
* **Electrocute (Porażenie):** Zwiększa otrzymywane obrażenia przez drużynę o wartość ładunku porażenia, gdy jednostka atakująca ma atak > 0.

### Typy Jednostek i Archetypy (Unit Types)

W grze zdefiniowane jest 8 typów jednostek o ściśle określonych rolach i mechanikach:

* **Earth:** Shield.
* **Plant:** Max HP.
* **Water:** Heal/Cleanse (usuwanie negatywnych statusów).
* **Dragon:** Unique mods (unikalne modyfikatory i mechaniki akcji).
* **Beast:** Physical Damage.
* **Toxic:** Poison.
* **Electric:** Electrocute.
* **Fire:** Burn.

### Zmęczenie (Fatigue)

Czas trwania walki wynosi 30 sekund. Po tym czasie co 1 sekundę obie drużyny otrzymują obrażenia fatigue, które rosną z każdym krokiem zgodnie z ciągiem Fibonacciego.

### Wspólne punkty życia drużyny (Shared Team Health)

W fazie walki jednostki nie otrzymują obrażeń indywidualnie:

* **Sumowanie Zdrowia:** Przy starcie walki (`load_team_units()`), punkty zdrowia (`health`) wszystkich aktywnych jednostek w drużynie są sumowane w jedną wspólną pulę zdrowia drużyny (`health` oraz `max_health` klasy `BattleTeamModel`).
* **Aplikowanie Obrażeń:** Wszystkie otrzymywane obrażenia (zarówno ataki fizyczne, jak i obrażenia od statusów Trucizny czy Oparzenia) są odejmowane bezpośrednio od wspólnej puli zdrowia/tarczy całej drużyny. Statystyki zdrowia poszczególnych potworów (`UnitInstance.health`) pozostają w trakcie walki nienaruszone przez otrzymywane obrażenia.
* **Modyfikatory Statystyk:** Efekty modyfikatorów w walce (np. `BUFF_HEALTH`) mogą modyfikować statystyki konkretnej jednostki (`UnitInstance.health`) – jeśli zmiana ta ma charakter permanentny (`UnitModifier.Duration.PERMANENT`), to po zakończeniu walki zaktualizowana wartość zdrowia jednostki jest przepisywana z powrotem do stanu gry (`RunState`).
* **Warunek Porażki:** Drużyna zostaje pokonana, a sygnał `team_defeated` wyemitowany, gdy wspólne zdrowie drużyny (`health`) spadnie do `0` lub poniżej.

### Obiektowy System Modyfikatorów (Modular Unit Modifiers)

Każda jednostka z unikalną zdolnością posiada przypisany modyfikator dziedziczący po klasie bazowej `UnitModifier` (`src/features/units/unit_modifier.gd`):

* **Modułowość i Hermetyzacja**: Zamiast jednego centralnego silnika z instrukcją `match`, zachowanie modyfikatora (akcja w walce) definiuje się w dedykowanym skrypcie w folderze `src/features/units/templates/modifiers/` poprzez nadpisanie metody `apply_modifier(source_idx: int, team_obj: BattleTeamModel) -> void`.
* **Dynamiczny Opis**: Modyfikatory nadpisują metodę `get_description() -> String` zwracającą sformatowany tekst tooltipu. Aby zachować spójność wizualną, do formatowania nazwy momentu aktywacji używa się metody klasy bazowej `get_trigger_name(p_trigger: Trigger = trigger) -> String` (np. `get_trigger_name()` lub `get_trigger_name(Trigger.ON_BATTLE_START)`).
* **Zmienne Eksportowane (@export)**: Wszelkie wartości liczbowe modyfikatora (np. siła leczenia, wartość buffu) powinny być deklarowane jako `@export` klasy modyfikatora (np. `@export var health_buff: int = 5`). Umożliwia to łatwe zarządzanie nimi bezpośrednio z poziomu inspektora Godota w plikach szablonów `.tres`.

---

## 4. Wytyczne i Dobre Praktyki dla Asystenta AI

Podczas edycji lub rozbudowy tego projektu muszę bezwzględnie przestrzegać następujących reguł:

* **Ścisłe typowanie (Static Typing):** W pliku `project.godot` włączone są restrykcyjne ostrzeżenia kompilatora GDScript (`untyped_declaration=1`, `unsafe_property_access=1`, `inferred_declaration=1` itp.). Należy przestrzegać następujących zasad:
  * **Brak nieweryfikowalnych typów:** Każda zmienna, w tym zmienne `@onready`, musi mieć jawnie zadeklarowany typ po dwukropku (np. `@onready var confirm_button: Button = %ConfirmButton` – *nigdy* bez określenia typu).
  * **Typowanie iteratorów pętli:** Każdy iterator w pętli `for` musi mieć zadeklarowany typ (np. `for i: int in range(6):` lub `for node: Node in container.get_children():`).
  * **Typowanie lambd/funkcji anonimowych:** Wszystkie lambdy przypisywane do zmiennych lub przekazywane jako Callables muszą mieć otypowane parametry oraz określony typ zwracany (np. `var process_data: Callable = func(p_name: String) -> Variant:`).
  * **Bezpieczny dostęp (Unsafe Access):** Unikaj ostrzeżeń `unsafe_property_access`. Przypisuj dynamicznie pobierane obiekty bezpośrednio do zmiennych z jawnym typem podklasy (np. `var child: ChildClass = parent.get_child(i)`), co jest dozwolone i bezpieczne dla obiektów z hierarchii klas bazowych. Używaj rzutowania `as` tylko przy odczycie pól typu `Variant` (np. `node.get("property") as MyClass`) lub przy rzutowaniu obiektów z typów dynamicznych.
  * **Jawne rzutowanie typów:** Podczas wczytywania scen, skryptów lub zasobów zawsze rzutuj załadowany zasób (np. `load(path) as PackedScene` lub `load(path) as Script`).
  * **Bezpieczne rzutowanie ze słowników (Unsafe Casts):** Dla słowników klasowych reprezentujących stałą strukturę danych zawsze używaj silnego typowania generycznego (np. `var my_dict: Dictionary[String, ResourceClass] = {}`). Zapobiega to zwracaniu typu `Variant` i ostrzeżeniom `UNSAFE_CAST` przy odczycie.

* **Dobre praktyki Godot 4.x & GDScript:**
  * **Konwencje Nazewnictwa:** Klasy w PascalCase (`class_name MyClass`), zmienne i funkcje w snake_case (`func load_game()`), stałe w UPPER_SNAKE_CASE (`const MAX_SIZE = 6`).
  * **Referencje do węzłów:** Do pobierania węzłów z drzewa sceny używaj mechanizmu unikalnych nazw (`%UniqueNodeName`) oraz słowa kluczowego `@onready` z jawnym typem. Zapobiega to psuciu się referencji po zmianie struktury sceny.
  * **Zarządzanie Pamięcią:** Zawsze używaj `queue_free()` zamiast `free()` do bezpiecznego usuwania węzłów pod koniec klatki.
  * **Wydajność i Object Pooling:** Unikaj wywołań wyszukiwania węzłów (`get_node()` lub `$`) w pętlach i funkcjach cyklicznych takich jak `_process()`. Cache'uj referencje w zmiennych `@onready`. Dla obiektów często tworzonych i niszczonych w fazie walki (np. wyskakujące teksty obrażeń/damage popups, pociski, ikony statusów) **wymagane jest** stosowanie wzorca Object Pool zamiast ciągłego `instantiate()` i `queue_free()`.
  * **Obsługa Sygnałów:** Preferuj łączenie sygnałów w kodzie za pomocą bezpiecznej składni Godot 4 (np. `button.pressed.connect(_on_button_pressed)`).

* **Zarządzanie stanem i architekturą:**
  * **Architektura bez Autoloadów (Singletons):** Stan gry nie jest przechowywany w globalnych singletonach. Musi być przekazywany bezpośrednio między scenami za pomocą metod konfiguracyjnych (np. `setup(state)`).
  * **Komunikacja "Sygnały w górę, funkcje w dół":** Aby uniknąć sztywnego sprzężenia (tight coupling) pod nieobecność Autoloadów, węzły-dzieci (szczególnie komponenty UI) nigdy nie wywołują bezpośrednio metod rodziców ani nie szukają ich w drzewie. Dzieci komunikują się w górę wyłącznie za pomocą sygnałów. Rodzice zarządzają dziećmi, wywołując ich funkcje bezpośrednio w dół hierarchii.
  * **Podział Logiki i UI:** Komponenty interfejsu (UI) wizualizują stan logiczny obiektów/zasobów. Wszelkie zmiany w UI muszą być synchronizowane z danymi w logicznych strukturach danych.
  * **Zachowanie Spójności Stylu (Premium UI):** Zmiany wizualne powinny zachowywać estetyczny, spójny styl graficzny zdefiniowany w motywach i kolorach klas wspólnych gry.

* **Ścisłe trzymanie się wymagań i zakaz nadinterpretacji (No Over-Interpretation):**
  * **Ścisłe posłuszeństwo instrukcjom:** Wprowadzaj wyłącznie te zmiany, o które użytkownik bezpośrednio poprosił. ZAKAZUJE SIĘ dodawania na własną rękę jakichkolwiek nieopisanych mechanik, zmiennych, wskaźników UI, o które użytkownik nie wnioskował.
  * **Wątpliwości projektowe:** Jeśli makieta graficzna lub opis zadania wydaje się niejasny, asystent musi zadać pytanie wyjaśniające, zamiast zgadywać intencje i wdrażać domniemane rozwiązania.

* **Ścisłe etapy i tempo pracy (Work Pacing & Boundaries):**
  * **Zasada jednego kroku (Single-Step Execution):** Zaimplementuj wyłącznie JEDNO najmniejsze logiczne zadanie/etap na raz, o ile plan implementacji jest podzielony na etapy. Zadanie to nie powinno być sztucznie ograniczane, jeśli jego kompletne wdrożenie wymaga spójnych modyfikacji. Po pełnym zakończeniu danego zadania/etapu natychmiast zatrzymaj wywoływanie narzędzi, zgłoś wynik i czekaj na potwierdzenie użytkownika.

* **Styl Komunikacji (Communication Style):**
  * **Zwięzłość i Konkretność**: Zawsze odpowiadaj w sposób maksymalnie zwięzły, konkretny i bezpośrednio na temat (do celu). Unikaj zbędnego rozpisywania się, powtórzeń i nadmiernego tłumaczenia.
