import { db } from '../../lib/database.js'

export async function findOrCreateUser({email}: { email: string}) {
  return await db.user.upsert({
    where: {
      email: email,
    },
    update: {},
    create: {
      email: email,
    },
  })
}
