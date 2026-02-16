import { useState, useEffect } from 'react'
import './App.css'
import { Device } from '@capacitor/device';

function App() {
    const [count, setCount] = useState(0)
    const [deviceInfo, setDeviceInfo] = useState<any>(null);

    useEffect(() => {
        console.log("App Mounted - Checking Device Info");

        Device.getInfo().then(info => {
            setDeviceInfo(info);
            console.log('Device Info:', JSON.stringify(info));
        }).catch(err => {
            console.error('Error getting device info:', err);
        });
    }, []);

    const fetchInfo = () => {
        console.log("Manual Device Info Fetch");
        Device.getInfo().then(info => {
            setDeviceInfo(info);
            console.log('Manual Device Info:', JSON.stringify(info));
        });
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
                <h2>Device Info</h2>
                {deviceInfo ? (
                    <>
                        <pre style={{ textAlign: 'left', fontSize: '12px' }}>
                            {JSON.stringify(deviceInfo, null, 2)}
                        </pre>
                        <button onClick={fetchInfo}>Fetch Device Info</button>
                    </>
                ) : (
                    <p>Loading device info...</p>
                )}
            </div>
        </>
    )
}

export default App
