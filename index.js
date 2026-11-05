const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server);

const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
    res.status(200).json({ status: 'online', service: 'Core System Management Hub' });
});

io.on('connection', (socket) => {
    console.log(`[+] Client connected: ${socket.id}`);
    
    socket.on('disconnect', () => {
        console.log(`[-] Client disconnected: ${socket.id}`);
    });
});

server.listen(PORT, () => {
    console.log(`[+] System Core Server running on port ${PORT}`);
});
