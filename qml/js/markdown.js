.pragma library

// Enough Markdown for a note on the fridge, turned into the rich text a QML
// Label can show: headings, bold, italic, strike, code, links, lists, ticks,
// quotes and rules. Qt 5.6 has no Markdown of its own.

// Not named escape: on the phone's Qt 5.6 a call to escape() inside this file
// reached the global, URL-style escape() instead, and "Här kan" came out as
// "H%E4r%20kan".
function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")
}

function inline(s, linkColour) {
    var codes = []
    s = s.replace(/`([^`]+)`/g, function (m, c) { codes.push(c); return "\u0000" + (codes.length - 1) + "\u0000" })
    s = escapeHtml(s)
    s = s.replace(/\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)/g,
                  '<a href="$2"><font color="' + linkColour + '">$1</font></a>')
    s = s.replace(/(^|[\s(])(https?:\/\/[^\s<)]*[^\s<).,;:!?])/g,
                  '$1<a href="$2"><font color="' + linkColour + '">$2</font></a>')
    s = s.replace(/\*\*([^*]+)\*\*/g, "<b>$1</b>")
    s = s.replace(/__([^_]+)__/g, "<b>$1</b>")
    s = s.replace(/(^|[^*])\*([^*\s][^*]*)\*/g, "$1<i>$2</i>")
    s = s.replace(/(^|[^\w_])_([^_\s][^_]*)_/g, "$1<i>$2</i>")
    s = s.replace(/~~([^~]+)~~/g, "<s>$1</s>")
    s = s.replace(/\u0000(\d+)\u0000/g, function (m, i) { return "<tt>" + escapeHtml(codes[Number(i)]) + "</tt>" })
    return s
}

function toRich(text, linkColour, quietColour) {
    if (!text)
        return ""
    var lines = String(text).replace(/\r\n?/g, "\n").split("\n")
    var out = []
    var list = ""          // "ul", "ol" or ""
    var fence = false

    function closeList() {
        if (list !== "") {
            out.push("</" + list + ">")
            list = ""
        }
    }

    for (var i = 0; i < lines.length; ++i) {
        var line = lines[i]

        if (/^\s*```/.test(line)) {
            closeList()
            out.push(fence ? "</pre>" : "<pre>")
            fence = !fence
            continue
        }
        if (fence) {
            out.push(escapeHtml(line))
            continue
        }

        var m
        if ((m = /^\s*[-*+]\s+\[( |x|X)\]\s+(.*)$/.exec(line))) {
            closeList()
            var ticked = m[1] !== " "
            out.push("<p>" + (ticked ? "☑ " : "☐ ")
                     + (ticked ? '<font color="' + quietColour + '">' + inline(m[2], linkColour) + "</font>"
                               : inline(m[2], linkColour)) + "</p>")
            continue
        }
        if ((m = /^\s*[-*+]\s+(.*)$/.exec(line))) {
            if (list !== "ul") { closeList(); out.push("<ul>"); list = "ul" }
            out.push("<li>" + inline(m[1], linkColour) + "</li>")
            continue
        }
        if ((m = /^\s*\d+[.)]\s+(.*)$/.exec(line))) {
            if (list !== "ol") { closeList(); out.push("<ol>"); list = "ol" }
            out.push("<li>" + inline(m[1], linkColour) + "</li>")
            continue
        }
        closeList()

        if ((m = /^(#{1,6})\s+(.*)$/.exec(line))) {
            var level = Math.min(m[1].length + 2, 6)
            out.push("<h" + level + ">" + inline(m[2], linkColour) + "</h" + level + ">")
            continue
        }
        if (/^\s*(?:(?:-\s*){3,}|(?:\*\s*){3,}|(?:_\s*){3,})$/.test(line)) {
            out.push("<hr/>")
            continue
        }
        if ((m = /^\s*>\s?(.*)$/.exec(line))) {
            out.push('<p><i><font color="' + quietColour + '">' + inline(m[1], linkColour) + "</font></i></p>")
            continue
        }
        if (line.trim() === "") {
            out.push("<br/>")
            continue
        }
        out.push("<p>" + inline(line, linkColour) + "</p>")
    }
    closeList()
    if (fence)
        out.push("</pre>")
    return out.join("")
}

// A few plain lines for a card on the wall: the marks taken out.
function preview(text, maxLines) {
    if (!text)
        return ""
    var lines = String(text).replace(/\r\n?/g, "\n").split("\n")
    var out = []
    for (var i = 0; i < lines.length && out.length < maxLines; ++i) {
        var l = lines[i]
        if (/^\s*```/.test(l) || l.trim() === "")
            continue
        l = l.replace(/^\s*[-*+]\s+\[( |x|X)\]\s+/, function (m, t) { return t === " " ? "☐ " : "☑ " })
        l = l.replace(/^\s*[-*+]\s+/, "• ")
        l = l.replace(/^#{1,6}\s+/, "")
        l = l.replace(/^\s*>\s?/, "")
        l = l.replace(/\*\*|__|~~|`/g, "")
        l = l.replace(/(^|[^\w*])\*([^*\s][^*]*)\*/g, "$1$2")
        l = l.replace(/\[([^\]]+)\]\([^)]+\)/g, "$1")
        out.push(l)
    }
    return out.join("\n")
}
