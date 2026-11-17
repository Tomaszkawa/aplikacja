# ANDON — System zgłaszania awarii

Mobilny prototyp z laboratorium: operator zgłasza awarie maszyn, utrzymanie ruchu aktualizuje statusy.

## Struktura

```
andon-system/
├── backend/   # FastAPI + SQLite + Swagger
└── mobile/    # Flutter (Android / iOS / desktop / web)
```

## Backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

- API: http://127.0.0.1:8000
- Swagger: http://127.0.0.1:8000/docs

### Endpointy

| Metoda | Ścieżka | Opis |
|--------|---------|------|
| GET | `/machines` | Lista maszyn |
| GET | `/incidents` | Lista zgłoszeń |
| POST | `/incidents` | Nowe zgłoszenie (`open`) |
| PATCH | `/incidents/{id}` | Zmiana statusu |

Przejścia statusu: `open` → `in_progress` → `resolved`.

## Aplikacja mobilna (Flutter)

Wymaga Flutter SDK w `PATH` (np. `C:\Users\user\flutter\bin`).

```powershell
cd mobile
flutter pub get
flutter run
```

Domyślny adres API:

- emulator Android → `http://10.0.2.2:8000`
- desktop / web / iOS simulator → `http://127.0.0.1:8000`
- telefon fizyczny → ustaw IP komputera w `lib/config.dart` (`overrideBaseUrl`)

### Ekrany

1. **Maszyny** — lista z kolorowym statusem (Sprawna / Awaria / Naprawa)
2. **Nowe zgłoszenie** — maszyna, opis, priorytet, POST
3. **Zgłoszenia** — lista z kolorami statusów i przyciskiem PATCH

## Testy akceptacyjne (lab)

1. Aplikacja pobiera i wyświetla maszyny z API  
2. Operator wybiera maszynę i wypełnia formularz  
3. POST tworzy zgłoszenie ze statusem `open`  
4. Nowe zgłoszenie pojawia się na liście po odświeżeniu  
5. PATCH zmienia status na `in_progress`, potem `resolved`  
6. Błędne dane / brak połączenia → czytelny komunikat  
