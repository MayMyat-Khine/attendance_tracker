// Run with Google Application Default Credentials. Dry run unless --apply is present.
import { applicationDefault, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const flags = process.argv.slice(2);
const projectId = flags.find((flag) => flag.startsWith('--project='))?.split('=')[1];
if (!projectId) throw new Error('Pass --project=YOUR_PROJECT_ID explicitly.');
const apply = flags.includes('--apply');
const collection = flags.includes('--staging') ? 'staging_users' : 'users';
initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore();
let last;
let changed = 0;
do {
  let query = db.collection(collection).orderBy('__name__').limit(200);
  if (last) query = query.startAfter(last);
  const page = await query.get();
  for (const doc of page.docs) {
    const profile = doc.data();
    if (typeof profile.email !== 'string' || !['user', 'admin'].includes(profile.role)) continue;
    const name = (typeof profile.name === 'string' ? profile.name.trim() : '') || profile.email.split('@')[0];
    const fields = {
      id: doc.id, name, nameLower: name.toLowerCase(),
      emailLower: profile.email.trim().toLowerCase(), photoUrl: profile.photoUrl || '',
    };
    const changes = Object.fromEntries(Object.entries(fields).filter(([key, value]) => profile[key] !== value));
    if (Object.keys(changes).length === 0) continue;
    changed++;
    if (apply) await doc.ref.update(changes, { lastUpdateTime: doc.updateTime });
  }
  last = page.size === 200 ? page.docs.at(-1) : undefined;
} while (last);
console.log(`${apply ? 'Updated' : 'Would update'} ${changed} profiles. Roles and attendance are unchanged.`);
