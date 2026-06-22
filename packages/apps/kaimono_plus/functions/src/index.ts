import { createHash, randomInt } from 'node:crypto';

import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

initializeApp();

const db = getFirestore();
const auth = getAuth();

const COLLECTION = 'passwordResetCodes';
const SHARED_LISTS_COLLECTION = 'sharedLists';
const SHARE_BASE_URL = 'https://kaimono-plus.web.app/share';
const CODE_TTL_MS = 10 * 60 * 1000;
const MAX_ATTEMPTS = 5;
const MAX_SHARED_ITEMS = 100;
const MAX_SHARED_ITEM_LENGTH = 120;

function normalizeEmail(email: unknown): string {
  if (typeof email !== 'string') {
    throw new HttpsError(
      'invalid-argument',
      'メールアドレスの形式が正しくありません',
      { authCode: 'invalid-email' },
    );
  }
  const trimmed = email.trim().toLowerCase();
  if (!/^[^@]+@[^@]+\.[^@]+$/.test(trimmed)) {
    throw new HttpsError(
      'invalid-argument',
      'メールアドレスの形式が正しくありません',
      { authCode: 'invalid-email' },
    );
  }
  return trimmed;
}

function hashCode(email: string, code: string): string {
  return createHash('sha256').update(`${email}:${code}`).digest('hex');
}

function generateCode(): string {
  return String(randomInt(100000, 1_000_000));
}

function validateNewPassword(password: unknown): string {
  if (typeof password !== 'string' || password.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      'パスワードを入力してください',
      { authCode: 'weak-password' },
    );
  }
  if (password.length < 6) {
    throw new HttpsError(
      'invalid-argument',
      'パスワードは6文字以上で入力してください',
      { authCode: 'weak-password' },
    );
  }
  if (!/[a-zA-Z]/.test(password)) {
    throw new HttpsError(
      'invalid-argument',
      'パスワードは英字を1文字以上含めてください',
      { authCode: 'weak-password' },
    );
  }
  if (!/[0-9]/.test(password)) {
    throw new HttpsError(
      'invalid-argument',
      'パスワードは数字を1文字以上含めてください',
      { authCode: 'weak-password' },
    );
  }
  return password;
}

function normalizeSharedItems(items: unknown): Array<{ text: string }> {
  if (!Array.isArray(items)) {
    throw new HttpsError(
      'invalid-argument',
      '共有するアイテムがありません',
      { authCode: 'invalid-shared-list' },
    );
  }

  const normalized = items
    .map((item) => {
      if (typeof item !== 'object' || item === null || !('text' in item)) {
        return null;
      }
      const text = (item as { text?: unknown }).text;
      if (typeof text !== 'string') {
        return null;
      }
      const trimmed = text.trim();
      if (trimmed.length === 0) {
        return null;
      }
      return { text: trimmed.slice(0, MAX_SHARED_ITEM_LENGTH) };
    })
    .filter((item): item is { text: string } => item !== null);

  if (normalized.length === 0) {
    throw new HttpsError(
      'invalid-argument',
      '共有するアイテムがありません',
      { authCode: 'invalid-shared-list' },
    );
  }

  return normalized.slice(0, MAX_SHARED_ITEMS);
}

function normalizeSharedListId(id: unknown): string {
  if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{8,}$/.test(id)) {
    throw new HttpsError(
      'invalid-argument',
      '共有リストが見つかりません',
      { authCode: 'invalid-shared-list-id' },
    );
  }
  return id;
}

async function findSharedList(id: string): Promise<Array<{ text: string }> | null> {
  const snap = await db.collection(SHARED_LISTS_COLLECTION).doc(id).get();
  if (!snap.exists) {
    return null;
  }

  const data = snap.data()!;
  return Array.isArray(data.items)
    ? data.items
        .map((item) => {
          if (typeof item !== 'object' || item === null || !('text' in item)) {
            return null;
          }
          const text = (item as { text?: unknown }).text;
          return typeof text === 'string' ? { text } : null;
        })
        .filter((item): item is { text: string } => item !== null)
    : [];
}

export const sendPasswordResetCode = onCall({ invoker: 'public' }, async (request) => {
  const email = normalizeEmail(request.data?.email);

  try {
    await auth.getUserByEmail(email);
  } catch {
    // 列挙防止: 未登録メールでも成功レスポンス
    return { success: true };
  }

  const code = generateCode();
  const expiresAt = Date.now() + CODE_TTL_MS;

  await db.collection(COLLECTION).doc(email).set({
    codeHash: hashCode(email, code),
    expiresAt,
    attempts: 0,
    createdAt: Timestamp.now(),
  });

  await db.collection('mail').add({
    to: email,
    message: {
      subject: '【Kaimono+】パスワード再設定の認証コード',
      text: `認証コード: ${code}\n\nこのコードの有効期限は10分です。`,
      html: `<p>認証コード: <strong>${code}</strong></p><p>有効期限は10分です。</p>`,
    },
  });

  return { success: true };
});

export const confirmPasswordResetWithCode = onCall({ invoker: 'public' }, async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code =
    typeof request.data?.code === 'string' ? request.data.code.trim() : '';
  const newPassword = validateNewPassword(request.data?.newPassword);

  if (!/^\d{6}$/.test(code)) {
    throw new HttpsError(
      'invalid-argument',
      '認証コードは6桁の数字で入力してください',
      { authCode: 'invalid-verification-code' },
    );
  }

  const docRef = db.collection(COLLECTION).doc(email);
  const snap = await docRef.get();
  if (!snap.exists) {
    throw new HttpsError(
      'failed-precondition',
      '認証コードが無効です。再度コードを送信してください',
      { authCode: 'invalid-verification-code' },
    );
  }

  const data = snap.data()!;
  if (Date.now() > (data.expiresAt as number)) {
    await docRef.delete();
    throw new HttpsError(
      'failed-precondition',
      '認証コードの有効期限が切れています。再度コードを送信してください',
      { authCode: 'expired-verification-code' },
    );
  }

  const attempts = (data.attempts as number) ?? 0;
  if (attempts >= MAX_ATTEMPTS) {
    throw new HttpsError(
      'resource-exhausted',
      '試行回数の上限に達しました。再度認証コードを送信してください',
      { authCode: 'too-many-requests' },
    );
  }

  if (data.codeHash !== hashCode(email, code)) {
    await docRef.update({ attempts: attempts + 1 });
    throw new HttpsError(
      'failed-precondition',
      '認証コードが正しくありません',
      { authCode: 'invalid-verification-code' },
    );
  }

  const user = await auth.getUserByEmail(email);
  await auth.updateUser(user.uid, { password: newPassword });
  await docRef.delete();

  return { success: true };
});

export const createSharedList = onCall({ invoker: 'public' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'ログインが必要です',
      { authCode: 'unauthenticated' },
    );
  }

  const items = normalizeSharedItems(request.data?.items);
  const docRef = db.collection(SHARED_LISTS_COLLECTION).doc();
  await docRef.set({
    items,
    ownerUid: request.auth.uid,
    createdBy: request.auth.uid,
    createdAt: FieldValue.serverTimestamp(),
    version: 1,
  });

  return {
    id: docRef.id,
    url: `${SHARE_BASE_URL}/${docRef.id}`,
  };
});

export const getSharedListForApp = onCall({ invoker: 'public' }, async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'ログインが必要です',
      { authCode: 'unauthenticated' },
    );
  }

  const id = normalizeSharedListId(request.data?.id);
  const items = await findSharedList(id);
  if (items === null) {
    throw new HttpsError(
      'not-found',
      '共有リストが見つかりません',
      { authCode: 'shared-list-not-found' },
    );
  }

  return {
    id,
    title: '買い物リスト',
    items,
  };
});
