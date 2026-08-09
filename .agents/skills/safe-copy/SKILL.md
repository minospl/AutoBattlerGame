---
name: safe-copy
description: Wymusza fizyczne kopiowanie kodu za pomocą skryptu PowerShell, aby uniknąć halucynacji AI przy przenoszeniu niezmienionego kodu.
---
# Bezpieczne Kopiowanie Kodu (Safe Copy)

Gdy zadanie wymaga przeniesienia, skopiowania lub zastąpienia całego, niezmienionego bloku kodu (np. przeniesienie dużej funkcji z jednego pliku do drugiego bez jej modyfikacji):

1. **BEZWZGLĘDNY ZAKAZ UŻYWANIA LLM DO KOPIOWANIA**: Nie używaj narzędzi `replace_file_content` ani `multi_replace_file_content` do wklejania dużych bloków skopiowanego kodu. Zmusza Cię to do generowania tekstu z pamięci co grozi drobnymi, niewidocznymi halucynacjami (np. podmiana zmiennej heal na health).
2. **UŻYJ SKRYPTU POWERSHELL**: Musisz użyć narzędzia `run_command`, aby uruchomić skrypt `d:\Projekty\AutoBattlerDungeonGame\.agents\scripts\copy_block.ps1`.

### Jak używać skryptu

Skrypt przyjmuje następujące parametry:
- `-SourceFile`: Bezwzględna ścieżka do pliku źródłowego.
- `-StartLine`: Numer linii początkowej do skopiowania (1-indexed).
- `-EndLine`: Numer linii końcowej do skopiowania (1-indexed).
- `-DestFile`: Bezwzględna ścieżka do pliku docelowego.

Opcjonalne tryby wklejania (wybierz jeden):
- **Append (Domyślnie)**: Pomiń dodatkowe argumenty, aby dopisać skopiowany blok na końcu `DestFile`.
- **Insert**: Podaj `-InsertAtLine <numer>` aby wkleić kod od podanej linii (dotychczasowy kod od tej linii zostanie przesunięty w dół).
- **Replace**: Podaj `-ReplaceStartLine <numer> -ReplaceEndLine <numer>` aby w pełni usunąć wskazany zakres w `DestFile` i w jego miejsce wstawić skopiowany blok.

### Przykład użycia za pomocą run_command:

Otwórz w narzędziu `run_command` powłokę `powershell` (lub cmd) i wywołaj:
```powershell
powershell -ExecutionPolicy Bypass -File "d:\Projekty\AutoBattlerDungeonGame\.agents\scripts\copy_block.ps1" -SourceFile "d:\Projekty\AutoBattlerDungeonGame\src\plik_A.gd" -StartLine 10 -EndLine 25 -DestFile "d:\Projekty\AutoBattlerDungeonGame\src\plik_B.gd" -ReplaceStartLine 40 -ReplaceEndLine 55
```
Zawsze upewniaj się, że używasz absolutnych ścieżek. W razie potrzeby użyj `grep_search` aby najpierw określić poprawne linie.
