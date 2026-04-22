importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCTYINIDykTbeH3n8Jg9p287Zi-JL1hpO8",
  projectId: "maatha-7193c",
  messagingSenderId: "1052612162492",
  appId: "1:1052612162492:web:9b081bdca6e7782f32b1b9"
});

const messaging = firebase.messaging();