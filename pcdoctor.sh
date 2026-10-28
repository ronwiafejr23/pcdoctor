#!/usr/bin/env bash
# pcdoctor - a plain-English health checkup for Linux computers.
# Checks disk, memory, CPU, battery, failed services, updates, security and
# junk files, then explains each problem and the command that fixes it.
#
# Usage:  ./pcdoctor.sh            run the checkup
#         ./pcdoctor.sh --fix      run the checkup, then offer to fix problems (asks y/n for each)
#         ./pcdoctor.sh --report   also save the results to a text file
#         (you can combine them:  ./pcdoctor.sh --fix --report)

# ---------- options ----------
FIX_MODE=0
REPORT_MODE=0
for arg in "$@"; do
  case "$arg" in
    --fix)    FIX_MODE=1 ;;
    --report) REPORT_MODE=1 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg  (try --help)"; exit 1 ;;
  esac
done

# ---------- colors (turned off when output isn't a terminal) ----------
if [ -t 1 ] && [ "$REPORT_MODE" -eq 0 ]; then
  RED=$'\e[31m'; YEL=$'\e[33m'; GRN=$'\e[32m'; BLU=$'\e[36m'; BLD=$'\e[1m'; RST=$'\e[0m'
else
  RED=""; YEL=""; GRN=""; BLU=""; BLD=""; RST=""
fi

SCORE=100
PROBLEMS=0
WARNINGS=0
FIX_DESCS=()   # what each fix does, in plain English
FIX_CMDS=()    # the command that does it

ok()   { echo "  ${GRN}[OK]${RST}   $1"; }
warn() { echo "  ${YEL}[WARN]${RST} $1"; WARNINGS=$((WARNINGS+1)); SCORE=$((SCORE-5)); }
bad()  { echo "  ${RED}[FIX]${RST}  $1"; PROBLEMS=$((PROBLEMS+1)); SCORE=$((SCORE-15)); }
tip()  { echo "         ${BLU}-> $1${RST}"; }
section() { echo; echo "${BLD}== $1 ==${RST}"; }
has()  { command -v "$1" >/dev/null 2>&1; }

# Remember a fix so --fix mode can offer it at the end
add_fix() { FIX_DESCS+=("$1"); FIX_CMDS+=("$2"); }

# Turn a number of KB into something readable like 1.4G
human_kb() { awk -v k="$1" 'BEGIN{ split("K M G T",u," "); i=1; while(k>=1024 && i<4){k/=1024;i++} printf "%.1f%s", k, u[i] }'; }

# ---------- 1. Disk space ----------
check_disk() {
  section "Disk space"
  while read -r used mount; do
    pct=${used%\%}
    if   [ "$pct" -ge 90 ]; then
      bad "$mount is ${pct}% full. Programs can crash or refuse to save when a disk fills up."
      tip "See what's taking space:  sudo du -xh $mount --max-depth=1 2>/dev/null | sort -h | tail"
    elif [ "$pct" -ge 80 ]; then
      warn "$mount is ${pct}% full. Fine for now, but start cleaning up."
      tip "See what's taking space:  du -h ~ --max-depth=1 2>/dev/null | sort -h | tail"
    else
      ok "$mount is ${pct}% full."
    fi
  done < <(df -P -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | awk 'NR>1 {print $5, $6}')
}

# ---------- 2. Memory ----------
check_memory() {
  section "Memory (RAM)"
  total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  used_pct=$(( (total - avail) * 100 / total ))
  if   [ "$used_pct" -ge 90 ]; then
    bad "RAM is ${used_pct}% used ($(human_kb "$avail") free of $(human_kb "$total")). This is why things feel slow."
  elif [ "$used_pct" -ge 75 ]; then
    warn "RAM is ${used_pct}% used ($(human_kb "$avail") free of $(human_kb "$total"))."
  else
    ok "RAM is ${used_pct}% used ($(human_kb "$avail") free of $(human_kb "$total"))."
  fi
  echo "         Biggest memory users:"
  ps -eo comm,%mem --sort=-%mem | awk 'NR>1 && NR<=4 {printf "           %-20s %s%%\n", $1, $2}'
  [ "$used_pct" -ge 75 ] && tip "Close the top programs above, or too many browser tabs."
}

# ---------- 3. CPU ----------
check_cpu() {
  section "Processor (CPU)"
  cores=$(nproc)
  load=$(awk '{print $2}' /proc/loadavg)        # 5-minute average
  load_pct=$(awk -v l="$load" -v c="$cores" 'BEGIN{printf "%d", l/c*100}')
  if   [ "$load_pct" -ge 100 ]; then
    bad "CPU is overloaded (load $load on $cores cores). Something is working it very hard."
  elif [ "$load_pct" -ge 70 ]; then
    warn "CPU is busy (load $load on $cores cores)."
  else
    ok "CPU is relaxed (load $load on $cores cores)."
  fi
  echo "         Biggest CPU users:"
  ps -eo comm,%cpu --sort=-%cpu | awk 'NR>1 && NR<=4 {printf "           %-20s %s%%\n", $1, $2}'
  [ "$load_pct" -ge 70 ] && tip "If one program is stuck, stop it:  pkill <name>"
}

# ---------- 4. Battery ----------
# Linux keeps battery info in /sys/class/power_supply/BAT0 (or BAT1...).
# Health = how much the battery holds now compared to when it was new.
check_battery() {
  section "Battery"
  power_dir="${PCDOCTOR_POWER_DIR:-/sys/class/power_supply}"
  found=0
  for bat in "$power_dir"/BAT*; do
    [ -d "$bat" ] || continue
    found=1
    name=$(basename "$bat")

    # Some laptops report energy (Wh), others charge (Ah). Same math either way.
    if   [ -r "$bat/energy_full" ] && [ -r "$bat/energy_full_design" ]; then
      now_full=$(cat "$bat/energy_full"); design=$(cat "$bat/energy_full_design")
    elif [ -r "$bat/charge_full" ] && [ -r "$bat/charge_full_design" ]; then
      now_full=$(cat "$bat/charge_full"); design=$(cat "$bat/charge_full_design")
    else
      ok "$name found, but it doesn't report its health."
      continue
    fi
    [ "$design" -gt 0 ] 2>/dev/null || { ok "$name doesn't report its health."; continue; }

    health=$(( now_full * 100 / design ))
    [ "$health" -gt 100 ] && health=100
    charge=$(cat "$bat/capacity" 2>/dev/null || echo "?")
    status=$(cat "$bat/status" 2>/dev/null || echo "Unknown")
    cycles=$(cat "$bat/cycle_count" 2>/dev/null)
    extra="charged ${charge}%, ${status,,}"
    [ -n "$cycles" ] && [ "$cycles" != "0" ] && extra="$extra, $cycles charge cycles"

    if   [ "$health" -lt 60 ]; then
      bad "$name health is ${health}% ($extra). It holds about half its original charge."
      tip "Time to replace it. Search: '<your laptop model> replacement battery'."
    elif [ "$health" -lt 80 ]; then
      warn "$name health is ${health}% ($extra). It's wearing out, so expect shorter battery life."
      tip "Help it last: avoid keeping it at 100% plugged in all day, and keep it cool."
    else
      ok "$name health is ${health}% ($extra)."
    fi
  done
  [ "$found" -eq 0 ] && ok "No battery found (desktop, virtual machine, or WSL)."
}

# ---------- 5. Failed services ----------
check_services() {
  section "Background services"
  if ! has systemctl || ! systemctl list-units >/dev/null 2>&1; then
    ok "Skipped (this system doesn't use systemd, e.g. WSL or a container)."
    return
  fi
  failed=$(systemctl --failed --no-legend --plain 2>/dev/null | awk '{print $1}')
  if [ -n "$failed" ]; then
    for svc in $failed; do
      bad "Service '$svc' crashed or failed to start."
      tip "Find out why:  journalctl -u $svc -n 20 --no-pager"
      add_fix "Try restarting the '$svc' service" "sudo systemctl restart $svc"
    done
  else
    ok "No services have failed."
  fi
}

# ---------- 6. Updates & reboots ----------
check_updates() {
  section "Updates"
  if has apt; then
    count=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
    if   [ "$count" -ge 50 ]; then
      bad "$count updates are waiting. Updates fix security holes, so don't put these off."
      tip "Install them:  sudo apt update && sudo apt upgrade"
    elif [ "$count" -gt 0 ]; then
      warn "$count updates are waiting."
      tip "Install them:  sudo apt update && sudo apt upgrade"
    else
      ok "Everything is up to date (as of the last 'apt update')."
    fi
    [ "$count" -gt 0 ] && add_fix "Install $count waiting updates" "sudo apt update && sudo apt upgrade -y"
  elif has dnf; then
    count=$(dnf -q check-update 2>/dev/null | grep -c '^[a-zA-Z0-9]')
    if [ "$count" -gt 0 ]; then
      warn "$count updates are waiting."
      tip "Install them:  sudo dnf upgrade"
      add_fix "Install $count waiting updates" "sudo dnf upgrade -y"
    else
      ok "Everything is up to date."
    fi
  else
    ok "Skipped (unknown package manager)."
  fi

  if [ -f /var/run/reboot-required ]; then
    warn "An update needs a restart to finish installing."
    tip "Restart when convenient:  sudo reboot"
  fi
  days=$(awk '{printf "%d", $1/86400}' /proc/uptime)
  if [ "$days" -ge 30 ]; then
    warn "Computer has been on for $days days without a restart."
    tip "A restart clears memory leaks and applies kernel updates."
  else
    ok "Last restart was $days day(s) ago."
  fi
}

# ---------- 7. Security basics ----------
check_security() {
  section "Security"
  if has ufw; then
    if sudo -n ufw status 2>/dev/null | grep -q "Status: active"; then
      ok "Firewall (ufw) is on."
    elif sudo -n true 2>/dev/null; then
      bad "Firewall (ufw) is off. Anything listening on the network is reachable."
      tip "Turn it on:  sudo ufw enable"
      # Allow SSH first so nobody connected remotely gets locked out
      add_fix "Turn on the firewall (keeps SSH allowed)" "sudo ufw allow ssh && sudo ufw --force enable"
    else
      ok "Firewall check skipped (run with sudo to include it)."
    fi
  fi

  if [ -f /etc/ssh/sshd_config ] && grep -qiE '^\s*PermitRootLogin\s+yes' /etc/ssh/sshd_config; then
    bad "SSH allows logging in directly as root. Attackers try this constantly."
    tip "Set 'PermitRootLogin no' in /etc/ssh/sshd_config, then: sudo systemctl restart ssh"
  fi

  if has ss; then
    open=$(ss -tulnH 2>/dev/null | awk '$5 !~ /^(127\.|\[::1\]|::1)/ {n=split($5,a,":"); print a[n]}' | sort -un | tr '\n' ' ')
    if [ -n "$open" ]; then
      warn "Programs are listening for outside connections on ports: $open"
      tip "See which programs:  sudo ss -tulnp   (close anything you don't recognize)"
    else
      ok "Nothing is listening for outside connections."
    fi
  else
    ok "Port check skipped (install it with: sudo apt install iproute2)."
  fi
}

# ---------- 8. Junk you can safely delete ----------
check_junk() {
  section "Junk files"
  total_kb=0
  report_junk() {  # $1 = label, $2 = path, $3 = cleanup command
    [ -e "$2" ] || return
    kb=$(du -sk "$2" 2>/dev/null | awk '{print $1}')
    [ -z "$kb" ] && return
    total_kb=$((total_kb + kb))
    if [ "$kb" -ge 512000 ]; then         # 500 MB
      warn "$1 is using $(human_kb "$kb")."
      tip "Clear it:  $3"
      add_fix "Clear $1 (frees $(human_kb "$kb"))" "$3"
    fi
  }
  report_junk "Trash"                 "$HOME/.local/share/Trash" "rm -rf ~/.local/share/Trash/files/* ~/.local/share/Trash/info/*"
  report_junk "Thumbnail cache"       "$HOME/.cache/thumbnails" "rm -rf ~/.cache/thumbnails/*"
  report_junk "Downloaded installers" "/var/cache/apt/archives" "sudo apt clean"
  report_junk "System logs"           "/var/log/journal"       "sudo journalctl --vacuum-size=200M"
  ok "Total junk found: $(human_kb "$total_kb")."
}

# ---------- --fix mode: offer each fix, one at a time ----------
run_fixes() {
  echo
  echo "${BLD}== Fix mode ==${RST}"
  if [ "${#FIX_CMDS[@]}" -eq 0 ]; then
    echo "  Nothing pcdoctor can fix automatically. Any [FIX]/[WARN] items above need a person to decide."
    return
  fi
  echo "  pcdoctor can fix ${#FIX_CMDS[@]} thing(s). It will ask before each one."
  echo "  (Some need your password because they change system settings.)"
  fixed=0
  for i in "${!FIX_CMDS[@]}"; do
    echo
    echo "  ${BLD}$((i+1)). ${FIX_DESCS[$i]}${RST}"
    echo "     Command: ${FIX_CMDS[$i]}"
    read -r -p "     Do it? [y/N] " answer
    case "$answer" in
      [yY]|[yY][eE][sS])
        if bash -c "${FIX_CMDS[$i]}"; then
          echo "     ${GRN}Done.${RST}"; fixed=$((fixed+1))
        else
          echo "     ${RED}That didn't work.${RST} Try running the command yourself to see the error."
        fi ;;
      *) echo "     Skipped." ;;
    esac
  done
  echo
  echo "  Fixed $fixed of ${#FIX_CMDS[@]}. Run ./pcdoctor.sh again to see your new score."
}

# ---------- run it ----------
main() {
  echo "${BLD}pcdoctor${RST} - checkup for $(hostname) ($(. /etc/os-release 2>/dev/null; echo "${PRETTY_NAME:-Linux}"))"
  echo "Run on $(date '+%a %b %d %Y, %I:%M %p')"

  check_disk
  check_memory
  check_cpu
  check_battery
  check_services
  check_updates
  check_security
  check_junk

  [ "$SCORE" -lt 0 ] && SCORE=0
  if   [ "$SCORE" -ge 85 ]; then grade="${GRN}Healthy${RST}"
  elif [ "$SCORE" -ge 60 ]; then grade="${YEL}Needs some attention${RST}"
  else                           grade="${RED}Needs fixing${RST}"; fi

  echo
  echo "${BLD}== Result ==${RST}"
  echo "  Health score: ${BLD}$SCORE/100${RST} - $grade"
  echo "  $PROBLEMS problem(s) to fix, $WARNINGS warning(s)."
  if [ "$PROBLEMS" -gt 0 ] || [ "$WARNINGS" -gt 0 ]; then
    if [ "$FIX_MODE" -eq 1 ]; then
      run_fixes
    elif [ "${#FIX_CMDS[@]}" -gt 0 ]; then
      echo "  Tip: run ${BLD}./pcdoctor.sh --fix${RST} and pcdoctor will fix ${#FIX_CMDS[@]} of these for you."
    fi
  fi
}

if [ "$REPORT_MODE" -eq 1 ]; then
  out="pcdoctor-report-$(date +%Y%m%d-%H%M).txt"
  main 2>&1 | tee "$out"
  echo; echo "Saved to $out"
else
  main
fi
