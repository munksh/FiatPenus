/*
 * The phone's own household: lists, notes and photos kept in one database on
 * the phone. Everything comes back in the shape Pantry sends, so the pages
 * cannot tell this household from one on a server. shelf.js does the routing.
 *
 * Times are in seconds, as Pantry's are. Pictures are files in the app's own
 * folder; the database holds their paths in `files`, and a photo or an item
 * points at one of those rows the way Pantry points at a Nextcloud file.
 */

.import QtQuick.LocalStorage 2.0 as LS

var ready = false

function db() {
    var d = LS.LocalStorage.openDatabaseSync("FiatPenus", "", "fiat penus", 1000000)
    if (!ready) {
        ready = true
        d = migrate(d)
    }
    return d
}

// Walked forward one step at a time. Write a new step, never edit a shipped one.
function migrate(d) {
    if (d.version === "") {
        d.changeVersion("", "1", function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS shelf_lists (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, description TEXT DEFAULT '', color TEXT DEFAULT '', sortOrder INTEGER DEFAULT 0, createdAt INTEGER DEFAULT 0, updatedAt INTEGER DEFAULT 0)")
            tx.executeSql("CREATE TABLE IF NOT EXISTS shelf_items (id INTEGER PRIMARY KEY AUTOINCREMENT, listId INTEGER NOT NULL, name TEXT NOT NULL, description TEXT DEFAULT '', quantity TEXT DEFAULT '', categoryId INTEGER DEFAULT 0, done INTEGER DEFAULT 0, doneAt INTEGER DEFAULT 0, rrule TEXT DEFAULT '', repeatFromCompletion INTEGER DEFAULT 0, deleteOnDone INTEGER DEFAULT 0, nextDueAt INTEGER DEFAULT 0, imageFileId INTEGER DEFAULT 0, sortOrder INTEGER DEFAULT 0, createdAt INTEGER DEFAULT 0, updatedAt INTEGER DEFAULT 0)")
            tx.executeSql("CREATE TABLE IF NOT EXISTS shelf_categories (id INTEGER PRIMARY KEY AUTOINCREMENT, listId INTEGER DEFAULT 0, name TEXT NOT NULL, color TEXT DEFAULT '', icon TEXT DEFAULT '', sortOrder INTEGER DEFAULT 0, createdAt INTEGER DEFAULT 0)")
            tx.executeSql("CREATE TABLE IF NOT EXISTS shelf_notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT DEFAULT '', color TEXT DEFAULT '', isPinned INTEGER DEFAULT 0, sortOrder INTEGER DEFAULT 0, createdAt INTEGER DEFAULT 0, updatedAt INTEGER DEFAULT 0)")
            tx.executeSql("CREATE TABLE IF NOT EXISTS shelf_folders (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, sortOrder INTEGER DEFAULT 0, createdAt INTEGER DEFAULT 0)")
            tx.executeSql("CREATE TABLE IF NOT EXISTS shelf_photos (id INTEGER PRIMARY KEY AUTOINCREMENT, folderId INTEGER DEFAULT 0, fileId INTEGER NOT NULL, caption TEXT DEFAULT '', sortOrder INTEGER DEFAULT 0, createdAt INTEGER DEFAULT 0, updatedAt INTEGER DEFAULT 0)")
            tx.executeSql("CREATE TABLE IF NOT EXISTS shelf_files (id INTEGER PRIMARY KEY AUTOINCREMENT, path TEXT NOT NULL)")
        })
        d = LS.LocalStorage.openDatabaseSync("FiatPenus", "", "fiat penus", 1000000)
    }
    return d
}

// LocalStorage stores a bound "" as NULL, so text is read back through text().
function text(v) { return (v === null || v === undefined) ? "" : String(v) }
function nowSeconds() { return Math.floor(new Date().getTime() / 1000) }

function rowOf(table, id, wrap) {
    var out = null
    db().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT * FROM " + table + " WHERE id = ?", [id])
        if (rs.rows.length > 0) out = wrap(rs.rows.item(0))
    })
    return out
}

function nextSort(tx, table, where, args) {
    var rs = tx.executeSql("SELECT IFNULL(MAX(sortOrder), -1) + 1 AS n FROM " + table + (where ? " WHERE " + where : ""), args || [])
    return rs.rows.item(0).n
}

// Writes the fields that were sent, and only those. "" clears a text; a number
// field of 0 clears a reference, as Pantry's categoryId 0 does.
function update(table, id, f, texts, flags, numbers, wrap) {
    var sets = [], args = []
    var i
    for (i = 0; i < texts.length; i++)
        if (f[texts[i]] !== undefined) { sets.push(texts[i] + " = ?"); args.push(text(f[texts[i]])) }
    for (i = 0; i < flags.length; i++)
        if (f[flags[i]] !== undefined) { sets.push(flags[i] + " = ?"); args.push(f[flags[i]] ? 1 : 0) }
    for (i = 0; i < numbers.length; i++)
        if (f[numbers[i]] !== undefined) { sets.push(numbers[i] + " = ?"); args.push(f[numbers[i]] > 0 ? f[numbers[i]] : 0) }
    if (sets.length > 0) {
        args.push(id)
        db().transaction(function (tx) { tx.executeSql("UPDATE " + table + " SET " + sets.join(", ") + " WHERE id = ?", args) })
    }
    return rowOf(table, id, wrap)
}

// ---- files ----

function filePath(id) {
    var out = ""
    db().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT path FROM shelf_files WHERE id = ?", [id])
        if (rs.rows.length > 0) out = text(rs.rows.item(0).path)
    })
    return out
}

function addFile(path) {
    var id = 0
    db().transaction(function (tx) {
        id = parseInt(tx.executeSql("INSERT INTO shelf_files (path) VALUES (?)", [path]).insertId, 10)
    })
    return id
}

// Returns the path, so the caller can take the file itself away.
function dropFile(id) {
    var path = filePath(id)
    db().transaction(function (tx) { tx.executeSql("DELETE FROM shelf_files WHERE id = ?", [id]) })
    return path
}

// ---- lists ----

function list(r) {
    return { id: r.id, houseId: -1, name: text(r.name), description: text(r.description),
             color: text(r.color), icon: "", sortOrder: r.sortOrder, canEdit: true,
             createdAt: r.createdAt, updatedAt: r.updatedAt }
}

function lists() {
    var out = []
    db().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT * FROM shelf_lists ORDER BY sortOrder ASC, id ASC", [])
        for (var i = 0; i < rs.rows.length; i++) out.push(list(rs.rows.item(i)))
    })
    return out
}

function addList(f) {
    var now = nowSeconds(), id = 0
    db().transaction(function (tx) {
        id = parseInt(tx.executeSql("INSERT INTO shelf_lists (name, description, color, sortOrder, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?)",
                                    [text(f.name), text(f.description), text(f.color), nextSort(tx, "shelf_lists"), now, now]).insertId, 10)
    })
    return rowOf("shelf_lists", id, list)
}

function updateList(id, f) {
    return update("shelf_lists", id, f, ["name", "description", "color"], [], [], list)
}

// Returns the files the list's items had, for the caller to remove.
function deleteList(id) {
    var paths = []
    db().transaction(function (tx) {
        var rs = tx.executeSql("SELECT f.id, f.path FROM shelf_items i JOIN shelf_files f ON f.id = i.imageFileId WHERE i.listId = ?", [id])
        for (var i = 0; i < rs.rows.length; i++) {
            paths.push(text(rs.rows.item(i).path))
            tx.executeSql("DELETE FROM shelf_files WHERE id = ?", [rs.rows.item(i).id])
        }
        tx.executeSql("DELETE FROM shelf_items WHERE listId = ?", [id])
        tx.executeSql("DELETE FROM shelf_categories WHERE listId = ?", [id])
        tx.executeSql("DELETE FROM shelf_lists WHERE id = ?", [id])
    })
    return paths
}

// ---- items ----

function item(r) {
    return { id: r.id, listId: r.listId, name: text(r.name), description: text(r.description),
             quantity: text(r.quantity), categoryId: r.categoryId > 0 ? r.categoryId : null,
             done: r.done === 1, doneAt: r.doneAt > 0 ? r.doneAt : null, rrule: text(r.rrule),
             repeatFromCompletion: r.repeatFromCompletion === 1, deleteOnDone: r.deleteOnDone === 1,
             nextDueAt: r.nextDueAt > 0 ? r.nextDueAt : null,
             imageFileId: r.imageFileId > 0 ? r.imageFileId : null, imageUploadedBy: "", addedBy: "",
             sortOrder: r.sortOrder, createdAt: r.createdAt, updatedAt: r.updatedAt }
}

// A repeating item that was ticked off comes back on the day it is due again.
function revive() {
    var now = nowSeconds()
    db().transaction(function (tx) {
        tx.executeSql("UPDATE shelf_items SET done = 0, doneAt = 0, nextDueAt = 0, updatedAt = ? WHERE done = 1 AND nextDueAt > 0 AND nextDueAt <= ?", [now, now])
    })
}

// listId 0 is every list.
function items(listId) {
    revive()
    var out = []
    db().readTransaction(function (tx) {
        var rs = listId > 0
            ? tx.executeSql("SELECT * FROM shelf_items WHERE listId = ? ORDER BY sortOrder ASC, id ASC", [listId])
            : tx.executeSql("SELECT * FROM shelf_items ORDER BY listId ASC, sortOrder ASC, id ASC", [])
        for (var i = 0; i < rs.rows.length; i++) out.push(item(rs.rows.item(i)))
    })
    return out
}

function addItem(listId, f) {
    var now = nowSeconds(), id = 0
    db().transaction(function (tx) {
        id = parseInt(tx.executeSql("INSERT INTO shelf_items (listId, name, description, quantity, categoryId, rrule, repeatFromCompletion, deleteOnDone, sortOrder, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                                    [listId, text(f.name), text(f.description), text(f.quantity), f.categoryId > 0 ? f.categoryId : 0,
                                     text(f.rrule), f.repeatFromCompletion ? 1 : 0, f.deleteOnDone ? 1 : 0,
                                     nextSort(tx, "shelf_items", "listId = ?", [listId]), now, now]).insertId, 10)
    })
    return rowOf("shelf_items", id, item)
}

function updateItem(id, f) {
    update("shelf_items", id, f, ["name", "description", "quantity", "rrule"],
           ["repeatFromCompletion", "deleteOnDone"], ["categoryId", "imageFileId"], item)
    db().transaction(function (tx) {
        tx.executeSql("UPDATE shelf_items SET updatedAt = ? WHERE id = ?", [nowSeconds(), id])
        // A changed rule starts counting again from the next tick.
        if (f.rrule !== undefined)
            tx.executeSql("UPDATE shelf_items SET nextDueAt = 0 WHERE id = ? AND done = 0", [id])
    })
    return rowOf("shelf_items", id, item)
}

// Returns the paths of the pictures the items had.
function deleteItems(ids) {
    var paths = []
    db().transaction(function (tx) {
        for (var i = 0; i < ids.length; i++) {
            var rs = tx.executeSql("SELECT f.id, f.path FROM shelf_items i JOIN shelf_files f ON f.id = i.imageFileId WHERE i.id = ?", [ids[i]])
            if (rs.rows.length > 0) {
                paths.push(text(rs.rows.item(0).path))
                tx.executeSql("DELETE FROM shelf_files WHERE id = ?", [rs.rows.item(0).id])
            }
            tx.executeSql("DELETE FROM shelf_items WHERE id = ?", [ids[i]])
        }
    })
    return paths
}

// The next time a repeating item is wanted: the rule's step from now, at the
// start of that day.
function nextDue(rrule, fromSeconds) {
    var freq = "", interval = 1
    var parts = text(rrule).replace(/^RRULE:/, "").split(";")
    for (var i = 0; i < parts.length; i++) {
        var kv = parts[i].split("=")
        var k = (kv[0] || "").toUpperCase(), v = (kv[1] || "").toUpperCase()
        if (k === "FREQ") freq = v
        else if (k === "INTERVAL") interval = Math.max(1, parseInt(v, 10) || 1)
    }
    var d = new Date(fromSeconds * 1000)
    d.setHours(0, 0, 0, 0)
    if (freq === "DAILY") d.setDate(d.getDate() + interval)
    else if (freq === "WEEKLY") d.setDate(d.getDate() + 7 * interval)
    else if (freq === "MONTHLY" || freq === "YEARLY") {
        var months = freq === "YEARLY" ? 12 * interval : interval
        var day = d.getDate()
        d.setDate(1)
        d.setMonth(d.getMonth() + months)
        d.setDate(Math.min(day, new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()))
    } else {
        return 0
    }
    return Math.floor(d.getTime() / 1000)
}

// Answers like Pantry's toggle: the item as it is now, or, for one that goes
// away when done, its id with deletedAt. `paths` gets any picture it leaves.
function toggle(id, paths) {
    var it = rowOf("shelf_items", id, item)
    if (it === null) return null
    var now = nowSeconds()
    if (!it.done && it.deleteOnDone && it.rrule === "") {
        var gone = deleteItems([id])
        for (var i = 0; i < gone.length; i++) paths.push(gone[i])
        return { id: id, deletedAt: now }
    }
    db().transaction(function (tx) {
        if (it.done)
            tx.executeSql("UPDATE shelf_items SET done = 0, doneAt = 0, nextDueAt = 0, updatedAt = ? WHERE id = ?", [now, id])
        else
            tx.executeSql("UPDATE shelf_items SET done = 1, doneAt = ?, nextDueAt = ?, updatedAt = ? WHERE id = ?", [now, nextDue(it.rrule, now), now, id])
    })
    return rowOf("shelf_items", id, item)
}

function uncheck(ids) {
    var now = nowSeconds()
    db().transaction(function (tx) {
        for (var i = 0; i < ids.length; i++)
            tx.executeSql("UPDATE shelf_items SET done = 0, doneAt = 0, nextDueAt = 0, updatedAt = ? WHERE id = ?", [now, ids[i]])
    })
}

// ---- categories ----

function category(r) {
    return { id: r.id, houseId: -1, listId: r.listId > 0 ? r.listId : null, name: text(r.name),
             color: text(r.color), icon: text(r.icon), sortOrder: r.sortOrder, createdAt: r.createdAt }
}

function categories() {
    var out = []
    db().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT * FROM shelf_categories ORDER BY sortOrder ASC, id ASC", [])
        for (var i = 0; i < rs.rows.length; i++) out.push(category(rs.rows.item(i)))
    })
    return out
}

function addCategory(f) {
    var id = 0
    db().transaction(function (tx) {
        id = parseInt(tx.executeSql("INSERT INTO shelf_categories (listId, name, color, icon, sortOrder, createdAt) VALUES (?, ?, ?, ?, ?, ?)",
                                    [f.listId > 0 ? f.listId : 0, text(f.name), text(f.color), text(f.icon),
                                     nextSort(tx, "shelf_categories"), nowSeconds()]).insertId, 10)
    })
    return rowOf("shelf_categories", id, category)
}

function updateCategory(id, f) {
    return update("shelf_categories", id, f, ["name", "color", "icon"], [], [], category)
}

function deleteCategory(id) {
    db().transaction(function (tx) {
        tx.executeSql("UPDATE shelf_items SET categoryId = 0 WHERE categoryId = ?", [id])
        tx.executeSql("DELETE FROM shelf_categories WHERE id = ?", [id])
    })
}

// ---- notes ----

function note(r) {
    return { id: r.id, houseId: -1, title: text(r.title), content: text(r.content), color: text(r.color),
             isPinned: r.isPinned === 1, sortOrder: r.sortOrder, createdBy: "", canEdit: true,
             createdAt: r.createdAt, updatedAt: r.updatedAt }
}

function notes() {
    var out = []
    db().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT * FROM shelf_notes ORDER BY isPinned DESC, sortOrder ASC, id ASC", [])
        for (var i = 0; i < rs.rows.length; i++) out.push(note(rs.rows.item(i)))
    })
    return out
}

function addNote(f) {
    var now = nowSeconds(), id = 0
    db().transaction(function (tx) {
        id = parseInt(tx.executeSql("INSERT INTO shelf_notes (title, content, color, isPinned, sortOrder, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?, ?)",
                                    [text(f.title), text(f.content), text(f.color), f.isPinned ? 1 : 0,
                                     nextSort(tx, "shelf_notes"), now, now]).insertId, 10)
    })
    return rowOf("shelf_notes", id, note)
}

function updateNote(id, f) {
    var out = update("shelf_notes", id, f, ["title", "content", "color"], ["isPinned"], [], note)
    db().transaction(function (tx) { tx.executeSql("UPDATE shelf_notes SET updatedAt = ? WHERE id = ?", [nowSeconds(), id]) })
    return rowOf("shelf_notes", id, note) || out
}

function deleteNote(id) {
    db().transaction(function (tx) { tx.executeSql("DELETE FROM shelf_notes WHERE id = ?", [id]) })
}

// ---- folders and photos ----

function folder(r) {
    return { id: r.id, houseId: -1, name: text(r.name), sortOrder: r.sortOrder, canEdit: true, createdAt: r.createdAt }
}

function folders() {
    var out = []
    db().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT * FROM shelf_folders ORDER BY sortOrder ASC, id ASC", [])
        for (var i = 0; i < rs.rows.length; i++) out.push(folder(rs.rows.item(i)))
    })
    return out
}

function addFolder(f) {
    var id = 0
    db().transaction(function (tx) {
        id = parseInt(tx.executeSql("INSERT INTO shelf_folders (name, sortOrder, createdAt) VALUES (?, ?, ?)",
                                    [text(f.name), nextSort(tx, "shelf_folders"), nowSeconds()]).insertId, 10)
    })
    return rowOf("shelf_folders", id, folder)
}

function updateFolder(id, f) {
    return update("shelf_folders", id, f, ["name"], [], [], folder)
}

// The photos in it stay, loose on the board, as Pantry keeps them.
function deleteFolder(id) {
    db().transaction(function (tx) {
        tx.executeSql("UPDATE shelf_photos SET folderId = 0 WHERE folderId = ?", [id])
        tx.executeSql("DELETE FROM shelf_folders WHERE id = ?", [id])
    })
}

function photo(r) {
    return { id: r.id, houseId: -1, folderId: r.folderId > 0 ? r.folderId : null, fileId: r.fileId,
             caption: text(r.caption), uploadedBy: "", sortOrder: r.sortOrder, canEdit: true,
             createdAt: r.createdAt, updatedAt: r.updatedAt }
}

function photos() {
    var out = []
    db().readTransaction(function (tx) {
        var rs = tx.executeSql("SELECT * FROM shelf_photos ORDER BY sortOrder ASC, id ASC", [])
        for (var i = 0; i < rs.rows.length; i++) out.push(photo(rs.rows.item(i)))
    })
    return out
}

function addPhoto(path, f) {
    var now = nowSeconds(), id = 0
    var fileId = addFile(path)
    db().transaction(function (tx) {
        id = parseInt(tx.executeSql("INSERT INTO shelf_photos (folderId, fileId, caption, sortOrder, createdAt, updatedAt) VALUES (?, ?, ?, ?, ?, ?)",
                                    [f.folderId > 0 ? f.folderId : 0, fileId, text(f.caption), nextSort(tx, "shelf_photos"), now, now]).insertId, 10)
    })
    return rowOf("shelf_photos", id, photo)
}

function updatePhoto(id, f) {
    return update("shelf_photos", id, f, ["caption"], [], ["folderId"], photo)
}

// Returns the picture's path, for the caller to remove.
function deletePhoto(id) {
    var p = rowOf("shelf_photos", id, photo)
    if (p === null) return ""
    db().transaction(function (tx) { tx.executeSql("DELETE FROM shelf_photos WHERE id = ?", [id]) })
    return dropFile(p.fileId)
}

function photoPath(id) {
    var p = rowOf("shelf_photos", id, photo)
    return p === null ? "" : filePath(p.fileId)
}
