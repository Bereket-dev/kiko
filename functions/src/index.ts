import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as crypto from "crypto";
import * as nodemailer from "nodemailer";

admin.initializeApp();

const db = admin.firestore();
const auth = admin.auth();

const MAX_DEVICES = 2;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function sha256(value: string): string {
  return crypto.createHash("sha256").update(value).digest("hex");
}

function requireAuth(
  contextAuth: { uid: string } | undefined,
  userId: string
): void {
  if (!contextAuth || contextAuth.uid !== userId) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }
}

async function requireRegisteredDevice(
  userId: string,
  deviceId: string | undefined
): Promise<void> {
  // deviceId is optional for callers that only know the auth uid; when
  // provided, enforce registry membership. When absent, just require that
  // the user has at least one registered device (upload/download gates).
  const devicesRef = db.collection(`users/${userId}/devices`);
  if (deviceId) {
    const snap = await devicesRef.doc(deviceId).get();
    if (!snap.exists) {
      throw new HttpsError(
        "permission-denied",
        "This device is not registered"
      );
    }
    return;
  }

  const all = await devicesRef.limit(1).get();
  if (all.empty) {
    throw new HttpsError(
      "permission-denied",
      "No registered devices for this account"
    );
  }
}

function getSmtpTransport(): nodemailer.Transporter {
  const host = process.env.SMTP_HOST;
  const port = parseInt(process.env.SMTP_PORT ?? "587", 10);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !user || !pass) {
    throw new HttpsError("internal", "SMTP configuration is missing");
  }

  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
  });
}

// ---------------------------------------------------------------------------
// 1. requestOtp
// ---------------------------------------------------------------------------

interface RequestOtpData {
  email: string;
}

interface RequestOtpResult {
  otpToken: string;
}

export const requestOtp = onCall<RequestOtpData, Promise<RequestOtpResult>>(
  async (request) => {
    const { email } = request.data;

    if (!email || typeof email !== "string" || !email.includes("@")) {
      throw new HttpsError("invalid-argument", "A valid email is required");
    }

    const normalizedEmail = email.trim().toLowerCase();
    const emailHash = sha256(normalizedEmail);
    const now = Date.now();

    // Rate-limit: count unexpired sessions for this email
    const existing = await db
      .collection("otpSessions")
      .where("emailHash", "==", emailHash)
      .where("expiresAt", ">", now)
      .get();

    if (existing.size >= 3) {
      throw new HttpsError("resource-exhausted", "Too many OTP requests");
    }

    // Generate 6-digit OTP
    const otp = String(Math.floor(100000 + Math.random() * 900000));
    const otpHash = sha256(otp);
    const expiresAt = now + 10 * 60 * 1000; // 10 minutes

    // Persist session
    const sessionRef = db.collection("otpSessions").doc();
    await sessionRef.set({
      emailHash,
      otpHash,
      expiresAt,
      attempts: 0,
    });

    // Send email
    const transport = getSmtpTransport();
    const from = process.env.SMTP_FROM ?? process.env.SMTP_USER;

    await transport.sendMail({
      from,
      to: normalizedEmail,
      subject: "Your Kiko verification code",
      text: `Your Kiko OTP is: ${otp}\n\nThis code expires in 10 minutes.`,
      html: `<p>Your Kiko OTP is: <strong>${otp}</strong></p><p>This code expires in 10 minutes.</p>`,
    });

    return { otpToken: sessionRef.id };
  }
);

// ---------------------------------------------------------------------------
// 2. verifyOtp
// ---------------------------------------------------------------------------

interface VerifyOtpData {
  otpToken: string;
  otpCode: string;
}

interface VerifyOtpResult {
  verified: boolean;
}

export const verifyOtp = onCall<VerifyOtpData, Promise<VerifyOtpResult>>(
  async (request) => {
    const { otpToken, otpCode } = request.data;

    if (!otpToken || !otpCode) {
      throw new HttpsError(
        "invalid-argument",
        "otpToken and otpCode are required"
      );
    }

    const sessionRef = db.collection("otpSessions").doc(otpToken);
    const sessionSnap = await sessionRef.get();

    if (!sessionSnap.exists) {
      throw new HttpsError("invalid-argument", "Invalid or expired OTP");
    }

    const session = sessionSnap.data() as {
      emailHash: string;
      otpHash: string;
      expiresAt: number;
      attempts: number;
    };

    const now = Date.now();

    if (session.expiresAt <= now) {
      await sessionRef.delete();
      throw new HttpsError("invalid-argument", "Invalid or expired OTP");
    }

    if (session.attempts >= 5) {
      await sessionRef.delete();
      throw new HttpsError("invalid-argument", "Invalid or expired OTP");
    }

    // Increment attempts first (prevents race-condition brute-force)
    await sessionRef.update({
      attempts: admin.firestore.FieldValue.increment(1),
    });

    const inputHash = sha256(otpCode.trim());
    const storedBuf = Buffer.from(session.otpHash, "hex");
    const inputBuf = Buffer.from(inputHash, "hex");
    const match =
      storedBuf.length === inputBuf.length &&
      crypto.timingSafeEqual(storedBuf, inputBuf);

    if (!match) {
      throw new HttpsError("invalid-argument", "Invalid or expired OTP");
    }

    await sessionRef.delete();
    return { verified: true };
  }
);

// ---------------------------------------------------------------------------
// 3. registerDevice
// ---------------------------------------------------------------------------

interface RegisterDeviceData {
  userId: string;
  deviceId: string;
  deviceName: string;
}

interface RegisterDeviceResult {
  success: boolean;
}

export const registerDevice = onCall<
  RegisterDeviceData,
  Promise<RegisterDeviceResult>
>(async (request) => {
  const { userId, deviceId, deviceName } = request.data;

  requireAuth(request.auth, userId);

  if (!userId || !deviceId || !deviceName) {
    throw new HttpsError(
      "invalid-argument",
      "userId, deviceId, and deviceName are required"
    );
  }

  const devicesRef = db.collection(`users/${userId}/devices`);

  const existingSnap = await devicesRef.doc(deviceId).get();
  if (existingSnap.exists) {
    throw new HttpsError("already-exists", "Device already registered");
  }

  const allDevices = await devicesRef.get();
  if (allDevices.size >= MAX_DEVICES) {
    throw new HttpsError("resource-exhausted", "Max devices reached");
  }

  await devicesRef.doc(deviceId).set({
    deviceId,
    deviceName,
    registeredAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// ---------------------------------------------------------------------------
// 4. removeDevice
// ---------------------------------------------------------------------------

interface RemoveDeviceData {
  userId: string;
  deviceId: string;
}

interface RemoveDeviceResult {
  success: boolean;
}

export const removeDevice = onCall<
  RemoveDeviceData,
  Promise<RemoveDeviceResult>
>(async (request) => {
  const { userId, deviceId } = request.data;

  requireAuth(request.auth, userId);

  if (!deviceId) {
    throw new HttpsError("invalid-argument", "deviceId is required");
  }

  await db.doc(`users/${userId}/devices/${deviceId}`).delete();
  return { success: true };
});

// ---------------------------------------------------------------------------
// 5. listDevices
// ---------------------------------------------------------------------------

interface ListDevicesData {
  userId: string;
}

interface DeviceEntry {
  deviceId: string;
  deviceName: string;
  registeredAt: number | null;
}

interface ListDevicesResult {
  devices: DeviceEntry[];
}

export const listDevices = onCall<ListDevicesData, Promise<ListDevicesResult>>(
  async (request) => {
    const { userId } = request.data;

    requireAuth(request.auth, userId);

    const snap = await db.collection(`users/${userId}/devices`).get();

    const devices: DeviceEntry[] = snap.docs.map((doc) => {
      const d = doc.data();
      const ts = d.registeredAt as admin.firestore.Timestamp | undefined;
      return {
        deviceId: d.deviceId as string,
        deviceName: d.deviceName as string,
        registeredAt: ts ? ts.toMillis() : null,
      };
    });

    return { devices };
  }
);

// ---------------------------------------------------------------------------
// 6. getUploadUrl
// ---------------------------------------------------------------------------

interface GetUploadUrlData {
  userId: string;
  filename: string;
  deviceId?: string;
}

interface GetUploadUrlResult {
  uploadUrl: string;
  storagePath: string;
}

const FILENAME_RE = /^\d+\.enc$/;

export const getUploadUrl = onCall<
  GetUploadUrlData,
  Promise<GetUploadUrlResult>
>(async (request) => {
  const { userId, filename, deviceId } = request.data;

  requireAuth(request.auth, userId);
  await requireRegisteredDevice(userId, deviceId);

  if (!filename || !FILENAME_RE.test(filename)) {
    throw new HttpsError(
      "invalid-argument",
      "filename must match pattern <timestamp>.enc"
    );
  }

  const storagePath = `users/${userId}/backups/${filename}`;
  const bucket = admin.storage().bucket();
  const file = bucket.file(storagePath);

  const [uploadUrl] = await file.getSignedUrl({
    action: "write",
    expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    contentType: "application/octet-stream",
  });

  return { uploadUrl, storagePath };
});

// ---------------------------------------------------------------------------
// 7. getDownloadUrl
// ---------------------------------------------------------------------------

interface GetDownloadUrlData {
  userId: string;
  storagePath: string;
  deviceId?: string;
}

interface GetDownloadUrlResult {
  downloadUrl: string;
}

export const getDownloadUrl = onCall<
  GetDownloadUrlData,
  Promise<GetDownloadUrlResult>
>(async (request) => {
  const { userId, storagePath, deviceId } = request.data;

  requireAuth(request.auth, userId);
  await requireRegisteredDevice(userId, deviceId);

  const expectedPrefix = `users/${userId}/backups/`;
  if (!storagePath || !storagePath.startsWith(expectedPrefix)) {
    throw new HttpsError(
      "invalid-argument",
      "storagePath must be within your own backups folder"
    );
  }

  const bucket = admin.storage().bucket();
  const file = bucket.file(storagePath);

  const [downloadUrl] = await file.getSignedUrl({
    action: "read",
    expires: Date.now() + 15 * 60 * 1000, // 15 minutes
  });

  return { downloadUrl };
});

// ---------------------------------------------------------------------------
// 8. deleteAccount
// ---------------------------------------------------------------------------

interface DeleteAccountData {
  userId: string;
}

interface DeleteAccountResult {
  success: boolean;
}

async function deleteStorageFolder(
  bucket: ReturnType<ReturnType<typeof admin.storage>["bucket"]>,
  prefix: string
): Promise<void> {
  const [files] = await bucket.getFiles({ prefix });
  if (files.length === 0) return;
  await Promise.all(files.map((f) => f.delete()));
}

async function deleteFirestoreSubcollection(
  parentPath: string,
  subcollection: string
): Promise<void> {
  const colRef = db.collection(`${parentPath}/${subcollection}`);
  const snap = await colRef.get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((doc) => batch.delete(doc.ref));
  await batch.commit();
}

export const deleteAccount = onCall<
  DeleteAccountData,
  Promise<DeleteAccountResult>
>(async (request) => {
  const { userId } = request.data;

  requireAuth(request.auth, userId);

  const bucket = admin.storage().bucket();
  const userPath = `users/${userId}`;

  await Promise.all([
    deleteStorageFolder(bucket, `${userPath}/backups/`),
    deleteFirestoreSubcollection(userPath, "devices"),
    deleteFirestoreSubcollection(userPath, "keystore"),
    db.doc(userPath).delete(),
    auth.deleteUser(userId),
  ]);

  return { success: true };
});
