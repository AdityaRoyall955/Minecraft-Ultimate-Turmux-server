#!/usr/bin/env python3
"""Local browser manager for server mods and plugins."""

import html
import json
import os
import threading
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from email import policy
from email.parser import BytesParser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent.parent
PORT = int(os.environ.get("MINECRAFT_MANAGER_PORT", "8765"))
ALLOWED = {"mods": ROOT / "mods", "plugins": ROOT / "plugins"}
CUSTOM_CONFIG = ROOT / "core" / "custom-software.json"
SETTINGS_FILE = ROOT / "core" / "manager-settings.json"
VERSION_DIR = ROOT / "versions"
SERVER = None

for directory in ALLOWED.values():
    directory.mkdir(parents=True, exist_ok=True)


def safe_file(directory, filename):
    name = Path(filename).name
    if not name or name in {".", ".."}:
        raise ValueError("Invalid file name")
    return directory / name


def files_for(kind):
    return sorted(
        path.name for path in ALLOWED[kind].iterdir() if path.is_file()
    )


def load_settings():
    defaults = {"menu_title": "Minecraft Server Manager", "accent": "#56d6a0", "curseforge_api_key": ""}
    if SETTINGS_FILE.exists():
        try:
            saved = json.loads(SETTINGS_FILE.read_text())
            defaults.update({key: saved[key] for key in defaults if key in saved})
        except (OSError, json.JSONDecodeError):
            pass
    return defaults


def save_settings(payload):
    current = load_settings()
    title = str(payload.get("menu_title", current["menu_title"])).strip()[:80]
    accent = str(payload.get("accent", current["accent"])).strip()
    api_key = str(payload.get("curseforge_api_key", "")).strip()
    if not title:
        raise ValueError("Menu title cannot be empty")
    if not (len(accent) == 7 and accent.startswith("#") and all(char in "0123456789abcdefABCDEF" for char in accent[1:])):
        raise ValueError("Accent must be a hex color such as #56d6a0")
    if api_key:
        current["curseforge_api_key"] = api_key
    current.update({"menu_title": title, "accent": accent})
    SETTINGS_FILE.parent.mkdir(parents=True, exist_ok=True)
    SETTINGS_FILE.write_text(json.dumps(current, indent=2) + "\n")
    return {"menu_title": title, "accent": accent, "curseforge_configured": bool(current["curseforge_api_key"])}


def json_request(url, method="GET", payload=None):
    data = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = urllib.request.Request(
        url,
        data=data,
        method=method,
        headers={"Accept": "application/json", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))


def download_bytes(url):
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or parsed.hostname not in {
        "cdn.modrinth.com", "api.modrinth.com", "modrinth.com",
        "edge.forgecdn.net", "mediafilez.forgecdn.net", "www.curseforge.com", "curseforge.com"
    }:
        raise ValueError("Download URL is not a trusted Modrinth URL")
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()


def curseforge_request(path, params=None):
    api_key = load_settings()["curseforge_api_key"]
    if not api_key:
        raise ValueError("Add a CurseForge API key in Settings first")
    url = "https://api.curseforge.com/v1/" + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    request = urllib.request.Request(url, headers={"Accept": "application/json", "x-api-key": api_key})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read().decode("utf-8"))["data"]


def search_curseforge(search, project_type):
    class_id = "6" if project_type == "mod" else "5"
    return curseforge_request("mods/search", {"gameId": "432", "classId": class_id, "searchFilter": search, "pageSize": "12", "sortField": "2", "sortOrder": "desc"})


def install_curseforge(project_id, kind):
    if kind not in ALLOWED:
        raise ValueError("Choose Mods or Plugins")
    files = curseforge_request(f"mods/{int(project_id)}/files", {"pageSize": "20", "sortField": "2", "sortOrder": "desc"})
    file_info = next((item for item in files if item.get("downloadUrl")), None)
    if not file_info:
        raise ValueError("No downloadable CurseForge file found")
    target = safe_file(ALLOWED[kind], file_info["fileName"])
    target.write_bytes(download_bytes(file_info["downloadUrl"]))
    return {"name": target.name, "version": file_info.get("displayName", "latest")}


def safe_relative_path(relative):
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError("Archive contains an unsafe path")
    return path


def import_modpack(filename, data):
    if not filename.lower().endswith(".mrpack"):
        raise ValueError("Only Modrinth .mrpack files are supported")
    installed = []
    with zipfile.ZipFile(__import__("io").BytesIO(data)) as archive:
        index = json.loads(archive.read("modrinth.index.json"))
        for entry in index.get("files", []):
            target = ROOT / safe_relative_path(entry["path"])
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(download_bytes(entry["downloads"][0]))
            installed.append(str(target.relative_to(ROOT)))
        for member in archive.infolist():
            if not member.filename.startswith("overrides/") or member.is_dir():
                continue
            relative = safe_relative_path(member.filename.removeprefix("overrides/"))
            target = ROOT / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(archive.read(member))
            installed.append(str(target.relative_to(ROOT)))
    return installed


def install_modrinth(project_id, kind, version_id=None):
    if kind not in ALLOWED:
        raise ValueError("Choose Mods or Plugins")
    versions = json_request(
        "https://api.modrinth.com/v2/project/"
        + urllib.parse.quote(project_id, safe="")
        + "/version"
    )
    if version_id:
        versions = [version for version in versions if version["id"] == version_id]
    if not versions or not versions[0].get("files"):
        raise ValueError("No downloadable Modrinth version found")
    version = versions[0]
    file_info = next((item for item in version["files"] if item.get("primary")), version["files"][0])
    target = safe_file(ALLOWED[kind], file_info["filename"])
    target.write_bytes(download_bytes(file_info["url"]))
    return {"name": target.name, "version": version.get("version_number", "latest")}


def install_custom_software(payload):
    name = str(payload.get("name", "")).strip()
    version = str(payload.get("version", "")).strip()
    url = str(payload.get("url", "")).strip()
    if not name or not version or not url or not url.startswith("https://"):
        raise ValueError("Name, version, and an HTTPS JAR URL are required")
    jar_name = "server.jar"
    jar_path = ROOT / jar_name
    request = urllib.request.Request(url, headers={"User-Agent": "Minecraft-Manager"})
    with urllib.request.urlopen(request, timeout=120) as response:
        jar_path.write_bytes(response.read())
    CUSTOM_CONFIG.parent.mkdir(parents=True, exist_ok=True)
    CUSTOM_CONFIG.write_text(json.dumps({"name": name, "version": version, "url": url, "jar": jar_name}, indent=2) + "\n")
    VERSION_DIR.mkdir(exist_ok=True)
    (VERSION_DIR / "custom.version").write_text(version + "\n")
    config = ROOT / "core" / "server.conf"
    lines = config.read_text().splitlines() if config.exists() else []
    lines = [line for line in lines if not line.startswith("SERVER_TYPE=")]
    lines.append("SERVER_TYPE=Custom")
    config.write_text("\n".join(lines) + "\n")
    return {"name": name, "version": version, "jar": jar_name}


class ManagerHandler(BaseHTTPRequestHandler):
    def log_message(self, format_string, *args):
        return

    def send_json(self, payload, status=200):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/":
            self.send_html()
            return
        if parsed.path == "/api/files":
            self.send_json({kind: files_for(kind) for kind in ALLOWED})
            return
        if parsed.path == "/api/modrinth/search":
            query = parse_qs(parsed.query)
            search = query.get("q", [""])[0].strip()
            project_type = query.get("type", ["mod"])[0]
            if not search or project_type not in {"mod", "plugin"}:
                self.send_json({"hits": []})
                return
            params = urllib.parse.urlencode({
                "query": search,
                "limit": 12,
                "index": "relevance",
                "facets": json.dumps([[f"project_type:{project_type}"]]),
            })
            self.send_json(json_request("https://api.modrinth.com/v2/search?" + params))
            return
        if parsed.path == "/api/curseforge/search":
            query = parse_qs(parsed.query)
            search = query.get("q", [""])[0].strip()
            project_type = query.get("type", ["mod"])[0]
            try:
                self.send_json({"data": search_curseforge(search, project_type) if search else []})
            except (ValueError, OSError, urllib.error.URLError) as error:
                self.send_json({"error": str(error)}, 400)
            return
        if parsed.path == "/api/settings":
            settings = load_settings()
            self.send_json({"menu_title": settings["menu_title"], "accent": settings["accent"], "curseforge_configured": bool(settings["curseforge_api_key"])})
            return
        if parsed.path == "/api/custom-software":
            if CUSTOM_CONFIG.exists():
                self.send_json(json.loads(CUSTOM_CONFIG.read_text()))
            else:
                self.send_json({})
            return
        self.send_error(404)

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/import":
            self.import_file()
            return
        if parsed.path == "/api/modrinth/install":
            try:
                payload = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
                self.send_json({"ok": True, **install_modrinth(payload.get("project_id", ""), payload.get("kind", "mods"), payload.get("version_id"))})
            except (ValueError, KeyError, OSError, urllib.error.URLError, json.JSONDecodeError) as error:
                self.send_json({"error": str(error)}, 400)
            return
        if parsed.path == "/api/curseforge/install":
            try:
                payload = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
                self.send_json({"ok": True, **install_curseforge(payload.get("project_id", ""), payload.get("kind", "mods"))})
            except (ValueError, KeyError, OSError, urllib.error.URLError, json.JSONDecodeError) as error:
                self.send_json({"error": str(error)}, 400)
            return
        if parsed.path == "/api/settings":
            try:
                payload = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
                self.send_json({"ok": True, **save_settings(payload)})
            except (ValueError, OSError, json.JSONDecodeError) as error:
                self.send_json({"error": str(error)}, 400)
            return
        if parsed.path == "/api/custom-software":
            try:
                payload = json.loads(self.rfile.read(int(self.headers.get("Content-Length", "0"))))
                self.send_json({"ok": True, **install_custom_software(payload)})
            except (ValueError, OSError, urllib.error.URLError, json.JSONDecodeError) as error:
                self.send_json({"error": str(error)}, 400)
            return
        if parsed.path == "/api/end":
            self.send_json({"ok": True})
            threading.Thread(target=shutdown_server, daemon=True).start()
            return
        self.send_error(404)

    def import_file(self):
        query = parse_qs(urlparse(self.path).query)
        kind = query.get("kind", [""])[0]
        if kind not in ALLOWED and kind != "modpacks":
            self.send_json({"error": "Choose Mods, Plugins, or Modpacks"}, 400)
            return

        content_type = self.headers.get("Content-Type", "")
        if not content_type.startswith("multipart/form-data"):
            self.send_json({"error": "Use the import form"}, 400)
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        request_body = self.rfile.read(content_length)
        message = BytesParser(policy=policy.default).parsebytes(
            (f"Content-Type: {content_type}\r\n"
             "MIME-Version: 1.0\r\n\r\n").encode() + request_body
        )
        upload = next(
            (part for part in message.iter_attachments() if part.get_name() == "file"),
            None,
        )
        if not upload or not upload.get_filename():
            self.send_json({"error": "Select a file first"}, 400)
            return

        try:
            data = upload.get_payload(decode=True) or b""
            if kind == "modpacks":
                installed = import_modpack(upload.get_filename(), data)
                self.send_json({"ok": True, "name": upload.get_filename(), "kind": kind, "installed": installed})
                return
            target = safe_file(ALLOWED[kind], upload.get_filename())
            with target.open("wb") as output:
                output.write(data)
        except (OSError, ValueError) as error:
            self.send_json({"error": str(error)}, 400)
            return

        self.send_json({"ok": True, "name": target.name, "kind": kind})

    def send_html(self):
        settings = load_settings()
        body = HTML.replace("__SERVER_TYPE__", html.escape(os.environ.get("SERVER_TYPE", "Minecraft")))
        body = body.replace("__MENU_TITLE__", html.escape(settings["menu_title"]))
        body = body.replace("__ACCENT__", html.escape(settings["accent"]))
        encoded = body.encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)


def shutdown_server():
    if SERVER:
        SERVER.shutdown()


HTML = r"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Minecraft Server Manager</title>
<style>
:root { color-scheme: dark; --bg:#10151c; --panel:#19232d; --line:#344554; --text:#edf4f7; --muted:#9fb0ba; --accent:__ACCENT__; --danger:#ff7676; }
* { box-sizing:border-box; }
body { margin:0; min-height:100vh; background:linear-gradient(145deg,#0b1117,#182a2d); color:var(--text); font:16px system-ui,sans-serif; }
main { width:min(900px,calc(100% - 32px)); margin:32px auto; }
header { display:flex; justify-content:space-between; align-items:center; gap:16px; border-bottom:1px solid var(--line); padding-bottom:20px; }
h1 { margin:0; font-size:clamp(24px,5vw,42px); letter-spacing:0; }
.badge { color:var(--accent); border:1px solid var(--accent); padding:7px 11px; border-radius:6px; white-space:nowrap; }
.grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:18px; margin-top:22px; }
section { background:rgba(25,35,45,.9); border:1px solid var(--line); border-radius:8px; padding:20px; }
h2 { margin:0 0 4px; font-size:22px; }
small { color:var(--muted); }
input[type=file] { width:100%; margin:18px 0 12px; color:var(--muted); }
button { border:0; border-radius:6px; padding:11px 15px; color:#08120e; background:var(--accent); font-weight:700; cursor:pointer; }
button.secondary { background:#d5e1e5; } button.danger { background:var(--danger); }
.actions { display:flex; flex-wrap:wrap; gap:10px; margin-top:22px; }
ul { list-style:none; padding:0; margin:18px 0 0; } li { padding:9px 0; border-top:1px solid #2a3945; overflow-wrap:anywhere; }
#status { min-height:24px; color:var(--muted); margin-top:18px; }
.inline { display:flex; gap:8px; margin-top:16px; }
.inline input { min-width:0; flex:1; }
input, select { width:100%; margin:8px 0; padding:10px; border:1px solid var(--line); border-radius:6px; background:#101920; color:var(--text); }
.result { display:flex; justify-content:space-between; align-items:center; gap:10px; }
.result button { padding:7px 10px; }
</style>
</head>
<body>
<main>
<header><h1>__MENU_TITLE__</h1><span class="badge">__SERVER_TYPE__ · localhost</span></header>
<p>Import server files without stopping the server. Changes are visible after refresh.</p>
<div class="grid">
<section><h2>Mods</h2><small>Upload .jar files to the mods folder.</small><form onsubmit="upload(event,'mods')"><input name="file" type="file" accept=".jar,.zip" required><button type="submit">Import Mod</button></form><ul id="mods"></ul></section>
<section><h2>Plugins</h2><small>Upload .jar files to the plugins folder.</small><form onsubmit="upload(event,'plugins')"><input name="file" type="file" accept=".jar,.zip" required><button type="submit">Import Plugin</button></form><ul id="plugins"></ul></section>
<section><h2>Modpacks</h2><small>Import a Modrinth .mrpack and install its files.</small><form onsubmit="upload(event,'modpacks')"><input name="file" type="file" accept=".mrpack" required><button type="submit">Import Modpack</button></form></section>
<section><h2>Modrinth</h2><small>Find compatible mods and plugins by name.</small><div class="inline"><input id="modrinth-query" placeholder="Search Modrinth"><select id="modrinth-type"><option value="mod">Mods</option><option value="plugin">Plugins</option></select><button onclick="searchModrinth()">Search</button></div><ul id="modrinth-results"></ul></section>
<section><h2>CurseForge</h2><small>Search CurseForge after adding your API key in Settings.</small><div class="inline"><input id="curseforge-query" placeholder="Search CurseForge"><select id="curseforge-type"><option value="mod">Mods</option><option value="plugin">Plugins</option></select><button onclick="searchCurseForge()">Search</button></div><ul id="curseforge-results"></ul></section>
<section><h2>Custom Software</h2><small>Choose a version and download a custom HTTPS server JAR.</small><form onsubmit="installCustom(event)"><input id="custom-name" placeholder="Software name" required><input id="custom-version" placeholder="Version" required><input id="custom-url" type="url" placeholder="HTTPS JAR URL" required><button type="submit">Install Custom Software</button></form><div id="custom-current"></div></section>
<section><h2>Settings</h2><small>Customize the manager menu. The key is stored locally and never displayed.</small><form onsubmit="saveSettings(event)"><input id="settings-title" placeholder="Menu title" required><label>Accent color <input id="settings-accent" type="color" required></label><input id="curseforge-key" type="password" placeholder="CurseForge API key"><button type="submit">Save Settings</button></form><div id="settings-state"></div></section>
</div>
<div class="actions"><button class="secondary" onclick="refreshFiles()">Refresh Mods and Plugins</button><button class="danger" onclick="endPage()">End Download Page</button></div>
<div id="status" role="status"></div>
</main>
<script>
const status = document.getElementById('status');
async function refreshFiles() {
  const response = await fetch('/api/files');
  const data = await response.json();
  for (const kind of ['mods','plugins']) {
    document.getElementById(kind).innerHTML = data[kind].length
      ? data[kind].map(name => `<li>${escapeHtml(name)}</li>`).join('')
      : '<li><small>Nothing imported yet.</small></li>';
  }
  status.textContent = 'Folders refreshed.';
}
async function upload(event, kind) {
  event.preventDefault();
  const form = event.target;
  const response = await fetch(`/api/import?kind=${kind}`, {method:'POST', body:new FormData(form)});
  const data = await response.json();
  status.textContent = data.error || `${data.name} imported into ${kind}.`;
  if (data.ok) { form.reset(); refreshFiles(); }
}
async function searchModrinth() {
    const query = document.getElementById('modrinth-query').value.trim();
    const type = document.getElementById('modrinth-type').value;
    if (!query) return;
    const response = await fetch(`/api/modrinth/search?q=${encodeURIComponent(query)}&type=${type}`);
    const data = await response.json();
    document.getElementById('modrinth-results').innerHTML = (data.hits || []).map(hit =>
        `<li class="result"><span><b>${escapeHtml(hit.title)}</b><br><small>${escapeHtml(hit.description || '')}</small></span><button onclick="installModrinth('${escapeHtml(hit.project_id)}','${type}')">Install</button></li>`
    ).join('') || '<li><small>No Modrinth results.</small></li>';
}
async function installModrinth(projectId, kind) {
    const response = await fetch('/api/modrinth/install', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({project_id:projectId, kind})});
    const data = await response.json();
    status.textContent = data.error || `${data.name} ${data.version} installed.`;
    if (data.ok) refreshFiles();
}
async function searchCurseForge() {
    const query = document.getElementById('curseforge-query').value.trim();
    const type = document.getElementById('curseforge-type').value;
    if (!query) return;
    const response = await fetch(`/api/curseforge/search?q=${encodeURIComponent(query)}&type=${type}`);
    const data = await response.json();
    document.getElementById('curseforge-results').innerHTML = (data.data || []).map(hit =>
        `<li class="result"><span><b>${escapeHtml(hit.name)}</b><br><small>${escapeHtml(hit.summary || '')}</small></span><button onclick="installCurseForge('${hit.id}','${type}')">Install</button></li>`
    ).join('') || `<li><small>${escapeHtml(data.error || 'No CurseForge results.')}</small></li>`;
}
async function installCurseForge(projectId, kind) {
    const response = await fetch('/api/curseforge/install', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({project_id:projectId, kind})});
    const data = await response.json();
    status.textContent = data.error || `${data.name} ${data.version} installed.`;
    if (data.ok) refreshFiles();
}
async function installCustom(event) {
    event.preventDefault();
    const payload = {name:document.getElementById('custom-name').value, version:document.getElementById('custom-version').value, url:document.getElementById('custom-url').value};
    const response = await fetch('/api/custom-software', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(payload)});
    const data = await response.json();
    status.textContent = data.error || `${data.name} ${data.version} installed as the active server.`;
    if (data.ok) loadCustom();
}
async function loadCustom() {
    const response = await fetch('/api/custom-software');
    const data = await response.json();
    document.getElementById('custom-current').textContent = data.name ? `Active: ${data.name} ${data.version}` : 'No custom software installed.';
}
async function loadSettings() {
    const response = await fetch('/api/settings');
    const data = await response.json();
    document.getElementById('settings-title').value = data.menu_title || '';
    document.getElementById('settings-accent').value = data.accent || '#56d6a0';
    document.getElementById('settings-state').textContent = data.curseforge_configured ? 'CurseForge key configured.' : 'CurseForge key not configured.';
}
async function saveSettings(event) {
    event.preventDefault();
    const response = await fetch('/api/settings', {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify({menu_title:document.getElementById('settings-title').value, accent:document.getElementById('settings-accent').value, curseforge_api_key:document.getElementById('curseforge-key').value})});
    const data = await response.json();
    status.textContent = data.error || 'Settings saved. Reopen the manager to apply the title and color.';
    document.getElementById('curseforge-key').value = '';
    if (data.ok) document.getElementById('settings-state').textContent = data.curseforge_configured ? 'CurseForge key configured.' : 'CurseForge key not configured.';
}
async function endPage() {
  await fetch('/api/end', {method:'POST'});
  document.body.innerHTML = '<main><h1>Download page ended</h1><p>You can close this tab. Run <b>mc -s mods</b> or <b>mc -s plugins</b> to open it again.</p></main>';
}
function escapeHtml(value) { return value.replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'}[char])); }
refreshFiles();
loadCustom();
loadSettings();
</script>
</body>
</html>"""


def main():
    global SERVER
    SERVER = ThreadingHTTPServer(("127.0.0.1", PORT), ManagerHandler)
    print(f"Minecraft manager running at http://127.0.0.1:{PORT}", flush=True)
    try:
        SERVER.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        SERVER.server_close()


if __name__ == "__main__":
    main()
