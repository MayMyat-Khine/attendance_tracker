// Keep this version aligned with firebase_core_web in pubspec.lock.
// Configure Auth before FlutterFire waits for persisted-user initialization.
globalThis.prepareAttendanceLocalFirebase = async (options, host) => {
  const sdk = 'https://www.gstatic.com/firebasejs/12.19.0/';
  const { initializeApp } = await import(sdk + 'firebase-app.js');
  const auth = await import(sdk + 'firebase-auth.js');
  const app = initializeApp(options);
  const instance = auth.initializeAuth(app, {
    errorMap: auth.debugErrorMap,
    persistence: [auth.indexedDBLocalPersistence, auth.browserLocalPersistence, auth.browserSessionPersistence],
    popupRedirectResolver: auth.browserPopupRedirectResolver,
  });
  auth.connectAuthEmulator(instance, `http://${host}:9099`);
};
