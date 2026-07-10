# Weryfikacja kodu i zapobieganie błędom
Podczas edycji i analizy kodu zawsze przestrzegaj tych zasad:
* **Minimalizacja halucynacji i weryfikacja kodu** Zanim założysz istnienie jakiejkolwiek metody, zmiennej lub wartości enuma w klasach pomocniczych i zasobach, ZAWSZE otwórz i przeanalizuj powiązane pliki źródłowe (`.gd` lub `.tres`) w celu weryfikacji ich rzeczywistej implementacji.
* **Spłaszczanie struktury kodu (Guard Clauses):** Unikaj głębokich zagnieżdżeń bloków `if` w logice gry i interfejsu. Dąż do zmniejszenia wcięć tabulacji poprzez stosowanie klauzul strażniczych (wczesnych powrotów `return` na początku funkcji).
* **Zasada Szerokiej Analizy i Walka z Tunnel Vision:**
    * **Analiza Konsekwencji:** Zanim wprowadzisz jakąś zmianę, pomyśl o jej szerokich konsekwencjach. Czy powiązane zmienne, sygnatury metod pomocniczych lub węzły w scenach `.tscn` stają się niepotrzebne? Jeśli tak, usuń je zamiast pisać puste obejścia.
    * **Brak Ślepego Kopiowania (No Boilerplate):** Kopiując wzorce, zawsze upewnij się, że obiekt docelowy potrzebuje wszystkich tych mechanik (nie twórz nadmiarowych metod i pól).
    * **Zgodność Stylistyczna:** Wszystkie nowo generowane opisy, wartości i teksty UI muszą zachować formatowanie spójne z istniejącymi elementami (np. używanie jednolitych tagów formatowania tekstu i kolorów).
    * **Ujednolicone Szablony UI:** Wszelkie generyczne węzły i szablony w plikach `.tscn` (np. powielane w pętli) muszą mieć ogólne nazwy klasowe/funkcjonalne, a nie powiązane z konkretnymi wariantami danych.