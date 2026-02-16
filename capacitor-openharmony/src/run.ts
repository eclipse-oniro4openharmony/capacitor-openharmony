import { spawn, execSync, exec } from 'child_process';
import { join } from 'path';
import { existsSync } from 'fs';

export async function run(target: string = 'default') {
    const projectRoot = process.env.CAPACITOR_ROOT_DIR || process.cwd();
    const ohosRoot = join(projectRoot, 'openharmony');

    if (!existsSync(ohosRoot)) {
        console.error('OpenHarmony platform not found. Run "npx cap add openharmony" first.');
        return;
    }

    console.log('Starting OpenHarmony build & run...');

    try {
        // 1. Build
        console.log('Building Hap...');

        // Check for local hvigorw, otherwise use global
        let hvigorwc = 'hvigorw';
        const localHvigorw = join(ohosRoot, 'hvigorw');
        if (existsSync(localHvigorw)) {
            hvigorwc = localHvigorw;
            try { execSync(`chmod +x ${hvigorwc}`); } catch (e) { }
        }

        const buildCmd = spawn(hvigorwc, ['assembleHap', '--mode', 'module', '-p', 'product=default', '-p', 'module=entry', '-p', 'buildMode=debug', '--no-daemon'], {
            cwd: ohosRoot,
            stdio: 'inherit'
        });

        await new Promise<void>((resolve, reject) => {
            buildCmd.on('close', (code) => {
                if (code === 0) resolve();
                else reject(new Error(`Build failed with code ${code}`));
            });
        });

        // 2. Install
        console.log('Installing Hap...');
        const hapPath = join(ohosRoot, 'entry/build/default/outputs/default/entry-default-signed.hap');
        execSync(`hdc install ${hapPath}`, { stdio: 'inherit' });

        // 3. Clear Logs & Start
        console.log('Starting App...');
        // We need the bundle ID. Read from app.json5 or config
        // For now hardcoded default from template or read from config if possible
        // TODO: Read bundle ID from AppScope/app.json5
        // Assume default for now or pass as arg
        const bundleId = 'org.oniroproject.ionicohos'; // fast hack, real implementation needs to read it

        execSync(`hdc shell hilog -r`); // clear logs
        execSync(`hdc shell aa start -a EntryAbility -b ${bundleId}`);

        // 4. Log Stream
        console.log('Streaming logs...');
        // tiny delay
        await new Promise(r => setTimeout(r, 2000));

        // Get PID
        const pidCmd = execSync(`hdc shell ps -ef | grep "${bundleId}" | grep -v grep | awk '{print $2}'`).toString().trim();
        if (!pidCmd) {
            console.error('Could not find app PID.');
            return;
        }
        console.log(`Attached to PID: ${pidCmd}`);

        const logCmd = spawn('hdc', ['shell', 'hilog', '-P', pidCmd], { stdio: 'inherit' });

        logCmd.on('close', (code) => {
            console.log('Log stream ended.');
        });

    } catch (e: any) {
        console.error('Error running OpenHarmony app:', e.message);
    }
}
