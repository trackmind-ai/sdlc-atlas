#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Trackmind
# SPDX-License-Identifier: MIT
# Full automated QA pipeline: detect stack, build, start servers, run live browser tests
# Part of the sdlc-atlas platform. Called by orchestrator Phase 5 Gate 4.
# Usage: bash scripts/run-full-qa.sh [--mode diff-aware|full|quick] [--target-url http://localhost:3000]

set -eu

PROJECT_ROOT="$(pwd)"
MODE="${1:-diff-aware}"
TARGET_URL="${2:-http://localhost:3000}"

# Detect backend and frontend stacks from CLAUDE.md
BACKEND_STACK=$(grep -E "^\s+backend:" "$PROJECT_ROOT/.claude/CLAUDE.md" 2>/dev/null | sed 's/.*backend:[[:space:]]*//;s/[[:space:]]*#.*//' || echo "")
FRONTEND_STACK=$(grep -E "^\s+frontend:" "$PROJECT_ROOT/.claude/CLAUDE.md" 2>/dev/null | sed 's/.*frontend:[[:space:]]*//;s/[[:space:]]*#.*//' || echo "")

BACKEND_PORT=8000
FRONTEND_PORT=3000
CHROME_PORT=9222

# Cleanup on exit
cleanup() {
  echo "[QA] Cleaning up servers..."
  [ ! -z "${BACKEND_PID:-}" ] && kill $BACKEND_PID 2>/dev/null || true
  [ ! -z "${FRONTEND_PID:-}" ] && kill $FRONTEND_PID 2>/dev/null || true
  [ ! -z "${CHROME_PID:-}" ] && kill $CHROME_PID 2>/dev/null || true
}
trap cleanup EXIT

echo "=========================================="
echo "sdlc-atlas — Full Automated QA"
echo "=========================================="
echo "Backend stack: ${BACKEND_STACK:-none}"
echo "Frontend stack: ${FRONTEND_STACK:-none}"
echo "Frontend target: $TARGET_URL"
echo "QA mode: $MODE"
echo ""

# ============================================================================
# STEP 1: Start Backend
# ============================================================================
case "$BACKEND_STACK" in
  fastapi|python)
    echo "[1/4] Starting FastAPI backend on :$BACKEND_PORT..."
    if [ ! -d "$PROJECT_ROOT/backend" ]; then
      echo "  ⚠ Backend folder not found, skipping"
    else
      cd "$PROJECT_ROOT/backend"
      if [ ! -d "venv" ]; then
        echo "  Creating Python venv..."
        python3 -m venv venv > /dev/null 2>&1 || python -m venv venv > /dev/null 2>&1
      fi
      if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
      elif [ -f "venv/Scripts/activate" ]; then
        source venv/Scripts/activate
      fi
      if [ -f "requirements.txt" ]; then
        echo "  Installing backend dependencies..."
        pip install -q -r requirements.txt 2>/dev/null || true
      fi
      echo "  Launching uvicorn on port $BACKEND_PORT..."
      python -m uvicorn main:app --host 127.0.0.1 --port $BACKEND_PORT --reload > /tmp/backend.log 2>&1 &
      BACKEND_PID=$!
      sleep 3
      if curl -s --max-time 3 "http://127.0.0.1:$BACKEND_PORT/docs" > /dev/null 2>&1; then
        echo "  ✔ FastAPI running on http://127.0.0.1:$BACKEND_PORT (PID: $BACKEND_PID)"
      else
        echo "  ⚠ FastAPI startup check failed (see /tmp/backend.log)"
      fi
    fi
    ;;
  node|express|typescript)
    echo "[1/4] Starting Node.js backend on :$BACKEND_PORT..."
    if [ ! -d "$PROJECT_ROOT/backend" ]; then
      echo "  ⚠ Backend folder not found, skipping"
    else
      cd "$PROJECT_ROOT/backend"
      if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        echo "  Installing backend dependencies..."
        npm install -q 2>/dev/null || npm install || true
      fi
      echo "  Launching Node backend..."
      npm start > /tmp/backend.log 2>&1 &
      BACKEND_PID=$!
      sleep 3
      if curl -s --max-time 3 "http://127.0.0.1:$BACKEND_PORT/health" > /dev/null 2>&1 || \
         curl -s --max-time 3 "http://127.0.0.1:$BACKEND_PORT" > /dev/null 2>&1; then
        echo "  ✔ Node backend running (PID: $BACKEND_PID)"
      else
        echo "  ⚠ Node backend startup check failed (see /tmp/backend.log)"
      fi
    fi
    ;;
  *)
    echo "[1/4] Backend: no recognized stack declared (or 'none') — skipping"
    ;;
esac

# ============================================================================
# STEP 2: Start Frontend
# ============================================================================
case "$FRONTEND_STACK" in
  nextjs|react|typescript|angular)
    echo ""
    echo "[2/4] Starting $FRONTEND_STACK frontend on :$FRONTEND_PORT..."
    if [ ! -d "$PROJECT_ROOT/frontend" ]; then
      echo "  ⚠ Frontend folder not found, skipping"
    else
      cd "$PROJECT_ROOT/frontend"
      if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        echo "  Installing frontend dependencies..."
        npm install -q 2>/dev/null || npm install || true
      fi
      echo "  Launching dev server..."
      npm run dev > /tmp/frontend.log 2>&1 &
      FRONTEND_PID=$!
      sleep 6  # Next.js/React takes longer to compile
      if curl -s --max-time 3 "$TARGET_URL" > /dev/null 2>&1; then
        echo "  ✔ Frontend running on $TARGET_URL (PID: $FRONTEND_PID)"
      else
        echo "  ⚠ Frontend startup check failed (see /tmp/frontend.log)"
      fi
    fi
    ;;
  *)
    echo ""
    echo "[2/4] Frontend: no recognized stack declared (or 'none') — skipping"
    ;;
esac

# ============================================================================
# STEP 3: Launch Chrome with CDP
# ============================================================================
echo ""
echo "[3/4] Launching Chrome with Chrome DevTools Protocol (port $CHROME_PORT)..."

if curl -s http://localhost:$CHROME_PORT/json > /dev/null 2>&1; then
  echo "  ✔ Chrome already running on port $CHROME_PORT, reusing session"
else
  CHROME_BIN=""
  if command -v google-chrome > /dev/null 2>&1; then
    CHROME_BIN="google-chrome"
  elif command -v chrome > /dev/null 2>&1; then
    CHROME_BIN="chrome"
  elif command -v chromium > /dev/null 2>&1; then
    CHROME_BIN="chromium"
  elif [ -f "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    CHROME_BIN="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  elif [ -f "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe" ]; then
    CHROME_BIN="C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe"
  elif [ -f "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe" ]; then
    CHROME_BIN="C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe"
  else
    echo "  ⚠ Chrome not found. Install Chrome or ensure it's on PATH."
    echo "  Servers are running but QA cannot proceed without a browser."
    exit 1
  fi

  echo "  Launching: $CHROME_BIN"
  "$CHROME_BIN" --remote-debugging-port=$CHROME_PORT > /dev/null 2>&1 &
  CHROME_PID=$!
  sleep 3

  if curl -s --max-time 3 http://localhost:$CHROME_PORT/json > /dev/null 2>&1; then
    echo "  ✔ Chrome launched on port $CHROME_PORT (PID: $CHROME_PID) — HEADED MODE (visible window)"
  else
    echo "  ⚠ Chrome failed to launch on port $CHROME_PORT"
    exit 1
  fi
fi

# ============================================================================
# STEP 4: Ready for QA Agent
# ============================================================================
echo ""
echo "[4/4] All servers running. Ready for QA automation..."
echo ""
echo "=========================================="
echo "✔ Setup complete:"
echo "  Backend: http://127.0.0.1:$BACKEND_PORT"
echo "  Frontend: http://127.0.0.1:$FRONTEND_PORT"
echo "  Chrome CDP: http://127.0.0.1:$CHROME_PORT"
echo ""
echo "When invoked by orchestrator, qa-agent will now:"
echo "  • Navigate to $TARGET_URL"
echo "  • Inspect page health (console, links, visual, functional)"
echo "  • Test user flows autonomously"
echo "  • Generate health score and findings"
echo ""
echo "Press Ctrl+C to stop all servers."
echo "=========================================="
echo ""

# Keep script running so servers stay alive until orchestrator finishes
wait
