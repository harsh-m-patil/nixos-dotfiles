import QtQuick
import Quickshell.Io

// Cached, rate-limited JSON GETs.
//
// Every request goes through one queue spaced `interval` apart (OpenF1's free
// tier allows ~3 req/s and 30 req/min). Responses are kept on disk with a
// per-request TTL; on failure the stale copy is served and the request retried
// with exponential backoff. Callbacks for the same URL are coalesced.
Item {
    id: root

    required property string cachePath
    property int interval: 450
    property int maxAge: 60 * 24 * 3600 * 1000

    property var cache: null
    property var queue: []
    property bool dirty: false

    function fetch(url, ttl, cb) {
        load()
        const hit = cache[url]
        if (hit && Date.now() - hit.t < ttl) {
            cb(hit.data)
            return
        }
        const queued = queue.find(q => q.url === url)
        if (queued) {
            queued.cbs.push(cb)
            return
        }
        queue.push({ url, cbs: [cb], tries: 0, notBefore: 0 })
        pump.start()
    }

    function load() {
        if (cache !== null)
            return
        try { cache = JSON.parse(cacheFile.text()) || {} } catch (e) { cache = {} }
        const cutoff = Date.now() - maxAge
        for (const url in cache)
            if (cache[url].t < cutoff) delete cache[url]
    }

    function persist() {
        dirty = true
        saveTimer.restart()
    }

    function deliver(cbs, data) {
        for (const cb of cbs) {
            try { cb(data) } catch (e) { console.warn("CachedFetch:", e) }
        }
    }

    FileView {
        id: cacheFile
        path: root.cachePath
        blockLoading: true
        printErrors: false
    }

    Timer {
        id: saveTimer
        interval: 3000
        onTriggered: {
            if (!root.dirty) return
            root.dirty = false
            cacheFile.setText(JSON.stringify(root.cache))
        }
    }

    Timer {
        id: pump
        interval: root.interval
        repeat: true
        onTriggered: {
            const nowMs = Date.now()
            const i = root.queue.findIndex(q => q.notBefore <= nowMs)
            if (i < 0) {
                if (root.queue.length === 0) stop()
                return
            }
            const job = root.queue.splice(i, 1)[0]
            const xhr = new XMLHttpRequest()
            xhr.onreadystatechange = () => {
                if (xhr.readyState !== XMLHttpRequest.DONE) return
                let data = null
                if (xhr.status === 200) {
                    try { data = JSON.parse(xhr.responseText) } catch (e) {}
                }
                if (data !== null && !(Array.isArray(data) && data.length === 0 && root.cache[job.url])) {
                    root.cache[job.url] = { t: Date.now(), data }
                    root.persist()
                    root.deliver(job.cbs, data)
                    return
                }
                const stale = root.cache[job.url]
                if (stale && job.tries === 0) root.deliver(job.cbs, stale.data)
                if (job.tries < 5) {
                    job.tries++
                    job.notBefore = Date.now() + Math.pow(2, job.tries) * 5000
                    if (stale) job.cbs = []
                    if (job.cbs.length || !stale) {
                        root.queue.push(job)
                        pump.start()
                    }
                }
            }
            xhr.open("GET", job.url)
            xhr.send()
        }
    }
}
