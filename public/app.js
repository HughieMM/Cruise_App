// Application State
const state = {
    currentUser: null,
    users: new Map(),
    conversations: new Map(),
    messages: new Map(),
    currentConversationId: null,
    ws: null
};

// DOM Elements
const loginScreen = document.getElementById('loginScreen');
const messagingScreen = document.getElementById('messagingScreen');
const loginForm = document.getElementById('loginForm');
const userNameInput = document.getElementById('userName');
const userRoleInput = document.getElementById('userRole');
const currentUserName = document.getElementById('currentUserName');
const currentUserRole = document.getElementById('currentUserRole');
const currentUserAvatar = document.getElementById('currentUserAvatar');
const conversationsList = document.getElementById('conversationsList');
const usersList = document.getElementById('usersList');
const emptyState = document.getElementById('emptyState');
const chatContent = document.getElementById('chatContent');
const chatTitle = document.getElementById('chatTitle');
const chatParticipants = document.getElementById('chatParticipants');
const messagesContainer = document.getElementById('messagesContainer');
const messageInput = document.getElementById('messageInput');
const sendMessageBtn = document.getElementById('sendMessageBtn');
const newConversationBtn = document.getElementById('newConversationBtn');
const newConversationModal = document.getElementById('newConversationModal');
const closeModalBtn = document.getElementById('closeModalBtn');
const cancelModalBtn = document.getElementById('cancelModalBtn');
const createConversationBtn = document.getElementById('createConversationBtn');
const conversationTitleInput = document.getElementById('conversationTitle');
const usersSelectionList = document.getElementById('usersSelectionList');
const typingIndicator = document.getElementById('typingIndicator');

// API Base URL
const API_URL = window.location.origin;
const WS_URL = `ws://${window.location.host}`;

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    setupEventListeners();
});

function setupEventListeners() {
    loginForm.addEventListener('submit', handleLogin);
    sendMessageBtn.addEventListener('click', sendMessage);
    messageInput.addEventListener('keypress', handleMessageInputKeypress);
    messageInput.addEventListener('input', handleTyping);
    newConversationBtn.addEventListener('click', openNewConversationModal);
    closeModalBtn.addEventListener('click', closeNewConversationModal);
    cancelModalBtn.addEventListener('click', closeNewConversationModal);
    createConversationBtn.addEventListener('click', createConversation);
}

// Login Handler
async function handleLogin(e) {
    e.preventDefault();

    const name = userNameInput.value.trim();
    const role = userRoleInput.value;

    if (!name || !role) return;

    try {
        const response = await fetch(`${API_URL}/api/users/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name, role })
        });

        const user = await response.json();
        state.currentUser = user;

        // Update UI
        currentUserName.textContent = user.name;
        currentUserRole.textContent = user.role;
        currentUserAvatar.textContent = user.name.charAt(0).toUpperCase();

        // Switch screens
        loginScreen.classList.remove('active');
        messagingScreen.classList.add('active');

        // Connect WebSocket
        connectWebSocket();

        // Load initial data
        loadUsers();
        loadConversations();

    } catch (error) {
        console.error('Login error:', error);
        alert('Failed to login. Please try again.');
    }
}

// WebSocket Connection
function connectWebSocket() {
    state.ws = new WebSocket(WS_URL);

    state.ws.onopen = () => {
        console.log('WebSocket connected');
        // Authenticate
        state.ws.send(JSON.stringify({
            type: 'authenticate',
            userId: state.currentUser.id
        }));
    };

    state.ws.onmessage = (event) => {
        const data = JSON.parse(event.data);
        handleWebSocketMessage(data);
    };

    state.ws.onclose = () => {
        console.log('WebSocket disconnected');
        // Attempt to reconnect after 3 seconds
        setTimeout(connectWebSocket, 3000);
    };

    state.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
    };
}

function handleWebSocketMessage(data) {
    switch (data.type) {
        case 'authenticated':
            console.log('WebSocket authenticated');
            break;

        case 'new_message':
            handleNewMessage(data.message);
            break;

        case 'new_conversation':
            handleNewConversation(data.conversation);
            break;

        case 'user_status':
            handleUserStatus(data.userId, data.status);
            break;

        case 'user_typing':
            handleUserTyping(data.userId, data.conversationId, data.isTyping);
            break;
    }
}

// Load Users
async function loadUsers() {
    try {
        const response = await fetch(`${API_URL}/api/users`);
        const users = await response.json();

        users.forEach(user => {
            if (user.id !== state.currentUser.id) {
                state.users.set(user.id, user);
            }
        });

        renderUsers();
    } catch (error) {
        console.error('Error loading users:', error);
    }
}

function renderUsers() {
    usersList.innerHTML = '';

    state.users.forEach(user => {
        const userItem = document.createElement('div');
        userItem.className = 'user-item';
        userItem.onclick = () => startConversationWithUser(user.id);

        userItem.innerHTML = `
            <div class="user-avatar">${user.name.charAt(0).toUpperCase()}</div>
            <div>
                <div class="user-name">${user.name}</div>
                <div class="user-role">${user.role}</div>
            </div>
            <div class="user-status ${user.status}"></div>
        `;

        usersList.appendChild(userItem);
    });
}

// Load Conversations
async function loadConversations() {
    try {
        const response = await fetch(`${API_URL}/api/conversations/${state.currentUser.id}`);
        const conversations = await response.json();

        conversations.forEach(conv => {
            state.conversations.set(conv.id, conv);
        });

        renderConversations();
    } catch (error) {
        console.error('Error loading conversations:', error);
    }
}

function renderConversations() {
    conversationsList.innerHTML = '';

    if (state.conversations.size === 0) {
        conversationsList.innerHTML = '<div style="padding: 20px; text-align: center; color: #999;">No conversations yet</div>';
        return;
    }

    state.conversations.forEach(conv => {
        const convItem = document.createElement('div');
        convItem.className = 'conversation-item';
        if (conv.id === state.currentConversationId) {
            convItem.classList.add('active');
        }

        convItem.onclick = () => selectConversation(conv.id);

        const preview = conv.lastMessage ? conv.lastMessage.content : 'No messages yet';

        convItem.innerHTML = `
            <div class="conversation-title">${conv.title}</div>
            <div class="conversation-preview">${preview}</div>
        `;

        conversationsList.appendChild(convItem);
    });
}

// Select Conversation
async function selectConversation(conversationId) {
    state.currentConversationId = conversationId;
    const conversation = state.conversations.get(conversationId);

    if (!conversation) return;

    // Update UI
    emptyState.style.display = 'none';
    chatContent.style.display = 'flex';
    chatTitle.textContent = conversation.title;

    // Get participant names
    const participantNames = conversation.participants
        .filter(id => id !== state.currentUser.id)
        .map(id => {
            const user = state.users.get(id);
            return user ? user.name : 'Unknown';
        })
        .join(', ');

    chatParticipants.textContent = `With: ${participantNames}`;

    // Load messages
    await loadMessages(conversationId);

    // Re-render conversations to update active state
    renderConversations();

    // Focus input
    messageInput.focus();
}

// Load Messages
async function loadMessages(conversationId) {
    try {
        const response = await fetch(`${API_URL}/api/conversations/${conversationId}/messages`);
        const messages = await response.json();

        messages.forEach(msg => {
            state.messages.set(msg.id, msg);
        });

        renderMessages();
    } catch (error) {
        console.error('Error loading messages:', error);
    }
}

function renderMessages() {
    messagesContainer.innerHTML = '';

    const conversationMessages = Array.from(state.messages.values())
        .filter(msg => msg.conversationId === state.currentConversationId)
        .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

    conversationMessages.forEach(msg => {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${msg.senderId === state.currentUser.id ? 'sent' : 'received'}`;

        const sender = msg.senderId === state.currentUser.id
            ? state.currentUser
            : state.users.get(msg.senderId);

        const senderName = sender ? sender.name : 'Unknown';
        const time = new Date(msg.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

        messageDiv.innerHTML = `
            <div class="message-bubble">
                ${msg.senderId !== state.currentUser.id ? `<div class="message-sender">${senderName}</div>` : ''}
                <div class="message-content">${escapeHtml(msg.content)}</div>
                <div class="message-time">${time}</div>
            </div>
        `;

        messagesContainer.appendChild(messageDiv);
    });

    // Scroll to bottom
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
}

// Send Message
function sendMessage() {
    const content = messageInput.value.trim();

    if (!content || !state.currentConversationId) return;

    // Send via WebSocket
    if (state.ws && state.ws.readyState === WebSocket.OPEN) {
        state.ws.send(JSON.stringify({
            type: 'send_message',
            conversationId: state.currentConversationId,
            senderId: state.currentUser.id,
            content
        }));

        messageInput.value = '';
        messageInput.style.height = 'auto';
    }
}

function handleMessageInputKeypress(e) {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
}

// Handle New Message from WebSocket
function handleNewMessage(message) {
    state.messages.set(message.id, message);

    // Update conversation's last message
    const conversation = state.conversations.get(message.conversationId);
    if (conversation) {
        conversation.lastMessage = message;
    }

    // If message is for current conversation, render it
    if (message.conversationId === state.currentConversationId) {
        renderMessages();
    }

    // Update conversations list
    renderConversations();
}

// Handle New Conversation
function handleNewConversation(conversation) {
    state.conversations.set(conversation.id, conversation);
    renderConversations();
}

// Handle User Status
function handleUserStatus(userId, status) {
    const user = state.users.get(userId);
    if (user) {
        user.status = status;
        renderUsers();
    }
}

// Typing Indicator
let typingTimeout;
function handleTyping() {
    if (!state.currentConversationId) return;

    clearTimeout(typingTimeout);

    // Send typing indicator
    if (state.ws && state.ws.readyState === WebSocket.OPEN) {
        state.ws.send(JSON.stringify({
            type: 'typing',
            conversationId: state.currentConversationId,
            userId: state.currentUser.id,
            isTyping: true
        }));
    }

    // Stop typing after 2 seconds of inactivity
    typingTimeout = setTimeout(() => {
        if (state.ws && state.ws.readyState === WebSocket.OPEN) {
            state.ws.send(JSON.stringify({
                type: 'typing',
                conversationId: state.currentConversationId,
                userId: state.currentUser.id,
                isTyping: false
            }));
        }
    }, 2000);
}

function handleUserTyping(userId, conversationId, isTyping) {
    if (conversationId !== state.currentConversationId) return;

    const user = state.users.get(userId);
    if (!user) return;

    if (isTyping) {
        typingIndicator.querySelector('.typing-text').textContent = `${user.name} is typing...`;
        typingIndicator.style.display = 'flex';
    } else {
        typingIndicator.style.display = 'none';
    }
}

// New Conversation Modal
function openNewConversationModal() {
    usersSelectionList.innerHTML = '';

    state.users.forEach(user => {
        const userCheckbox = document.createElement('div');
        userCheckbox.className = 'user-checkbox-item';
        userCheckbox.innerHTML = `
            <input type="checkbox" id="user-${user.id}" value="${user.id}">
            <label for="user-${user.id}" style="cursor: pointer; display: flex; align-items: center; gap: 12px; flex: 1;">
                <div class="user-avatar">${user.name.charAt(0).toUpperCase()}</div>
                <div>
                    <div class="user-name">${user.name}</div>
                    <div class="user-role">${user.role}</div>
                </div>
            </label>
        `;

        usersSelectionList.appendChild(userCheckbox);
    });

    newConversationModal.classList.add('active');
}

function closeNewConversationModal() {
    newConversationModal.classList.remove('active');
    conversationTitleInput.value = '';
}

async function createConversation() {
    const selectedUsers = Array.from(usersSelectionList.querySelectorAll('input[type="checkbox"]:checked'))
        .map(cb => cb.value);

    if (selectedUsers.length === 0) {
        alert('Please select at least one user');
        return;
    }

    const participants = [state.currentUser.id, ...selectedUsers];
    const title = conversationTitleInput.value.trim() || `Chat with ${selectedUsers.length} user(s)`;

    try {
        const response = await fetch(`${API_URL}/api/conversations`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ participants, title })
        });

        const conversation = await response.json();
        state.conversations.set(conversation.id, conversation);

        renderConversations();
        closeNewConversationModal();

        // Select the new conversation
        selectConversation(conversation.id);

    } catch (error) {
        console.error('Error creating conversation:', error);
        alert('Failed to create conversation');
    }
}

// Start conversation with a specific user
async function startConversationWithUser(userId) {
    // Check if conversation already exists
    const existingConv = Array.from(state.conversations.values())
        .find(conv =>
            conv.participants.length === 2 &&
            conv.participants.includes(userId) &&
            conv.participants.includes(state.currentUser.id)
        );

    if (existingConv) {
        selectConversation(existingConv.id);
        return;
    }

    // Create new conversation
    const user = state.users.get(userId);
    if (!user) return;

    const participants = [state.currentUser.id, userId];
    const title = `Chat with ${user.name}`;

    try {
        const response = await fetch(`${API_URL}/api/conversations`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ participants, title })
        });

        const conversation = await response.json();
        state.conversations.set(conversation.id, conversation);

        renderConversations();
        selectConversation(conversation.id);

    } catch (error) {
        console.error('Error creating conversation:', error);
    }
}

// Utility function to escape HTML
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Auto-resize textarea
messageInput.addEventListener('input', function() {
    this.style.height = 'auto';
    this.style.height = (this.scrollHeight) + 'px';
});
