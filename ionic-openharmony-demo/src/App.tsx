import { useState, useEffect } from 'react'
import './App.css'
import { Device } from '@capacitor/device';
import { Network } from '@capacitor/network';
import { App as CapacitorApp } from '@capacitor/app';

function App() {
    const [count, setCount] = useState(0)
    const [deviceInfo, setDeviceInfo] = useState<any>(null);
    const [networkStatus, setNetworkStatus] = useState<any>(null);

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
                <h2>Network Plugin</h2>
                <p>Status: {networkStatus ? (networkStatus.connected ? 'Connected' : 'Disconnected') : 'Loading...'}</p>
                <p>Type: {networkStatus ? networkStatus.connectionType : '-'}</p>
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
