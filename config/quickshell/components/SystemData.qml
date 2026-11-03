pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import "."

Singleton {
    id: root

    property bool windowOpen: false
    property var samplers: []
    readonly property int users: samplers.filter(x => x.active).length
    readonly property bool detailed: samplers.some(x => x.active && x.detailed)
    function subscribe(x) { samplers = samplers.concat([x]) }
    function unsubscribe(x) { samplers = samplers.filter(y => y !== x) }
    property int tab: 0
    property bool showPrivate: false
    onWindowOpenChanged: if (!windowOpen) showPrivate = false

    property var s: ({})
    property real cpu: 0
    property var cores: []
    property var cpuHistory: []
    property var gpuHistory: []
    property var memHistory: []
    property var diskReadHistory: []
    property var diskWriteHistory: []
    property var netRxHistory: []
    property var netTxHistory: []
    property real diskRead: 0
    property real diskWrite: 0
    property real netRx: 0
    property real netTx: 0

    property var lastCpu: null
    property var lastCores: []
    property var lastCounters: null
    property real lastT: 0
    property var lastProcs: ({})
    property var procList: []
    property int beat: 0

    readonly property int historySize: 90
    readonly property bool sampling: detailed || users > 0

    readonly property real memTotal: num(s.MemTotal) * 1024
    readonly property real memUsed: memTotal - num(s.MemAvailable) * 1024
    readonly property real memCache: (num(s.Cached) + num(s.Buffers)) * 1024
    readonly property real memFraction: memTotal > 0 ? memUsed / memTotal : 0
    readonly property real swapTotal: num(s.SwapTotal) * 1024
    readonly property real swapUsed: swapTotal - num(s.SwapFree) * 1024
    readonly property var disk: pair(s.disk)
    readonly property var vram: pair(s.vram)
    readonly property var batFull: pair(s.batfull)
    readonly property var freq: pair(s.freq)
    readonly property real temp: num(s.temp) / 1000
    readonly property real gpuTemp: num(s.gputemp) / 1000
    readonly property real nvmeTemp: num(s.nvmetemp) / 1000
    readonly property real gpuBusy: num(s.gpubusy) / 100
    readonly property var sensors: list(s.sensors)
    readonly property real batFraction: batFull[0] > 0 ? Math.min(1, num(s.batnow) / batFull[0]) : 0
    readonly property real batHealth: batFull[1] > 0 ? batFull[0] / batFull[1] : 0
    readonly property bool charging: s.batstatus === "Charging"
    readonly property real diskFraction: disk[1] > 0 ? disk[0] / disk[1] : 0
    readonly property var load: (s.load || "0 0 0").split(" ").map(Number)
    readonly property var nio: pair(s.nio)
    readonly property real batHours: {
        const p = num(s.batpower)
        if (p <= 0)
            return 0
        return (charging ? batFull[0] - num(s.batnow) : num(s.batnow)) / p
    }

    // Slow-changing facts, refreshed every few seconds instead of every beat.
    property var info: ({})
    readonly property var monitors: info.monitors ?? []
    readonly property var mounts: list(info.mounts)
    readonly property var failedUnits: (info.failed ?? "").split(" ").filter(x => x !== "")
    readonly property string cpuModel: (info.cpuname ?? "").split(" with ")[0]
    readonly property string gpuModel: {
        const parts = (info.cpuname ?? "").split(" with ")
        return parts.length > 1 ? (parts[0].split(" ")[0] + " " + parts[1]) : (info.gpudriver ?? "")
    }

    function topBy(key, n) {
        return procList.slice().sort((a, b) => b[key] - a[key] || b.mem - a.mem).slice(0, n)
    }
    function kill(pid) {
        killer.command = ["kill", String(pid)]
        killer.running = true
    }

    Process { id: killer }

    function num(v) { return parseFloat(v ?? 0) || 0 }
    function pair(v) { return (v ?? "").split(" ").map(Number) }
    function list(v) { return (v ?? "").split("|").filter(x => x !== "").map(x => x.split(",")) }
    function push(arr, v) {
        const h = arr.slice(-(historySize - 1))
        h.push(v)
        return h
    }

    Process {
        id: reader
        command: ["sh", "-c",
            "hw() { for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = \"$1\" ] && cat $h/$2 2>/dev/null && return; done; }; " +
            "grep '^cpu' /proc/stat | awk '{printf \"%s=%s %s %s %s %s %s %s\\n\", $1,$2,$3,$4,$5,$6,$7,$8}'; " +
            "awk '/^(MemTotal|MemAvailable|SwapTotal|SwapFree|Cached|Buffers):/{gsub(\":\",\"\"); print $1\"=\"$2}' /proc/meminfo; " +
            "echo temp=$(hw k10temp temp1_input); echo nvmetemp=$(hw nvme temp1_input); echo fan=$(hw hp fan1_input); " +
            "echo gputemp=$(hw amdgpu temp1_input); echo gpupower=$(hw amdgpu power1_input); " +
            "g=$(ls -d /sys/class/drm/card*/device | head -1); " +
            "echo gpubusy=$(cat $g/gpu_busy_percent 2>/dev/null); " +
            "echo vram=$(cat $g/mem_info_vram_used 2>/dev/null) $(cat $g/mem_info_vram_total 2>/dev/null); " +
            "b=/sys/class/power_supply/BAT0; " +
            "echo batpower=$(cat $b/power_now 2>/dev/null); echo batnow=$(cat $b/energy_now 2>/dev/null); " +
            "echo batfull=$(cat $b/energy_full 2>/dev/null) $(cat $b/energy_full_design 2>/dev/null); " +
            "echo batcycles=$(cat $b/cycle_count 2>/dev/null); echo batstatus=$(cat $b/status 2>/dev/null); " +
            "echo freq=$(awk '/cpu MHz/{s+=$4; n++; if($4>m)m=$4} END{printf \"%d %d\", s/n, m}' /proc/cpuinfo); " +
            "df -B1 --output=used,size / | tail -1 | awk '{print \"disk=\"$1\" \"$2}'; " +
            "echo load=$(cut -d' ' -f1-3 /proc/loadavg); echo up=$(cut -d. -f1 /proc/uptime); " +
            "echo procs=$(ls -d /proc/[0-9]* | wc -l); " +
            (root.sampling
                ? "cat /proc/[0-9]*/stat 2>/dev/null | sed 's/^/p=/'; " +
                  "for f in /proc/[0-9]*; do a=; IFS= read -r -d '' a 2>/dev/null < $f/cmdline; a=${a%% *}; echo \"c=${f#/proc/} ${a##*/}\"; done 2>/dev/null; " +
                  "echo dio=$(awk '$3 ~ /^nvme[0-9]+n[0-9]+$/{r+=$6; w+=$10} END{print r*512, w*512}' /proc/diskstats); " +
                  "n=$(ip route show default 2>/dev/null | awk '{print $5; exit}'); echo netdev=$n; " +
                  "echo nio=$(cat /sys/class/net/$n/statistics/rx_bytes 2>/dev/null) $(cat /sys/class/net/$n/statistics/tx_bytes 2>/dev/null); " +
                  "echo sensors=$(for h in /sys/class/hwmon/hwmon*; do for t in $h/temp*_input; do [ -f $t ] || continue; " +
                  "l=$(cat ${t%_input}_label 2>/dev/null || basename ${t%_input}); printf '%s,%s,%s|' $(cat $h/name) \"$l\" $(cat $t); done; done); " +
                  "echo profile=$(powerprofilesctl get 2>/dev/null); " +
                  "echo governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)"
                : "")]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.ingest(text)
        }
    }

    function ingest(text) {
        const out = {}
        const stats = []
        const names = {}
        for (const line of text.split("\n")) {
            if (line.startsWith("p=")) {
                stats.push(line.slice(2))
                continue
            }
            if (line.startsWith("c=")) {
                const sp = line.indexOf(" ")
                const exe = line.slice(sp + 1).trim().replace(/^\./, "").replace(/-wrapped$/, "")
                if (exe !== "")
                    names[line.slice(2, sp)] = exe
                continue
            }
            const i = line.indexOf("=")
            if (i > 0)
                out[line.slice(0, i)] = line.slice(i + 1).trim()
        }
        const parse = str => {
            const c = (str ?? "").split(" ").map(Number)
            return c.length >= 7 ? { idle: c[3] + c[4], total: c.reduce((a, b) => a + b, 0) } : null
        }
        const usage = (now, prev) => {
            if (!now || !prev)
                return 0
            const dt = now.total - prev.total
            return dt > 0 ? Math.max(0, Math.min(1, 1 - (now.idle - prev.idle) / dt)) : 0
        }

        const all = parse(out.cpu)
        if (all && lastCpu) {
            cpu = usage(all, lastCpu)
            cpuHistory = push(cpuHistory, cpu)
        }
        if (stats.length > 0)
            sampleProcs(stats, names, all && lastCpu ? all.total - lastCpu.total : 0, num(out.MemTotal) * 1024)
        lastCpu = all

        const now = []
        for (let i = 0; out["cpu" + i] !== undefined; i++)
            now.push(parse(out["cpu" + i]))
        cores = now.map((c, i) => usage(c, lastCores[i]))
        lastCores = now

        gpuHistory = push(gpuHistory, num(out.gpubusy) / 100)

        const t = Date.now()
        const dio = pair(out.dio), nio = pair(out.nio)
        if (lastCounters && out.dio && t > lastT) {
            const dt = (t - lastT) / 1000
            diskRead = Math.max(0, (dio[0] - lastCounters.dio[0]) / dt)
            diskWrite = Math.max(0, (dio[1] - lastCounters.dio[1]) / dt)
            netRx = Math.max(0, (nio[0] - lastCounters.nio[0]) / dt)
            netTx = Math.max(0, (nio[1] - lastCounters.nio[1]) / dt)
            diskReadHistory = push(diskReadHistory, diskRead)
            diskWriteHistory = push(diskWriteHistory, diskWrite)
            netRxHistory = push(netRxHistory, netRx)
            netTxHistory = push(netTxHistory, netTx)
        }
        lastCounters = out.dio ? { dio, nio } : null
        lastT = t

        s = out
        memHistory = push(memHistory, memFraction)
        beat++
    }

    // /proc/<pid>/stat: "pid (comm) state ..." — comm may contain spaces and parens,
    // so fields are counted from the last ")". utime/stime are fields 14/15, rss is 24.
    function sampleProcs(stats, names, dTotal, memBytes) {
        const now = {}
        const rows = []
        for (const l of stats) {
            const open = l.indexOf("("), close = l.lastIndexOf(")")
            if (open < 0 || close < 0)
                continue
            const pid = l.slice(0, open).trim()
            const f = l.slice(close + 2).split(" ")
            const ticks = (parseInt(f[11]) || 0) + (parseInt(f[12]) || 0)
            const rss = (parseInt(f[21]) || 0) * 4096
            now[pid] = ticks
            const prev = lastProcs[pid]
            if (prev === undefined || dTotal <= 0)
                continue
            rows.push({
                name: names[pid] ?? l.slice(open + 1, close),
                pid: pid,
                cpu: Math.max(0, Math.min(1, (ticks - prev) / dTotal)),
                mem: rss,
                memFraction: memBytes > 0 ? rss / memBytes : 0
            })
        }
        lastProcs = now
        if (rows.length > 0)
            procList = rows
    }

    Process {
        id: infoReader
        command: ["sh", "-c",
            "d=/sys/class/dmi/id; " +
            "echo host=$(cat /proc/sys/kernel/hostname); " +
            "echo vendor=$(cat $d/sys_vendor 2>/dev/null); echo product=$(cat $d/product_name 2>/dev/null); " +
            "echo board=$(cat $d/board_name 2>/dev/null); " +
            "echo bios=$(cat $d/bios_version 2>/dev/null); echo biosdate=$(cat $d/bios_date 2>/dev/null); " +
            "echo cpuname=$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo); " +
            "echo cpucores=$(awk -F': ' '/cpu cores/{print $2; exit}' /proc/cpuinfo); " +
            "echo cpumax=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null); " +
            "lscpu 2>/dev/null | awk -F': +' '/^L[23] cache/{sub(/ \\(.*/, \"\", $2); print tolower(substr($1, 1, 2)) \"=\" $2}'; " +
            "g=$(ls -d /sys/class/drm/card*/device | head -1); " +
            "echo gpudriver=$(basename \"$(readlink $g/driver)\" 2>/dev/null); echo gpulink=$(cat $g/current_link_speed 2>/dev/null); " +
            "echo mon=$(hyprctl -j monitors 2>/dev/null | tr -d '\\n'); " +
            "k=$(lsblk -no PKNAME \"$(findmnt -no SOURCE /)\" 2>/dev/null | head -1); " +
            "echo diskmodel=$(cat /sys/block/$k/device/model 2>/dev/null); " +
            "echo disksize=$(( $(cat /sys/block/$k/size 2>/dev/null || echo 0) * 512 )); " +
            "echo mounts=$(df -B1 -x tmpfs -x devtmpfs -x efivarfs -x overlay -x ramfs --output=target,fstype,used,size 2>/dev/null | " +
            "tail -n +2 | awk '{printf \"%s,%s,%s,%s|\", $1, $2, $3, $4}'); " +
            "echo kernel=$(uname -r); echo arch=$(uname -m); " +
            "echo os=$(nixos-version 2>/dev/null); echo rev=$(nixos-version --revision 2>/dev/null); " +
            "echo gen=$(readlink /nix/var/nix/profiles/system | grep -o '[0-9]*'); " +
            "echo gentime=$(stat -c %Y /nix/var/nix/profiles/system 2>/dev/null); " +
            "echo gens=$(ls -d /nix/var/nix/profiles/system-*-link 2>/dev/null | wc -l); " +
            "echo closure=$(nix-store -q --requisites /run/current-system 2>/dev/null | wc -l); " +
            "echo pkgs=$(ls /run/current-system/sw/bin | wc -l); " +
            "echo userpkgs=$(ls /etc/profiles/per-user/$(id -un)/bin 2>/dev/null | wc -l); " +
            "echo nix=$(nix --version 2>/dev/null | awk '{print $NF}'); " +
            "echo hypr=$(hyprctl version 2>/dev/null | head -1 | awk '{print $2}'); " +
            "echo qs=$(qs --version 2>/dev/null | awk '{print $2}'); " +
            "echo shell=$(getent passwd $(id -un) | awk -F: '{n = split($7, a, \"/\"); print a[n]}'); " +
            "echo session=$XDG_SESSION_TYPE; " +
            "echo running=$(systemctl list-units --type=service --state=running --no-legend 2>/dev/null | wc -l); " +
            "echo failed=$({ systemctl --failed --no-legend --plain; systemctl --user --failed --no-legend --plain; } 2>/dev/null | awk '{print $1}' | paste -sd' '); " +
            "n=$(ip route show default 2>/dev/null | awk '{print $5; exit}'); echo netdev=$n; " +
            "echo gateway=$(ip route show default 2>/dev/null | awk '{print $3; exit}'); " +
            "echo ipv4=$(ip -4 -o addr show dev \"$n\" 2>/dev/null | awk '{print $4; exit}'); " +
            "echo mac=$(cat /sys/class/net/$n/address 2>/dev/null); " +
            "echo conn=$(nmcli -t -g GENERAL.CONNECTION dev show \"$n\" 2>/dev/null); " +
            "echo wifi=$([ -n \"$n\" ] && [ -d /sys/class/net/$n/wireless ] && echo 1); " +
            "echo signal=$(awk -v n=\"$n:\" '$1 == n {print int($3)}' /proc/net/wireless 2>/dev/null); " +
            "b=/sys/class/power_supply/BAT0; " +
            "echo batvendor=$(cat $b/manufacturer 2>/dev/null); echo batmodel=$(cat $b/model_name 2>/dev/null); " +
            "echo battech=$(cat $b/technology 2>/dev/null)"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const out = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0)
                        out[line.slice(0, i)] = line.slice(i + 1).trim()
                }
                try {
                    out.monitors = JSON.parse(out.mon || "[]").filter(m => !m.disabled)
                } catch (e) {
                    out.monitors = []
                }
                root.info = out
            }
        }
    }

    Timer {
        interval: 15000
        repeat: true
        triggeredOnStart: true
        running: root.sampling
        onTriggered: if (!infoReader.running) infoReader.running = true
    }

    Timer {
        interval: root.sampling ? 1000 : 1500
        repeat: true
        triggeredOnStart: true
        running: root.users > 0
        onTriggered: if (!reader.running) reader.running = true
    }
}
