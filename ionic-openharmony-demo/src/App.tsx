import { useState, useEffect } from 'react'
import './App.css'
import { Device } from '@capacitor/device';
import { Network } from '@capacitor/network';
import { App as CapacitorApp } from '@capacitor/app';
import { Browser } from '@capacitor/browser';
import { Filesystem, Directory, Encoding } from '@capacitor/filesystem';

function App() {
    const [count, setCount] = useState(0)
    const [deviceInfo, setDeviceInfo] = useState<any>(null);
    const [networkStatus, setNetworkStatus] = useState<any>(null);
    const [fileContent, setFileContent] = useState<string>('');

    useEffect(() => {
        console.log("App Mounted - Checking Plugins");

        Device.getInfo().then(info => {
            setDeviceInfo(info);
            console.log('Device Info:', JSON.stringify(info));
        }).catch(err => {
            console.error('Error getting device info:', err);
        });

        Network.getStatus().then(status => {
            setNetworkStatus(status);
            console.log('Network Status:', JSON.stringify(status));
        }).catch(err => {
            console.error('Error getting network status:', err);
        });

        Network.addListener('networkStatusChange', (status) => {
            console.log('Network status changed', status);
            setNetworkStatus(status);
        });

        CapacitorApp.addListener('appStateChange', ({ isActive }) => {
            console.log('App state changed. Is active?', isActive);
        });

        CapacitorApp.addListener('appUrlOpen', (data) => {
            console.log('App opened with URL:', data.url);
        });

    }, []);

    const fetchInfo = () => {
        console.log("Manual Device Info Fetch");
        Device.getInfo().then(info => {
            setDeviceInfo(info);
        });
    };

    const exitApp = () => {
        CapacitorApp.exitApp();
    };

    const openBrowser = async () => {
        await Browser.open({ url: 'https://capacitorjs.com/' });
    };

    const testFilesystem = async () => {
        try {
            console.log("Testing Filesystem...");
            const fileName = 'test.txt';
            const content = 'Hello from OpenHarmony! ' + new Date().toISOString();

            console.log("Writing file...");
            await Filesystem.writeFile({
                path: fileName,
                data: content,
                directory: Directory.Data,
                encoding: Encoding.UTF8
            });
            console.log("File written");

            console.log("Reading file...");
            const result = await Filesystem.readFile({
                path: fileName,
                directory: Directory.Data,
                encoding: Encoding.UTF8
            });
            console.log("File read success:", result.data);
            setFileContent(result.data as string);

            console.log("Stat file...");
            const stats = await Filesystem.stat({
                path: fileName,
                directory: Directory.Data
            });
            console.log("File stats:", JSON.stringify(stats));

        } catch (err) {
            console.error('Filesystem test failed:', err);
            setFileContent('Error: ' + JSON.stringify(err));
        }
    };

    const testDocumentsPicker = async () => {
        try {
            console.log("Testing Documents Picker...");
            const fileName = 'hello-openharmony.txt';
            const content = 'This file was saved via DocumentViewPicker! at ' + new Date().toISOString();

            console.log("Writing file to DOCUMENTS...");
            const result = await Filesystem.writeFile({
                path: fileName,
                data: content,
                directory: Directory.Documents,
                encoding: Encoding.UTF8
            });
            console.log("File written to DOCUMENTS via picker. URI:", result.uri);
            setFileContent('Saved to: ' + result.uri);

        } catch (err) {
            console.error('Documents picker test failed:', err);
            setFileContent('Picker Error: ' + JSON.stringify(err));
        }
    };

    return (
        <>
            <h1>Ionic OpenHarmony</h1>
            <div className="card">
                <button onClick={() => setCount((count) => count + 1)}>
                    count is {count}
                </button>
            </div>

            <div className="card">
                <h2>App Plugin</h2>
                <button onClick={exitApp}>Exit App</button>
            </div>

            <div className="card">
                <h2>Browser Plugin</h2>
                <button onClick={openBrowser}>Open Browser</button>
            </div>

            <div className="card">
                <h2>Network Plugin</h2>
                <p>Status: {networkStatus ? (networkStatus.connected ? 'Connected' : 'Disconnected') : 'Loading...'}</p>
                <p>Type: {networkStatus ? networkStatus.connectionType : '-'}</p>
            </div>

            <div className="card">
                <h2>Filesystem Plugin</h2>
                <div style={{ display: 'flex', gap: '10px', justifyContent: 'center', flexWrap: 'wrap' }}>
                    <button onClick={testFilesystem}>Test Filesystem (Data)</button>
                    <button onClick={testDocumentsPicker}>Test Save to Documents (Picker)</button>
                </div>
                <p style={{ fontSize: '12px', wordBreak: 'break-all' }}>
                    Content: {fileContent || 'No content yet'}
                </p>
            </div>

            <div className="card">
                <h2>Device Plugin</h2>
                {deviceInfo ? (
                    <>
                        <pre style={{ textAlign: 'left', fontSize: '10px' }}>
                            {JSON.stringify(deviceInfo, null, 2)}
                        </pre>
                        <button onClick={fetchInfo}>Refresh Info</button>
                    </>
                ) : (
                    <p>Loading device info...</p>
                )}
            </div>
        </>
    )
}

export default App
