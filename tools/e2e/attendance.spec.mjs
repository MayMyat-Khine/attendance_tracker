import { test, expect } from '@playwright/test';
import { fileURLToPath } from 'node:url';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
initializeApp({projectId: 'demo-attendance-tracker'});
const db = getFirestore();
const auth = getAuth();
const password = 'WebDemo123!';
async function enableAccessibility(page) {
  await page.locator('flt-semantics-placeholder').evaluate(el => el.click());
}
async function fill(page, name, value) {
  const field = page.getByRole('textbox', {name, exact: true});
  await field.click();
  // Flutter's browser focus bridge commits its editable input on the next frame.
  await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
  await page.keyboard.press('ControlOrMeta+A');
  await page.keyboard.type(value, {delay: 10});
  await expect(field).toHaveValue(value);
}
async function login(page, email) {
  await fill(page, 'Email', email); await fill(page, 'Password', password);
  await page.getByRole('button', {name:'Login', exact:true}).click();
}
test.beforeAll(async () => {
  try { await auth.createUser({uid:'web-admin', email:'admin.web@example.test', password}); }
  catch (error) { if (error.code !== 'auth/uid-already-exists' && error.code !== 'auth/email-already-exists') throw error; }
  await db.doc('users/web-admin').set({id:'web-admin', email:'admin.web@example.test', emailLower:'admin.web@example.test', name:'Web Admin', nameLower:'web admin', role:'admin', photoUrl:'', position:'Administrator', department:'IT'});
  const batch = db.batch();
  for (let i = 0; i < 25; i++) {
    const name = `Pagination Employee ${String(i).padStart(2, '0')}`;
    batch.set(db.doc(`users/web-page-${i}`), {id:`web-page-${i}`, email:`pagination${i}@example.test`, emailLower:`pagination${i}@example.test`, name, nameLower:name.toLowerCase(), role:'user', photoUrl:'', position:'Engineer', department:'IT'});
  }
  await batch.commit();
});
test('registration, offline daily attendance, sync, persistence, access rules, and admin filters', async ({page, context}) => {
  const pageErrors = [];
  page.on('pageerror', error => pageErrors.push(error.message));
  const suffix = Date.now();
  const email = `web.employee.${suffix}@example.test`;
  const displayName = `Browser Test ${suffix}`;
  await page.goto('/'); await enableAccessibility(page);
  await page.getByRole('button', {name:'Login', exact:true}).click();
  await expect(page.getByRole('group', {name:'Email is required.', exact:true})).toBeVisible();
  await page.getByRole('button', {name:'Register', exact:true}).click();
  const chooser = page.waitForEvent('filechooser');
  await page.getByRole('button', {name:'Choose profile image'}).click();
  await (await chooser).setFiles(fileURLToPath(new URL('../../web/favicon.png', import.meta.url)));
  await expect(page.getByRole('button', {name:'Change profile image'})).toBeVisible();
  await fill(page, 'Name', displayName); await fill(page, 'Email', email);
  await fill(page, 'Password', password); await fill(page, 'Position', 'Engineer');
  await page.getByRole('button', {name:'Register', exact:true}).click();
  await expect(page.getByRole('heading', {name:'Home', exact:true})).toBeVisible();
  await expect.poll(() => page.locator('body').ariaSnapshot()).toContain('16.86610, 96.19510');
  const user = await auth.getUserByEmail(email);
  expect((await db.doc(`users/${user.uid}`).get()).data().photoUrl).toContain('/profiles%2F');
  await context.setOffline(true);
  await page.getByRole('button', {name:/Check in$/}).click();
  await expect.poll(() => page.locator('body').ariaSnapshot()).toContain('Pending');
  await expect.poll(() => page.evaluate(() => JSON.parse(localStorage.getItem('attendance_v2_local.json')).pending.length)).toBe(1);
  await page.getByRole('button', {name:/Check out$/}).click();
  await expect.poll(() => page.evaluate(() => JSON.parse(localStorage.getItem('attendance_v2_local.json')).pending.length)).toBe(2);
  await expect(page.getByRole('button', {name:/Check in$/})).toHaveCount(0);
  await context.setOffline(false);
  await expect.poll(async () => (await db.collection('attendance').where('userId','==',user.uid).get()).docs[0]?.data()?.checkOutAt, {timeout:30000}).toBeTruthy();
  await expect.poll(() => page.locator('body').ariaSnapshot()).not.toContain('Pending');
  const logs = await db.collection('attendance').where('userId','==',user.uid).get();
  expect(logs.size).toBe(1);
  const record = logs.docs[0].data();
  expect(record.location.latitude).toBeCloseTo(16.8661);
  expect(record.checkOutLocation.longitude).toBeCloseTo(96.1951);
  expect(record.checkOutAt.toMillis()).toBeGreaterThanOrEqual(record.checkInAt.toMillis());
  await page.reload(); await enableAccessibility(page);
  await expect(page.getByRole('heading', {name:'Home', exact:true})).toBeVisible();
  await page.getByRole('button', {name:'See more', exact:true}).click();
  await expect(page.getByRole('heading', {name:'History', exact:true})).toBeVisible();
  await expect.poll(() => page.locator('body').ariaSnapshot()).toContain('In: 16.86610');
  const loginResponse = await fetch('http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=local-emulator-key', {method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email,password,returnSecureToken:true})});
  const {idToken} = await loginResponse.json();
  expect(idToken).toBeTruthy();
  const api = 'http://127.0.0.1:8080/v1/projects/demo-attendance-tracker/databases/(default)/documents';
  expect((await fetch(`${api}/users/web-admin`,{headers:{Authorization:`Bearer ${idToken}`}})).status).toBe(403);
  expect((await fetch(`${api}/users/${user.uid}?updateMask.fieldPaths=role`,{method:'PATCH',headers:{Authorization:`Bearer ${idToken}`,'Content-Type':'application/json'},body:JSON.stringify({fields:{role:{stringValue:'admin'}}})})).status).toBe(403);
  await page.goto('/'); await enableAccessibility(page);
  await page.getByRole('button', {name:'Sign out', exact:true}).click();
  await login(page, 'admin.web@example.test');
  await expect(page.getByRole('heading', {name:'Admin dashboard', exact:true})).toBeVisible();
  await page.getByRole('button', {name:'Users', exact:true}).click();
  await expect(page.getByRole('button', {name:/^Pagination Employee 00 /})).toBeVisible();
  await page.mouse.move(600, 700); await page.mouse.wheel(0, 1800);
  await expect(page.getByRole('button', {name:'Load more', exact:true})).toBeVisible();
  await page.getByRole('button', {name:'Load more', exact:true}).click();
  await expect(page.getByRole('button', {name:'Load more', exact:true})).toHaveCount(0);
  await page.mouse.wheel(0, 2400);
  await expect(page.getByRole('button', {name:/Web Admin/})).toBeVisible();
  await fill(page, 'Name starts with…', displayName);
  await page.getByRole('button', {name:new RegExp(displayName)}).click();
  await expect(page.getByRole('heading', {name:`${displayName} · History`, exact:true})).toBeVisible();
  await expect.poll(() => page.locator('body').ariaSnapshot()).toContain(email);
  await page.emulateMedia({colorScheme:'dark'});
  // Allow MaterialApp's 200 ms theme transition to finish before visual capture.
  await page.waitForTimeout(300);
  await page.screenshot({path:fileURLToPath(new URL('../../.local-tools/web-admin-history-dark.png', import.meta.url))});
  expect(pageErrors).toEqual([]);
});

test('two offline browser tabs cannot queue competing check-ins', async ({page, context}) => {
  const suffix = Date.now();
  const email = `two.tabs.${suffix}@example.test`;
  const user = await auth.createUser({email,password});
  await db.doc(`users/${user.uid}`).set({id:user.uid,email,emailLower:email,name:'Two Tabs',nameLower:'two tabs',role:'user',photoUrl:'',position:'Engineer',department:'IT'});
  await page.goto('/'); await enableAccessibility(page); await login(page,email);
  await expect(page.getByRole('heading',{name:'Home',exact:true})).toBeVisible();
  const other = await context.newPage();
  await other.goto('/'); await enableAccessibility(other);
  await expect(other.getByRole('heading',{name:'Home',exact:true})).toBeVisible();
  await context.setOffline(true);
  await Promise.all([
    page.getByRole('button',{name:/Check in$/}).click(),
    other.getByRole('button',{name:/Check in$/}).click(),
  ]);
  await expect.poll(() => page.evaluate(() => JSON.parse(localStorage.getItem('attendance_v2_local.json')).pending.length)).toBe(1);
  await expect.poll(async () => (await page.locator('body').ariaSnapshot()) + (await other.locator('body').ariaSnapshot())).toContain('Check out before checking in again.');
  await context.setOffline(false);
  await expect.poll(async () => (await db.collection('attendance').where('userId','==',user.uid).get()).size,{timeout:30000}).toBe(1);
  await expect.poll(() => page.evaluate(() => JSON.parse(localStorage.getItem('attendance_v2_local.json')).pending.length)).toBe(0);
});
