import { addOpenHarmony } from './add';
import { sync } from './sync';

export async function add(config: any) {
    await addOpenHarmony(config);
}

export async function copy(config: any) {
    await sync(config);
}

export async function update(config: any) {
    console.log('Update command not implemented yet (plugins)');
}

export async function open(config: any) {
    console.log('Open command not implemented yet (DevEco Studio)');
}
