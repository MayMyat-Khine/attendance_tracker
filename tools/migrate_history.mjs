// Preserve old history documents; create daily records without overwriting existing days.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp, GeoPoint } from 'firebase-admin/firestore';

const args = process.argv.slice(2);
const option = (key) => args.find((arg) => arg.startsWith(`--${key}=`))?.split('=')[1];
const projectId = option('project');
const offset = Number(option('offset-minutes'));
if (!projectId || !option('offset-minutes') || !Number.isFinite(offset) || Math.abs(offset) > 840) {
  throw new Error('Pass --project=PROJECT_ID --offset-minutes=390 (original local timezone; Myanmar = 390).');
}
const apply = args.includes('--apply');
initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();
const counts = { planned: 0, existing: 0, unresolved: 0 };
const auth = getAuth();
let last;
do {
  let query = db.collection('history').orderBy('__name__').limit(100);
  if (last) query = query.startAfter(last);
  const page = await query.get();
  for (const doc of page.docs) {
    const history = doc.data();
    if (typeof history.email !== 'string' || !Array.isArray(history.records)) {
      counts.unresolved++; continue;
    }
    let user;
    try { user = await auth.getUserByEmail(history.email); }
    catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      counts.unresolved += history.records.length; continue;
    }
    for (const [index, record] of history.records.entries()) {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(record.date ?? '') || !/^\d{2}:\d{2}$/.test(record.checkin ?? '') || !(record.location instanceof GeoPoint)) {
        counts.unresolved++; continue;
      }
      const utc = (time) => Date.parse(`${record.date}T${time}:00Z`) - offset * 60000;
      const start = utc(record.checkin);
      let end = record.checkout ? utc(record.checkout) : null;
      if (!Number.isFinite(start) || (end !== null && !Number.isFinite(end))) {
        counts.unresolved++; continue;
      }
      if (end !== null && end < start) end += 86400000;
      const ref = db.collection('attendance').doc(`${user.uid}_${record.date}`);
      const session = db.collection('attendance_sessions').doc(user.uid);
      const result = await db.runTransaction(async (tx) => {
        const existing = await tx.get(ref);
        const active = await tx.get(session);
        if (existing.exists) return 'existing';
        if (end === null && active.data()?.openDate) return 'unresolved';
        if (apply) {
          tx.create(ref, {
            userId: user.uid, email: user.email, date: record.date,
            checkin: record.checkin, checkout: record.checkout || '',
            checkInAt: Timestamp.fromMillis(start), checkOutAt: end === null ? null : Timestamp.fromMillis(end),
            location: record.location, checkOutLocation: null,
            checkInOperationId: `legacy_${doc.id}_${index}`,
            checkOutOperationId: end === null ? null : `legacy_${doc.id}_${index}_out`,
            legacyImported: true,
          });
          if (end === null) tx.set(session, { openDate: record.date });
        }
        return 'planned';
      });
      counts[result]++;
    }
  }
  last = page.size === 100 ? page.docs.at(-1) : undefined;
} while (last);
console.log(`${apply ? 'Applied' : 'Dry run'}: ${JSON.stringify(counts)}`);
console.log('Source history retained; missing checkout coordinates remain null. Review unresolved rows manually.');
