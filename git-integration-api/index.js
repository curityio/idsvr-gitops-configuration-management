const http = require('http');
const port = 3000;

const server = http.createServer((req, res) => {

    console.log('API called');
    const auth = req.headers['authorization'];

    const message = `API Received request with auth header: ${auth}`;
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({message}));
});

server.listen(port, () => {
    console.log(`Server listening on port ${port}`);
});