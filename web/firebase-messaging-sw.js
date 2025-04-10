importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

// Initialize Firebase with your config
firebase.initializeApp({
  apiKey: "YOUR_API_KEY",  // Replace with your API key
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",  // Replace with your project ID
  projectId: "YOUR_PROJECT_ID",  // Replace with your project ID
  storageBucket: "YOUR_PROJECT_ID.appspot.com",  // Replace with your storage bucket ID
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",  // Replace with your messaging sender ID
  appId: "YOUR_APP_ID"  // Replace with your app ID
});

// Initialize Firebase Messaging
const messaging = firebase.messaging();

// Background message handler
messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);

  // Show notification using the payload data
  self.registration.showNotification(
    payload.notification.title,
    {
      body: payload.notification.body,
      icon: "/icons/icon-192x192.png",  // Ensure the icon path is correct
    }
  );
});

// Add an event listener for fetch errors (optional but good for debugging)
self.addEventListener('fetch', function(event) {
  console.log('Fetch request: ', event.request);
});
