# MeBTC Frontend (Vue + Vite)

Ziel: Das Frontend lokal starten (Windows, Linux, macOS).

## Option A: Dev-Server (empfohlen, mit Hot Reload)
Voraussetzungen: Node.js 18+ (empfohlen 20 LTS) und npm.

Schritte (alle OS):
1) In diesen Ordner wechseln: `cd frontend-vue`
2) Env Datei anlegen:
   - Windows PowerShell: `Copy-Item .env.example .env`
   - Windows CMD: `copy .env.example .env`
   - macOS/Linux: `cp .env.example .env`
3) `VITE_REOWN_PROJECT_ID` in `.env` setzen
4) Dependencies installieren: `npm install`
5) Dev-Server starten: `npm run dev`
6) Browser: `http://localhost:5173`

## Option B: Build + Preview (nahe an Production)
Hinweis: Wenn `VITE_FUJI_RPC_URL` in `.env` relativ ist (z.B. `/fuji`),
funktioniert das nur im Dev-Server (Proxy). Fuer Preview/Build bitte die
absolute URL eintragen.

1) `npm run build`
2) `npm run preview`
3) Browser: `http://localhost:4173`

## Option C: Docker (kein Node auf dem Host)
Voraussetzung: Docker Desktop (Windows/macOS) oder Docker Engine (Linux).

1) `cd frontend-vue`
2) `.env` wie oben anlegen und `VITE_REOWN_PROJECT_ID` setzen
3) `docker compose up`
4) Browser: `http://localhost:5173`

## Env Variablen
Siehe `.env.example`.

Monitoring-relevant:
- `VITE_MONITORING_INGEST_URL`: optionales Ingest-Endpoint fuer Runtime-Telemetrie.
- `VITE_MONITORING_ENV`: Label fuer die Umgebung (`development`, `staging`, `production`).
- `VITE_MONITORING_LOG_TO_CONSOLE`: nur lokal (`true/false`), schreibt Telemetrie als JSON in die Browser-Konsole.
