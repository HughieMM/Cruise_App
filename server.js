const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const { v4: uuidv4 } = require('uuid');
const bodyParser = require('body-parser');
const cors = require('cors');
const path = require('path');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// In-memory data storage (in production, use a real database)
const users = new Map();
const conversations = new Map();
const messages = new Map();

// WebSocket connections by user ID
const connections = new Map();

// API Routes

// Get all users
app.get('/api/users', (req, res) => {
  const userList = Array.from(users.values()).map(user => ({
    id: user.id,
    name: user.name,
    role: user.role,
    status: user.status
  }));
  res.json(userList);
});

// Create/Login user
app.post('/api/users/login', (req, res) => {
  const { name, role } = req.body;

  if (!name || !role) {
    return res.status(400).json({ error: 'Name and role are required' });
  }

  const userId = uuidv4();
  const user = {
    id: userId,
    name,
    role, // 'passenger' or 'crew'
    status: 'online',
    createdAt: new Date()
  };

  users.set(userId, user);
  res.json(user);
});

// Get conversations for a user
app.get('/api/conversations/:userId', (req, res) => {
  const { userId } = req.params;

  const userConversations = Array.from(conversations.values())
    .filter(conv => conv.participants.includes(userId))
    .map(conv => {
      const lastMessage = Array.from(messages.values())
        .filter(msg => msg.conversationId === conv.id)
        .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))[0];

      return {
        ...conv,
        lastMessage: lastMessage || null
      };
    });

  res.json(userConversations);
});

// Create a new conversation
app.post('/api/conversations', (req, res) => {
  const { participants, title } = req.body;

  if (!participants || participants.length < 2) {
    return res.status(400).json({ error: 'At least 2 participants required' });
  }

  const conversationId = uuidv4();
  const conversation = {
    id: conversationId,
    participants,
    title: title || 'New Conversation',
    createdAt: new Date()
  };

  conversations.set(conversationId, conversation);

  // Notify all participants
  participants.forEach(participantId => {
    const ws = connections.get(participantId);
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'new_conversation',
        conversation
      }));
    }
  });

  res.json(conversation);
});

// Get messages for a conversation
app.get('/api/conversations/:conversationId/messages', (req, res) => {
  const { conversationId } = req.params;

  const conversationMessages = Array.from(messages.values())
    .filter(msg => msg.conversationId === conversationId)
    .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

  res.json(conversationMessages);
});

// Send a message (REST endpoint)
app.post('/api/messages', (req, res) => {
  const { conversationId, senderId, content } = req.body;

  if (!conversationId || !senderId || !content) {
    return res.status(400).json({ error: 'Missing required fields' });
  }

  const conversation = conversations.get(conversationId);
  if (!conversation) {
    return res.status(404).json({ error: 'Conversation not found' });
  }

  const messageId = uuidv4();
  const message = {
    id: messageId,
    conversationId,
    senderId,
    content,
    timestamp: new Date(),
    status: 'sent'
  };

  messages.set(messageId, message);

  // Broadcast to all participants via WebSocket
  conversation.participants.forEach(participantId => {
    const ws = connections.get(participantId);
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'new_message',
        message
      }));
    }
  });

  res.json(message);
});

// WebSocket connection handling
wss.on('connection', (ws) => {
  console.log('New WebSocket connection');

  let userId = null;

  ws.on('message', (data) => {
    try {
      const parsed = JSON.parse(data);

      switch (parsed.type) {
        case 'authenticate':
          userId = parsed.userId;
          connections.set(userId, ws);

          // Update user status
          const user = users.get(userId);
          if (user) {
            user.status = 'online';
            broadcastUserStatus(userId, 'online');
          }

          ws.send(JSON.stringify({
            type: 'authenticated',
            userId
          }));
          break;

        case 'send_message':
          const { conversationId, senderId, content } = parsed;
          const conversation = conversations.get(conversationId);

          if (conversation) {
            const messageId = uuidv4();
            const message = {
              id: messageId,
              conversationId,
              senderId,
              content,
              timestamp: new Date(),
              status: 'sent'
            };

            messages.set(messageId, message);

            // Broadcast to all participants
            conversation.participants.forEach(participantId => {
              const participantWs = connections.get(participantId);
              if (participantWs && participantWs.readyState === WebSocket.OPEN) {
                participantWs.send(JSON.stringify({
                  type: 'new_message',
                  message
                }));
              }
            });
          }
          break;

        case 'typing':
          const typingConversation = conversations.get(parsed.conversationId);
          if (typingConversation) {
            typingConversation.participants.forEach(participantId => {
              if (participantId !== parsed.userId) {
                const participantWs = connections.get(participantId);
                if (participantWs && participantWs.readyState === WebSocket.OPEN) {
                  participantWs.send(JSON.stringify({
                    type: 'user_typing',
                    userId: parsed.userId,
                    conversationId: parsed.conversationId,
                    isTyping: parsed.isTyping
                  }));
                }
              }
            });
          }
          break;
      }
    } catch (error) {
      console.error('Error processing message:', error);
    }
  });

  ws.on('close', () => {
    if (userId) {
      connections.delete(userId);
      const user = users.get(userId);
      if (user) {
        user.status = 'offline';
        broadcastUserStatus(userId, 'offline');
      }
    }
    console.log('WebSocket connection closed');
  });
});

// Helper function to broadcast user status
function broadcastUserStatus(userId, status) {
  connections.forEach((ws, connectedUserId) => {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({
        type: 'user_status',
        userId,
        status
      }));
    }
  });
}

// Serve the frontend
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Cruise App Messaging Server running on port ${PORT}`);
  console.log(`Open http://localhost:${PORT} in your browser`);
});
