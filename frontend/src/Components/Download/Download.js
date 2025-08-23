import React, { useEffect, useState } from 'react';
import './Download.css';

function Download({ fileId }) {
    const [url, setUrl] = useState('');
    const [websocket, setWebsocket] = useState(null);

    const connectWebSocket = () => {
        const ws = new WebSocket(`wss://40nrw5iine.execute-api.us-east-1.amazonaws.com/dev/?fileId=${fileId}`);
        
        ws.onopen = () => {
            console.log('WebSocket connection established');
        };

        ws.onmessage = (event) => {
            console.log('Message: ', event.data);
            try {
                setUrl(JSON.parse(event.data).url);
            }
            catch (e) {
                console.error('Error parsing message:', e);
            }
        };

        ws.onclose = () => {
            console.log('WebSocket connection closed');
        };

        ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };

        setWebsocket(ws);
    }

    //Connect on mount
    useEffect(() => {
        connectWebSocket();

        return () => {
            if (websocket) {
                websocket.close(); // Cleanup on unmount
            }
        };
    }, [fileId]); 

    const openLink = () => {
        if (url) {
            window.open(url, '_blank');
        }
    }

    return (
            url && <button className="download-button" onClick={openLink}>Your transcription is ready!</button>
    );
}

export default Download;