#!/usr/bin/env python3
"""Local-only Godot Web stability soak. Captures browser and WebGL diagnostics."""
from __future__ import annotations
import argparse, functools, json, os, platform, subprocess, time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from playwright.sync_api import sync_playwright

class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *_args): pass

def descendants(root_pid: int) -> list[int]:
    try:
        rows = subprocess.check_output(['ps','-eo','pid=,ppid=,rss='],text=True).splitlines()
    except Exception:
        return []
    parents: dict[int,list[int]] = {}
    rss: dict[int,int] = {}
    for row in rows:
        bits=row.split()
        if len(bits)!=3: continue
        pid,ppid,size=map(int,bits); parents.setdefault(ppid,[]).append(pid); rss[pid]=size
    result=[]; stack=[root_pid]
    while stack:
        parent=stack.pop()
        for child in parents.get(parent,[]):
            result.append(child); stack.append(child)
    return result

def process_metrics(root_pid: int) -> dict[str,int]:
    pids=descendants(root_pid)
    try:
        rows=subprocess.check_output(['ps','-eo','pid=,rss='],text=True).splitlines()
        rss={int(row.split()[0]):int(row.split()[1]) for row in rows if len(row.split())==2}
    except Exception:
        rss={}
    return {'processes':len(pids),'rss_kib':sum(rss.get(pid,0) for pid in pids)}

def main() -> None:
    ap=argparse.ArgumentParser()
    ap.add_argument('build_dir',type=Path)
    ap.add_argument('--idle-seconds',type=int,default=1800)
    ap.add_argument('--active-seconds',type=int,default=1200)
    ap.add_argument('--sample-seconds',type=int,default=60)
    ap.add_argument('--output',type=Path,default=Path('/tmp/wonder-isle-web-stability.jsonl'))
    ap.add_argument('--artifacts',type=Path,default=Path('/tmp/wonder-isle-web-stability-artifacts'))
    args=ap.parse_args(); args.build_dir=args.build_dir.resolve(); args.output=args.output.resolve(); args.artifacts=args.artifacts.resolve()
    args.output.parent.mkdir(parents=True,exist_ok=True); args.artifacts.mkdir(parents=True,exist_ok=True)
    server=ThreadingHTTPServer(('127.0.0.1',0),functools.partial(QuietHandler,directory=str(args.build_dir)))
    import threading
    threading.Thread(target=server.serve_forever,daemon=True).start()
    log=args.output.open('w',encoding='utf-8')
    def record(value):
        log.write(json.dumps(value,ensure_ascii=False)+'\n'); log.flush(); print(json.dumps(value,ensure_ascii=False),flush=True)
    errors=[]; reloads=0
    with sync_playwright() as p:
        browser=p.chromium.launch(headless=True,executable_path=os.environ.get('CHROMIUM_PATH','/usr/bin/chromium'),args=['--no-sandbox','--disable-dev-shm-usage'])
        driver_pid=browser._impl_obj._connection._transport._proc.pid
        context=browser.new_context(viewport={'width':1280,'height':720})
        page=context.new_page()
        page.add_init_script("window.__stabilityEvents=[];document.addEventListener('webglcontextlost',e=>window.__stabilityEvents.push({type:'lost',time:performance.now()}),true);document.addEventListener('webglcontextrestored',e=>window.__stabilityEvents.push({type:'restored',time:performance.now()}),true);")
        page.on('console',lambda m: errors.append({'type':'console','text':m.text[:300]}) if m.type=='error' else None)
        page.on('pageerror',lambda e: errors.append({'type':'pageerror','text':str(e)[:300]}))
        page.on('crash',lambda: errors.append({'type':'page-crash'}))
        url=f'http://127.0.0.1:{server.server_port}/index.html'
        page.goto(url,wait_until='load',timeout=120000); page.wait_for_selector('canvas',timeout=120000); page.wait_for_timeout(10000)
        renderer=page.evaluate("""() => {const c=document.querySelector('canvas');let gl=null;try{gl=c&&c.getContext('webgl2')}catch(e){};if(!gl)return {supported:false};const d=gl.getExtension('WEBGL_debug_renderer_info');return {supported:true,vendor:d?gl.getParameter(d.UNMASKED_VENDOR_WEBGL):'',renderer:d?gl.getParameter(d.UNMASKED_RENDERER_WEBGL):'',version:gl.getParameter(gl.VERSION)}}""")
        record({'event':'start','browser':browser.version,'os':platform.platform(),'webgl':renderer,'viewport':[1280,720],'driver_pid':driver_pid,'idle_seconds':args.idle_seconds,'active_seconds':args.active_seconds})
        page.screenshot(path=str(args.artifacts/'start.png'))
        tabs=[]
        for i in range(3):
            tab=context.new_page(); tab.set_content(f'<main><h1>Ordinary tab {i+1}</h1><p>Local static content used only to keep multiple renderer tabs open.</p></main>'); tabs.append(tab)
        page.bring_to_front()
        def sample(phase,elapsed):
            proc=process_metrics(driver_pid)
            mem=page.evaluate("""() => ({heap:performance.memory?{used:performance.memory.usedJSHeapSize,total:performance.memory.totalJSHeapSize,limit:performance.memory.jsHeapSizeLimit}:null,contextEvents:window.__stabilityEvents||[],canvas:!!document.querySelector('canvas')})""")
            record({'event':'sample','phase':phase,'elapsed_seconds':elapsed,'renderer_tree':proc,'js':mem,'reloads':reloads,'errors':errors[-12:]})
        def run_phase(name,duration,active=False):
            start=time.monotonic(); end=start+duration; next_sample=start
            while time.monotonic()<end:
                elapsed=int(time.monotonic()-start)
                if active:
                    cycle=elapsed%24
                    if cycle<8: page.keyboard.down('d')
                    else: page.keyboard.up('d')
                    if 8<=cycle<16: page.keyboard.down('a')
                    else: page.keyboard.up('a')
                    if elapsed%6==0:
                        page.mouse.wheel(0,120 if (elapsed//6)%2==0 else -120)
                    if elapsed%18==1: page.mouse.click(1210,45)
                    if elapsed%18==4: page.mouse.click(760,48)
                now=time.monotonic()
                if now>=next_sample:
                    sample(name,int(now-start)); next_sample=now+args.sample_seconds
                time.sleep(min(1,max(0,end-time.monotonic())))
            page.keyboard.up('a'); page.keyboard.up('d')
            sample(name,duration)
            page.screenshot(path=str(args.artifacts/f'{name}-end.png'))
        run_phase('idle',args.idle_seconds)
        run_phase('active',args.active_seconds,True)
        for i in range(5):
            page.reload(wait_until='load',timeout=120000); reloads+=1; page.wait_for_selector('canvas',timeout=120000); page.wait_for_timeout(3000); sample('reload',i+1)
        page.screenshot(path=str(args.artifacts/'final.png'))
        record({'event':'result','reloads':reloads,'errors':errors,'artifacts':str(args.artifacts),'output':str(args.output)})
        browser.close()
    log.close(); server.shutdown(); server.server_close()
if __name__=='__main__': main()
