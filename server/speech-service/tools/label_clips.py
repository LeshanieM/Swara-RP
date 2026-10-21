"""Clip labelling for the C1 child test set (UCLASS or the team's own Sinhala recordings).

Each rater labels the same 3-second clips independently, in their own file. Then
notebooks/c1_04_children.ipynb measures their agreement (Cohen's κ) and uses the clips they agree on.

    .venv/bin/python tools/label_clips.py --clips data/uclass_label_set --rater A    # then open http://localhost:8090
    .venv/bin/python tools/label_clips.py --clips data/uclass_label_set --rater B --port 8091

Labels (same as SEP-28k and the service): block, prolongation, sound repetition, word repetition, interjection;
"fluent" when none apply; "unusable" for clips that can't be judged (no child speech, noise, adult speaking).
Keys: 1–5 toggle the labels, F fluent, U unusable, space replay, Enter save and next, ← back.
Answers are saved after every clip in labels_<rater>.csv next to the clips, so labelling can stop and resume.
Standard library only.
"""
import argparse
import csv
import html
import json
import mimetypes
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

LABELS = ("block", "prolongation", "sound_repetition", "word_repetition", "interjection")
FIELDS = ["clip", *LABELS, "fluent", "unusable", "notes"]

PAGE = """<!doctype html><html><head><meta charset="utf-8"><title>C1 clip labelling</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
 body{font-family:system-ui,sans-serif;max-width:640px;margin:24px auto;padding:0 16px;color:#1d2433;background:#fafaf7}
 h1{font-size:20px} .meta{color:#667;font-size:13px} label{display:block;padding:8px 10px;margin:6px 0;border:1px solid #ccd;border-radius:8px;background:#fff;cursor:pointer}
 label:has(input:checked){background:#e7f0ff;border-color:#3b6fd8} kbd{background:#eee;border-radius:4px;padding:1px 5px;font-size:12px}
 button{font-size:15px;padding:8px 16px;margin-right:8px;border-radius:8px;border:1px solid #889;background:#fff;cursor:pointer}
 button.primary{background:#3b6fd8;color:#fff;border-color:#3b6fd8} .bar{height:6px;background:#dde;border-radius:3px;margin:12px 0}
 .bar div{height:6px;background:#3b6fd8;border-radius:3px} textarea{width:100%;box-sizing:border-box}
</style></head><body>
<h1>Clip <span id="pos"></span> of <span id="total"></span> · rater <b>__RATER__</b></h1>
<div class="bar"><div id="progress"></div></div>
<p class="meta" id="meta"></p>
<audio id="player" controls autoplay style="width:100%"></audio>
<form id="f">
 <label><input type="checkbox" name="block"> <kbd>1</kbd> Block (silent or tense stop, gasp)</label>
 <label><input type="checkbox" name="prolongation"> <kbd>2</kbd> Prolongation (sssound held)</label>
 <label><input type="checkbox" name="sound_repetition"> <kbd>3</kbd> Sound / syllable repetition (b-b-ball)</label>
 <label><input type="checkbox" name="word_repetition"> <kbd>4</kbd> Word repetition (I-I-I want)</label>
 <label><input type="checkbox" name="interjection"> <kbd>5</kbd> Interjection (um, uh)</label>
 <label><input type="checkbox" name="fluent"> <kbd>F</kbd> Fluent: none of the above</label>
 <label><input type="checkbox" name="unusable"> <kbd>U</kbd> Unusable: no child speech, noise, adult speaking</label>
 <textarea name="notes" rows="2" placeholder="notes (optional)"></textarea>
</form>
<p><button onclick="go(-1)">← Back</button><button class="primary" onclick="save()">Save and next ⏎</button></p>
<p class="meta">Keys: <kbd>1</kbd>–<kbd>5</kbd> labels, <kbd>F</kbd> fluent, <kbd>U</kbd> unusable, <kbd>space</kbd> replay, <kbd>Enter</kbd> save and next.</p>
<script>
let clips=[], answers={}, i=0;
const LABELS=__LABELS__;
async function load(){const r=await fetch('state');const s=await r.json();clips=s.clips;answers=s.answers;
 i=clips.findIndex(c=>!answers[c.clip]); if(i<0)i=clips.length-1; show();}
function show(){const c=clips[i];document.getElementById('pos').textContent=i+1;document.getElementById('total').textContent=clips.length;
 document.getElementById('progress').style.width=(100*Object.keys(answers).length/clips.length)+'%';
 document.getElementById('meta').textContent=[c.clip,c.ageYears?('age '+c.ageYears):'',c.source||''].filter(Boolean).join(' · ');
 const p=document.getElementById('player');p.src='clip/'+encodeURIComponent(c.clip);p.play().catch(()=>{});
 const a=answers[c.clip]||{};const f=document.getElementById('f');
 for(const n of [...LABELS,'fluent','unusable'])f[n].checked=a[n]==='1';f.notes.value=a.notes||'';}
async function save(){const f=document.getElementById('f');const a={clip:clips[i].clip,notes:f.notes.value};
 for(const n of [...LABELS,'fluent','unusable'])a[n]=f[n].checked?'1':'0';
 const any=LABELS.some(n=>a[n]==='1');
 if(!any&&a.fluent==='0'&&a.unusable==='0'){alert('Choose at least one label, Fluent, or Unusable.');return;}
 if(any&&a.fluent==='1'){alert('A clip with a disfluency is not fluent.');return;}
 await fetch('save',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(a)});
 answers[a.clip]=a; if(i<clips.length-1){i++;show();} else {alert('All clips are labelled. Thank you!');show();}}
function go(d){i=Math.max(0,Math.min(clips.length-1,i+d));show();}
document.addEventListener('keydown',e=>{if(e.target.tagName==='TEXTAREA')return;const f=document.getElementById('f');
 const k=e.key.toLowerCase();if('12345'.includes(k)&&k){f[LABELS[+k-1]].checked=!f[LABELS[+k-1]].checked;}
 else if(k==='f')f.fluent.checked=!f.fluent.checked; else if(k==='u')f.unusable.checked=!f.unusable.checked;
 else if(k===' '){e.preventDefault();const p=document.getElementById('player');p.currentTime=0;p.play();}
 else if(k==='enter'){e.preventDefault();save();} else if(k==='arrowleft')go(-1);});
load();
</script></body></html>"""


def make_handler(clip_dir: Path, rater: str):
    labels_file = clip_dir / f"labels_{rater}.csv"
    audio_dir = clip_dir / "clips" if (clip_dir / "clips").is_dir() else clip_dir
    manifest = clip_dir / "manifest.csv"
    if manifest.exists():
        with open(manifest, newline="", encoding="utf-8") as fh:
            clips = list(csv.DictReader(fh))
    else:
        clips = [{"clip": p.name} for p in sorted(audio_dir.glob("*.wav"))]
    if not clips:
        raise SystemExit(f"No clips found in {audio_dir}")

    def read_answers() -> dict:
        if not labels_file.exists():
            return {}
        with open(labels_file, newline="", encoding="utf-8") as fh:
            return {row["clip"]: row for row in csv.DictReader(fh)}

    def write_answers(answers: dict) -> None:
        tmp = labels_file.with_suffix(".tmp")
        with open(tmp, "w", newline="", encoding="utf-8") as fh:
            w = csv.DictWriter(fh, fieldnames=FIELDS)
            w.writeheader()
            for c in clips:  # keep manifest order
                if c["clip"] in answers:
                    w.writerow({k: answers[c["clip"]].get(k, "") for k in FIELDS})
        tmp.replace(labels_file)

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def _send(self, body: bytes, ctype: str, status: int = 200):
            self.send_response(status)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if self.path in ("/", "/index.html"):
                page = PAGE.replace("__RATER__", html.escape(rater)).replace("__LABELS__", json.dumps(LABELS))
                return self._send(page.encode(), "text/html; charset=utf-8")
            if self.path == "/state":
                return self._send(json.dumps({"clips": clips, "answers": read_answers()}).encode(), "application/json")
            if self.path.startswith("/clip/"):
                from urllib.parse import unquote
                name = Path(unquote(self.path[len("/clip/"):])).name  # no path traversal
                f = audio_dir / name
                if f.is_file():
                    return self._send(f.read_bytes(), mimetypes.guess_type(f.name)[0] or "audio/wav")
            self._send(b"not found", "text/plain", 404)

        def do_POST(self):
            if self.path != "/save":
                return self._send(b"not found", "text/plain", 404)
            body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
            if body.get("clip") not in {c["clip"] for c in clips}:
                return self._send(b"unknown clip", "text/plain", 400)
            answers = read_answers()
            answers[body["clip"]] = {k: str(body.get(k, "")) for k in FIELDS}
            write_answers(answers)
            self._send(b"{}", "application/json")

    return Handler, labels_file, len(clips)


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--clips", type=Path, required=True, help="folder with manifest.csv and clips/ (from uclass.prepare_label_set)")
    ap.add_argument("--rater", required=True, help="short rater name, e.g. A or B; each rater gets their own file")
    ap.add_argument("--port", type=int, default=8090)
    args = ap.parse_args()
    handler, labels_file, n = make_handler(args.clips, args.rater)
    print(f"{n} clips · saving to {labels_file} · open http://localhost:{args.port}")
    ThreadingHTTPServer(("127.0.0.1", args.port), handler).serve_forever()


if __name__ == "__main__":
    main()
