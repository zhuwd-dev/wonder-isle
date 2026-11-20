import os,sys,functools,threading,subprocess,tempfile,time
from pathlib import Path
from http.server import ThreadingHTTPServer,SimpleHTTPRequestHandler
sys.path.insert(0,'tools')
from playwright.sync_api import sync_playwright
from browser_navigation import Navigator
from test_web_preview import inject_save_fixture
from web_save_namespace import SAVE_KEY
root=Path(__file__).resolve().parent.parent; build=Path(os.environ.get('WONDER_ISLE_WEB_BUILD', root/'build/web')).resolve()
server=ThreadingHTTPServer(('127.0.0.1',0),functools.partial(SimpleHTTPRequestHandler,directory=str(build))); threading.Thread(target=server.serve_forever,daemon=True).start()
with tempfile.TemporaryDirectory() as td:
 fixture=Path(td)/'q005.json';subprocess.run([os.environ.get('GODOT_BIN','/tmp/wonder-isle-godot-4.7.2/Godot_v4.7.2-stable_linux.x86_64'),'--headless','--path',str(root),'--script','tests/create_q005_web_save.gd','--',str(fixture)],check=True,stdout=subprocess.DEVNULL)
 with sync_playwright() as p:
  b=p.chromium.launch(headless=True,executable_path='/usr/bin/chromium');page=b.new_page(viewport={'width':1280,'height':720},service_workers='block');nav=Navigator(page,(build/'index.html').read_text());page.goto(f'http://127.0.0.1:{server.server_port}/index.html?test_telemetry=1');page.locator('#status').wait_for(state='detached',timeout=90000);inject_save_fixture(page,SAVE_KEY,fixture);nav.state=None;print('initial',nav.position(),flush=True)
  for i in range(int(os.environ.get('BRIDGE_ROUNDS','20'))):
    nav.go(('y',339),('x',770))
    if i == 0: page.screenshot(path=os.environ.get('BRIDGE_SCREENSHOT','/tmp/wonder-isle-bridge-repro.png'))
    nav.go(('x',960))
    right=nav.position(); assert right['x']>950 and right['bridge'] is True,(i,right)
    nav.go(('y',339),('x',300),('y',500))
    left=nav.position(); assert left['x']<320 and left['bridge'] is True,(i,left)
    print('PASS bridge round-trip',i+1,right['x'],left['x'],flush=True)
  page.screenshot(path=os.environ.get('BRIDGE_SCREENSHOT','/tmp/wonder-isle-bridge-repro.png')); b.close()
server.shutdown()
