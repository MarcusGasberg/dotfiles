pragma Singleton
import Quickshell

// Subsequence fuzzy matcher with positional scoring.
//
// Written rather than vendored: fzf-for-js is ~35KB of vendored code for one
// call site, and the scoring an app launcher needs is narrow - reward matches
// at word starts and consecutive runs, prefer shorter candidates, and never
// match out of order. `chr` typed against `firefox` must rank Chromium above
// Character Map.
Singleton {
    id: root

    // -1 = no match. Higher is better.
    function score(needle: string, hay: string): int {
        if (needle === "") return 1;
        const n = needle.toLowerCase();
        const h = hay.toLowerCase();
        if (n.length > h.length) return -1;

        // exact and prefix are special-cased so they always win outright
        if (h === n) return 10000;
        if (h.startsWith(n)) return 5000 - h.length;

        let s = 0, hi = 0, run = 0;
        for (let i = 0; i < n.length; i++) {
            const c = n[i];
            let found = -1;
            for (let j = hi; j < h.length; j++) {
                if (h[j] === c) { found = j; break; }
            }
            if (found === -1) return -1;

            // word-start bonus: start of string, or after a separator
            const atStart = found === 0 ||
                " -_./:".indexOf(h[found - 1]) !== -1;
            s += atStart ? 15 : 1;
            // consecutive-run bonus, growing so runs beat scattered hits
            run = (found === hi && i > 0) ? run + 1 : 0;
            s += run * 5;
            hi = found + 1;
        }
        // prefer shorter haystacks, and earlier first-hit
        return s * 100 - h.length;
    }

    // Rank a list of {name, ...} objects by the best score across `fields`.
    function rank(needle: string, items: var, fields: var): var {
        const out = [];
        for (const it of items) {
            let best = -1;
            for (const f of fields) {
                const v = it[f];
                if (typeof v !== "string" || v === "") continue;
                const sc = root.score(needle, v);
                if (sc > best) best = sc;
            }
            if (best >= 0) out.push({ item: it, score: best });
        }
        out.sort((a, b) => b.score - a.score);
        return out.map(o => o.item);
    }
}
