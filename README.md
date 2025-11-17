# Cruise App - Real-Time Messaging System

A modern, real-time messaging application designed for cruise ship passengers and crew members to communicate seamlessly. Built with Node.js, Express, WebSocket, and vanilla JavaScript.

## Features

- **Real-Time Messaging**: Instant message delivery using WebSocket connections
- **User Roles**: Support for both passengers and crew members
- **One-on-One & Group Chats**: Create conversations with multiple participants
- **Typing Indicators**: See when other users are typing
- **Online Status**: Real-time user presence indicators
- **Modern UI**: Clean, responsive design with smooth animations
- **Message History**: Persistent message storage across sessions

## Tech Stack

### Backend
- **Node.js** - JavaScript runtime
- **Express** - Web application framework
- **WebSocket (ws)** - Real-time bidirectional communication
- **UUID** - Unique identifier generation

### Frontend
- **HTML5** - Semantic markup
- **CSS3** - Modern styling with animations
- **Vanilla JavaScript** - No frameworks, pure JS

## Project Structure

```
Cruise_App/
├── server.js           # Express server with WebSocket support
├── package.json        # Project dependencies
├── public/
│   ├── index.html     # Main HTML file
│   ├── styles.css     # Application styles
│   └── app.js         # Frontend JavaScript
└── README.md          # This file
```

## Installation

### Prerequisites
- Node.js (v14 or higher)
- npm (Node Package Manager)

### Setup Steps

1. **Clone or navigate to the repository**
   ```bash
   cd /path/to/Cruise_App
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Start the server**
   ```bash
   npm start
   ```

   For development with auto-reload:
   ```bash
   npm run dev
   ```

4. **Open in browser**
   ```
   http://localhost:3000
   ```

## Usage

### Getting Started

1. **Login**
   - Enter your name
   - Select your role (Passenger or Crew)
   - Click "Start Messaging"

2. **Start a Conversation**
   - Click the "+" button next to "Conversations"
   - Select one or more users
   - Optionally add a conversation title
   - Click "Create"

   Or click on any user in the "Users Online" section to start a direct chat.

3. **Send Messages**
   - Type your message in the input field
   - Press Enter or click the send button
   - Messages appear instantly for all participants

4. **Features to Try**
   - Open multiple browser tabs to simulate different users
   - Watch real-time message delivery
   - See typing indicators when someone is typing
   - Notice online/offline status changes

### API Endpoints

#### Users
- `POST /api/users/login` - Create/login a user
- `GET /api/users` - Get all users

#### Conversations
- `GET /api/conversations/:userId` - Get user's conversations
- `POST /api/conversations` - Create a new conversation
- `GET /api/conversations/:conversationId/messages` - Get conversation messages

#### Messages
- `POST /api/messages` - Send a message (REST endpoint)

### WebSocket Events

#### Client to Server
```javascript
{
  type: 'authenticate',
  userId: 'user-id'
}

{
  type: 'send_message',
  conversationId: 'conversation-id',
  senderId: 'user-id',
  content: 'message text'
}

{
  type: 'typing',
  conversationId: 'conversation-id',
  userId: 'user-id',
  isTyping: true/false
}
```

#### Server to Client
```javascript
{
  type: 'new_message',
  message: { /* message object */ }
}

{
  type: 'new_conversation',
  conversation: { /* conversation object */ }
}

{
  type: 'user_status',
  userId: 'user-id',
  status: 'online/offline'
}

{
  type: 'user_typing',
  userId: 'user-id',
  conversationId: 'conversation-id',
  isTyping: true/false
}
```

## Development

### Data Storage

Currently, the application uses in-memory storage (Maps) for:
- Users
- Conversations
- Messages
- WebSocket connections

**For Production**: Replace in-memory storage with a database like:
- MongoDB
- PostgreSQL
- Redis (for real-time data)

### Extending the Application

**Add Authentication**
```javascript
// Implement JWT tokens
// Add password hashing with bcrypt
// Create protected routes
```

**Add File Sharing**
```javascript
// Integrate file upload (multer)
// Store files in cloud storage (AWS S3, Google Cloud Storage)
// Send file messages with previews
```

**Add Message Reactions**
```javascript
// Extend message model with reactions
// Broadcast reaction updates via WebSocket
```

**Add Push Notifications**
```javascript
// Integrate web push notifications
// Notify users of new messages when offline
```

## Testing

### Multi-User Testing

1. Open the app in multiple browser tabs
2. Login with different names in each tab
3. Create conversations and send messages
4. Observe real-time updates across all tabs

### Browser Console

Monitor WebSocket activity in browser DevTools:
- Network tab > WS filter
- Console tab for debug logs

## Deployment

### Environment Variables

Create a `.env` file:
```env
PORT=3000
NODE_ENV=production
```

### Deploy to Cloud

**Heroku**
```bash
heroku create cruise-app-messaging
git push heroku main
```

**DigitalOcean, AWS, Google Cloud**
- Set up Node.js environment
- Install dependencies
- Run `npm start`
- Configure reverse proxy (nginx)

## Troubleshooting

**WebSocket Connection Failed**
- Check if server is running
- Verify WebSocket URL matches server
- Check firewall settings

**Messages Not Appearing**
- Open browser console for errors
- Verify WebSocket connection is established
- Check if user is authenticated

**Port Already in Use**
```bash
# Change port in server.js or use environment variable
PORT=3001 npm start
```

## Future Enhancements

- [ ] User authentication with JWT
- [ ] Database integration (MongoDB/PostgreSQL)
- [ ] File and image sharing
- [ ] Message editing and deletion
- [ ] Message read receipts
- [ ] User profiles with avatars
- [ ] Search functionality
- [ ] Message reactions/emojis
- [ ] Voice/video calling
- [ ] Mobile app (React Native)

## License

MIT License - Feel free to use this project for learning and commercial purposes.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions, please open an issue on the repository.

---

Built with ❤️ for cruise ship communication
