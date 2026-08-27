@echo off
rem fullstack-agent: give your AI a full stack — memory, voice, face, hands.
rem Copyright (C) 2026 Jared Rhodenizer
rem
rem This program is free software: you can redistribute it and/or modify
rem it under the terms of the GNU Affero General Public License as published
rem by the Free Software Foundation, either version 3 of the License, or
rem (at your option) any later version.
rem
rem This program is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
rem GNU Affero General Public License for more details.
rem
rem You should have received a copy of the GNU Affero General Public License
rem along with this program. If not, see <https://www.gnu.org/licenses/>.
rem
rem SPDX-License-Identifier: AGPL-3.0-or-later

rem Starts the agent's pieces. Each server gets its own window;
rem close the windows (or this one for the voice) to stop.
rem   start.bat          everything installed
rem   start.bat voice    the voice and the face (no hands)
rem   start.bat hands    the voice and the hands board (no face)

cd /d "%~dp0.."

if exist "ai-visualizer\" if not "%1"=="hands" (
  netstat -ano | findstr /R /C:"127.0.0.1:8790.*LISTENING" >nul
  if errorlevel 1 (
    echo   face:  starting
    start "agent face" /D "ai-visualizer" run.bat
  ) else (
    rem A listening port alone doesn't prove a visible window is up --
    rem the browser can die or get closed by hand while the server lives on,
    rem which used to leave the face silently unopened every launch after.
    powershell -NoProfile -Command "if (Get-CimInstance Win32_Process | Where-Object { $_.Name -match 'msedge|chrome' -and $_.CommandLine -like '*.browser-profile*' }) { exit 0 } else { exit 1 }" >nul 2>nul
    if errorlevel 1 (
      echo   face:  server running with no window attached, restarting
      powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match 'server\.py' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"
      start "agent face" /D "ai-visualizer" run.bat
    ) else (
      echo   face:  already running, leaving it alone
    )
  )
)

if exist "barehands\" if not "%1"=="voice" (
  echo   hands: starting
  rem if errorlevel reads the where result at run time. A percent-style
  rem check here would expand when this block is parsed and test a stale value.
  where py >nul 2>nul
  if errorlevel 1 (
    start "agent hands" cmd /c "cd barehands && python server.py"
  ) else (
    start "agent hands" cmd /c "cd barehands && py server.py"
  )
)

if exist "backtalk\" (
  echo   voice: starting in this window. Close it to hang up.
  cd backtalk
  rem Self-repair: reconcile the voice line's packages before launch
  rem (fast when current; heals a half-installed environment).
  uv sync -q --inexact >nul 2>nul
  uv run python -m backtalk.main
  rem A clean goodbye exits 0 and the window may close. An error exits
  rem nonzero, and the window HOLDS so the message can be read.
  if errorlevel 1 (
    echo.
    echo   The voice line stopped with an error. The message is above.
    echo   The log lives in backtalk\logs\backtalk.log
    pause
  )
)
