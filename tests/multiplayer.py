"""Real ENet processes: capacity, complete snapshots, clean disconnects.
No simulated peer transport. All logs retained in /tmp/fieldlab-network.
"""
import os, pathlib, subprocess, time
ROOT = pathlib.Path(__file__).resolve().parents[1]
LOGS = pathlib.Path('/tmp/fieldlab-network')
LOGS.mkdir(exist_ok=True)
env = dict(os.environ)
for key, suffix in [('XDG_DATA_HOME','data'),('XDG_CONFIG_HOME','config'),('XDG_CACHE_HOME','cache')]:
    env.setdefault(key, f'/tmp/fieldlab-{suffix}')
    pathlib.Path(env[key]).mkdir(exist_ok=True, parents=True)
processes = []
def launch(name, *args):
    path = LOGS / f'{name}.log'
    f = path.open('w')
    p = subprocess.Popen(['godot', '--headless', '--path', str(ROOT), '--', '--smoke', '--port=24679', *args], stdout=f, stderr=subprocess.STDOUT, env=env)
    processes.append((name,p,f,path))
    return p
try:
    launch('host', '--host', '--duration=15')
    time.sleep(1)
    launch('client1', '--join', '--duration=8')
    launch('client2', '--join', '--duration=8')
    time.sleep(2)
    launch('late_client', '--join', '--duration=9')
    time.sleep(1)
    launch('fifth', '--join', '--duration=8')
    for name,p,f,path in processes:
        p.wait(timeout=25)
        f.close()
        output = path.read_text()
        print(f'--- {name} exit={p.returncode} ---\n{output}')
        assert 'SCRIPT ERROR' not in output and 'ERROR:' not in output, name
        if name == 'fifth':
            assert p.returncode == 2 and 'SMOKE_NOT_CONNECTED' in output, name
        else:
            assert p.returncode == 0 and 'invariants=[]' in output and 'SMOKE_RESULT' in output, name
            assert 'PROBE_RESULT passed=true peak_players=4' in output, name
    print('NETWORK_RESULT passed: four connected processes; fifth rejected; snapshots and invariants checked')
finally:
    for _,p,f,_ in processes:
        if p.poll() is None: p.terminate()
        f.close()
