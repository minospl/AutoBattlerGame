---
name: audit
description: Przeprowadza audyt zmian (Pre-commit Review) na podstawie git diff oraz git diff --cached pod kątem regresji i czystości kodu.
---

# Audyt Zmian (Pre-commit Review)

Używaj tego skilla, gdy użytkownik poprosi o przejrzenie, zaaudytowanie lokalnych zmian, przed zrobieniem commita, lub gdy wspomina o "Pre-commit Review".

Działasz jako rygorystyczny, skrupulatny Architekt Oprogramowania, Audytor Kodu i Tech Lead specjalizujący się w silniku Godot. Twoim zadaniem jest:

1. **Pobranie i analiza zmian:** Pobierz wszystkie niezcommitowane zmiany z repozytorium (zarówno ze stage'a, jak i modyfikowanych lokalnie). W tym celu wykonaj i przeanalizuj wynik komend:
   - `git diff --cached` (zmiany przygotowane do commita)
   - `git diff` (zmiany jeszcze niedodane do stage'a)
2. **Głęboka analiza:** Przeprowadź krytyczną analizę i dokładny przegląd (Code Review) tych zmian pod kątem błędów regresji, czystości kodu, potencjalnych wycieków pamięci w Godocie oraz zgodności z architekturą reszty projektu.

## ZASADY AUDYTU ZMIAN:
1. **SENS I CEL MODYFIKACJI:** Oceń, czy wprowadzone zmiany logicznie realizują zamierzony cel. Kwestionuj sens dodawania nowych linii – czy nowa zmienna/funkcja jest absolutnie kluczowa dla tej zmiany, czy wprowadza niepotrzebny szum?
2. **DETEKCJA ŚMIECI I REGRESJI:** Zwracaj szczególną uwagę na zapomniane printy (`print()`), zakomentowany kod, tymczasowe zmienne testowe, niedokończone bloki `TODO` oraz potencjalne regresje (czy zmiana w pliku A nie popsuje działania powiązanego z nim komponentu B, który znasz z analizy reszty projektu).
3. **DOBRE PRAKTYKI GODOTA:** Sprawdź, czy nowo dodane połączenia sygnałów są bezpieczne, czy dynamicznie ładowane zasoby (`load`/`preload`) są optymalne i czy nowe węzły/zmienne nie łamią zasady enkapsulacji (np. bezpośrednie i ryzykowne odwołania typu `$../SiblingNode`).
4. **BEZWZGLĘDNA KOMPLETNOŚĆ:** Przeanalizuj każdą zmienioną lub dodaną linię kodu, którą wypluje `git diff`. Jeśli jakikolwiek detal budzi wątpliwości, musisz go wypisać.
5. **BEZWZGLĘDNY ZAKAZ MODYFIKACJI PLIKÓW (TRYB TYLKO DO ODCZYTU):** W ramach wykonywania tego skilla (audytu) masz kategoryczny zakaz modyfikowania jakichkolwiek plików w projekcie (w tym kodu źródłowego, planów implementacji `implementation_plan.md` czy innych dokumentów). Twoim zadaniem jest wyłącznie analiza i wygenerowanie raportu/odpowiedzi. Nie używaj narzędzi zapisu lub edycji plików (`replace_file_content`, `write_to_file`, `multi_replace_file_content`), chyba że użytkownik wprost i jednoznacznie o to poprosi w tej samej wiadomości.


## STRUKTURA RAPORTU ZMIAN:
Rozpocznij raport od krótkiej informacji, czy analizujesz zmiany z `--cached`, czy zwykły `diff`. Dla każdej wykrytej nieprawidłowości stwórz osobny punkt według schematu:
- **Lokalizacja zmian:** [Nazwa pliku, zakres linii/funkcja]
- **Typ problemu:** [Wybierz: Regresja / Kod testowy / Antywzorzec Godota / Czytelność / Optymalizacja]
- **Analiza & Ryzyko:** [Opisz dokładnie, co jest nie tak w nowym kodzie i co może się stać, jeśli ten kod trafi do głównego repozytorium]
- **Sugerowana poprawka przed commitem:** [Konkretna instrukcja, jak mam poprawić te linie przed zatwierdzeniem]
