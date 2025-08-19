import React, { useEffect, useState } from 'react';

function Download({ fileId }) {
    const [message, setMessage] = useState('');
    const [websocket, setWebsocket] = useState(null);

    const connectWebSocket = () => {
        const ws = new WebSocket(`wss://40nrw5iine.execute-api.us-east-1.amazonaws.com/dev/?fileId=${fileId}`);
        
        ws.onopen = () => {
            console.log('WebSocket connection established');
        };

        ws.onmessage = (event) => {
            console.log('Message: ', event.data);
            setMessage(event.data);
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

    return (
        <div>
            {message && <p>Message from server: {message}</p>}
        </div>
    );
}

export default Download;