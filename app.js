const express = require('express');
const axios = require('axios');

const app = express();
const PORT = 8080;

app.use(express.json());
app.use(express.static('public'));

app.post('/chat', async (req, res) => {
    const defaultMessage = "What is the meaning of life?";
    const defaultModel = "deepseek-r1:8b";
    
    const { user_message = defaultMessage, model_name = defaultModel } = req.body;

    const payload = {
        model: model_name,
        messages: [{ role: "user", content: user_message }],
        stream: false
    };

    try {
        const response = await axios.post('http://localhost:11434/api/chat', payload);
        res.json(response.data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.get('/health', async (req, res) => {
    try {
        const response = await axios.get('http://localhost:11434/api/tags', { timeout: 5000 });
        res.json({ status: 'healthy', ollama: 'running' });
    } catch (error) {
        res.status(503).json({ status: 'unhealthy', error: error.message });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
