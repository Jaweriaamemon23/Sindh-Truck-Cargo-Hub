// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/10.8.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.8.1/firebase-messaging-compat.js');

// Initialize Firebase (USE YOUR CONFIG HERE)
firebase.initializeApp({
  apiKey: "AIzaSyB8daSx_lP5pBLUqiD8LsKW2Mer2V9Jy8U",
  authDomain: "sindhtruckcargohub.firebaseapp.com",
  projectId: "sindhtruckcargohub",
  messagingSenderId: "22061893159",
  appId: "1:22061893159:web:0802de538103a6e22eb002",
});

// Initialize messaging
const messaging = firebase.messaging();
