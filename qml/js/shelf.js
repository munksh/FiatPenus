// Where a call goes. The phone's own household is /houses/-1 and is answered
// here, from the phone; every other household is Pantry on the server,
// through `api`. Both answer in Pantry's shape and with api's callback,
// function (ok, data, status, message), so a page never needs to know which
// one it is talking to.
//
// The phone answers at once, before the call returns. Nothing in the app
// depends on the answer coming later.

.import "storage.js" as Storage

var LOCAL = -1
var PREFIX = "/houses/-1"

function isLocal(path) {
    return path === PREFIX || path.indexOf(PREFIX + "/") === 0
}

function localHouse(name, description) {
    return { id: LOCAL, name: name, description: description, local: true, role: "", isAdmin: true }
}

function parts(path) {
    return path.substring(PREFIX.length).split("/").filter(function (p) { return p !== "" })
}

function num(v) { return parseInt(v, 10) || 0 }

function forget(paths) {
    for (var i = 0; i < paths.length; i++)
        if (paths[i] !== "") files.forget(paths[i])
}

// What a GET on the phone's household answers, or undefined for a path it
// does not have.
function read(path) {
    var p = parts(path)
    if (p[0] === "lists" && p.length === 1) return Storage.lists()
    if (p[0] === "lists" && p.length === 3 && p[2] === "items") return Storage.items(num(p[1]))
    if (p[0] === "items" && p.length === 1) return Storage.items(0)
    if (p[0] === "categories" && p.length === 1) return Storage.categories()
    if (p[0] === "notes" && p.length === 1) return Storage.notes()
    if (p[0] === "photos" && p.length === 1) return Storage.photos()
    if (p[0] === "photos" && p[1] === "folders" && p.length === 2) return Storage.folders()
    if (p[0] === "members") return []
    return undefined
}

function write(method, path, body) {
    var p = parts(path)
    var b = body || {}
    if (p[0] === "lists") {
        if (p.length === 1 && method === "POST") return Storage.addList(b)
        var listId = num(p[1])
        if (p.length === 2 && method === "PATCH") return Storage.updateList(listId, b)
        if (p.length === 2 && method === "DELETE") { forget(Storage.deleteList(listId)); return {} }
        if (p.length === 3 && p[2] === "items" && method === "POST") return Storage.addItem(listId, b)
        var itemId = num(p[3])
        if (p.length === 4 && method === "PATCH") return Storage.updateItem(itemId, b)
        if (p.length === 4 && method === "DELETE") { forget(Storage.deleteItems([itemId])); return {} }
        if (p.length === 5 && p[4] === "toggle") {
            var gone = []
            var out = Storage.toggle(itemId, gone)
            forget(gone)
            return out
        }
        if (p.length === 5 && p[4] === "image" && method === "DELETE") {
            var it = Storage.rowOf("shelf_items", itemId, Storage.item)
            if (it && it.imageFileId) {
                forget([Storage.dropFile(it.imageFileId)])
                return Storage.updateItem(itemId, { imageFileId: 0 })
            }
            return it
        }
    }
    if (p[0] === "items" && p[1] === "batch" && method === "POST") {
        var ids = b.itemIds || []
        if (p[2] === "uncheck") { Storage.uncheck(ids); return {} }
        if (p[2] === "delete") { forget(Storage.deleteItems(ids)); return {} }
    }
    if (p[0] === "categories") {
        if (p.length === 1 && method === "POST") return Storage.addCategory(b)
        if (p.length === 2 && method === "PATCH") return Storage.updateCategory(num(p[1]), b)
        if (p.length === 2 && method === "DELETE") { Storage.deleteCategory(num(p[1])); return {} }
    }
    if (p[0] === "notes") {
        if (p.length === 1 && method === "POST") return Storage.addNote(b)
        if (p.length === 2 && method === "PATCH") return Storage.updateNote(num(p[1]), b)
        if (p.length === 2 && method === "DELETE") { Storage.deleteNote(num(p[1])); return {} }
    }
    if (p[0] === "photos" && p[1] === "folders") {
        if (p.length === 2 && method === "POST") return Storage.addFolder(b)
        if (p.length === 3 && method === "PATCH") return Storage.updateFolder(num(p[2]), b)
        if (p.length === 3 && method === "DELETE") { Storage.deleteFolder(num(p[2])); return {} }
    }
    if (p[0] === "photos" && p.length === 2) {
        if (method === "PATCH") return Storage.updatePhoto(num(p[1]), b)
        if (method === "DELETE") { forget([Storage.deletePhoto(num(p[1]))]); return {} }
    }
    return undefined
}

function answer(callback, data) {
    if (!callback) return
    if (data === undefined || data === null) callback(false, null, 404, "")
    else callback(true, data, 200, "")
}

// ---- the same calls as api ----

function get(path, query, callback) {
    if (!isLocal(path)) return api.get(path, query, callback)
    answer(callback, read(path))
}

function cached(path, query) {
    if (!isLocal(path)) return api.cached(path, query)
    return read(path)
}

function send(method, path, body, callback) {
    if (!isLocal(path)) return api.send(method, path, body, callback)
    answer(callback, write(method, path, body))
}

// A picture for the phone's household is not copied: the household keeps the
// path of the one the picker pointed at.
function upload(path, fileUrl, fields, callback) {
    if (!isLocal(path)) return api.upload(path, fileUrl, fields, callback)
    var kept = files.localPath(fileUrl)
    if (kept === "") { answer(callback, null); return }
    var p = parts(path)
    if (p[0] === "photos" && p.length === 1) {
        answer(callback, Storage.addPhoto(kept, fields || {}))
        return
    }
    if (p[0] === "lists" && p.length === 5 && p[4] === "image") {
        var itemId = num(p[3])
        var before = Storage.rowOf("shelf_items", itemId, Storage.item)
        if (before && before.imageFileId) forget([Storage.dropFile(before.imageFileId)])
        answer(callback, Storage.updateItem(itemId, { imageFileId: Storage.addFile(kept) }))
        return
    }
    answer(callback, null)
}

// The phone's pictures are files; a URL to one is all an Image needs.
function imageUrl(path, query) {
    if (!isLocal(path)) return api.imageUrl(path, query)
    var p = parts(path)
    var file = ""
    if (p[0] === "photos" && p.length === 3 && p[2] === "preview") file = Storage.photoPath(num(p[1]))
    else if (p[0] === "image-preview" && query && query.fileId) file = Storage.filePath(num(query.fileId))
    // Encoded part by part: a name with a space, a # or a % in it is still one file.
    return file === "" ? "" : "file://" + file.split("/").map(encodeURIComponent).join("/")
}
