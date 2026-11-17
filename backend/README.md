# ANDON Backend

REST API dla systemu zgłaszania awarii maszyn.

## Uruchomienie

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Swagger UI: http://127.0.0.1:8000/docs

## Endpointy

| Metoda | Ścieżka | Opis |
|--------|---------|------|
| GET | `/machines` | Lista maszyn |
| GET | `/incidents` | Lista zgłoszeń |
| POST | `/incidents` | Nowe zgłoszenie (`status=open`) |
| PATCH | `/incidents/{id}` | Zmiana statusu |

Dozwolone przejścia statusu: `open` → `in_progress` → `resolved`.
