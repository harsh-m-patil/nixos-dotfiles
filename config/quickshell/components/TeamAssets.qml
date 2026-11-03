pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

import "."

// Every F1 team logo the shell shows. Large logos for F1 themes are downloaded
// once into logoDir; small ones for arbitrary team names come straight from
// the F1 media CDN.
Singleton {
    id: root

    readonly property string logoDir: Quickshell.env("HOME") + "/.cache/quickshell/team-logos"
    property bool ready: false

    function themeSlug(theme) {
        return String(theme?.f1?.constructor ?? "").toLowerCase().replace(/[^a-z]/g, "")
    }

    function themeLogo(theme) {
        const slug = themeSlug(theme)
        return slug && ready ? "file://" + logoDir + "/" + slug + ".png" : ""
    }

    function logo(team, season) {
        const key = String(team ?? "").toLowerCase().replace(/[^a-z]/g, "").replace(/fteam$/, "")
        const alias = { redbull: "redbullracing", rb: "racingbulls", visacashapprb: "racingbulls", kicksauber: "audi", sauber: "audi" }
        const slug = alias[key] ?? key
        if (!slug) return ""
        const year = season ?? new Date().getFullYear()
        return "https://media.formula1.com/image/upload/c_fit,h_64/f_png/q_auto/v1740000000/common/f1/"
            + year + "/" + slug + "/" + year + slug + "logowhite.webp"
    }

    readonly property var slugs: Theme.f1Themes().map(t => themeSlug(t)).filter(s => s)
    onSlugsChanged: if (slugs.length > 0 && !ready && !download.running) download.running = true

    Process {
        id: download
        command: ["sh", "-c",
            "mkdir -p \"$0\"; for slug in \"$@\"; do f=\"$0/$slug.png\"; [ -s \"$f\" ] && continue; " +
            "curl -sfL --max-time 20 -o \"$f.tmp\" \"https://media.formula1.com/image/upload/c_fit,h_240/f_png/q_auto/v1740000000/common/f1/2026/$slug/2026${slug}logowhite.webp\" && mv \"$f.tmp\" \"$f\" & done; wait",
            root.logoDir].concat(root.slugs)
        onExited: root.ready = true
    }
}
