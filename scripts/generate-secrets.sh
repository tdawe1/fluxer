#!/usr/bin/env sh
set -eu

hex64() {
  openssl rand -hex 32
}

hex16() {
  openssl rand -hex 8
}

echo "MEILI_MASTER_KEY=$(hex64)"
echo "LIVEKIT_API_KEY=$(hex16)"
echo "LIVEKIT_API_SECRET=$(hex64)"
echo "CONNECTION_INITIATION_SECRET=$(hex64)"
echo "SUDO_MODE_SECRET=$(hex64)"
echo "S3_SECRET_ACCESS_KEY=$(hex64)"
echo "MEDIA_PROXY_SECRET_KEY=$(hex64)"
echo "ADMIN_OAUTH_CLIENT_SECRET=$(hex64)"
echo "ADMIN_SECRET_KEY_BASE=$(hex64)"
echo "MARKETING_SECRET_KEY_BASE=$(hex64)"
echo "GATEWAY_ADMIN_RELOAD_SECRET=$(hex64)"

docker run --rm node:22-alpine node -e '
const { generateKeyPairSync } = require("crypto");
function fromB64Url(value) {
  let normalized = value.replace(/-/g, "+").replace(/_/g, "/");
  while (normalized.length % 4) normalized += "=";
  return Buffer.from(normalized, "base64");
}
function toB64Url(buf) {
  return buf.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}
const { publicKey, privateKey } = generateKeyPairSync("ec", {
  namedCurve: "prime256v1",
  publicKeyEncoding: { format: "jwk" },
  privateKeyEncoding: { format: "jwk" }
});
const publicBytes = Buffer.concat([
  Buffer.from([0x04]),
  fromB64Url(publicKey.x),
  fromB64Url(publicKey.y)
]);
console.log("VAPID_PUBLIC_KEY=" + toB64Url(publicBytes));
console.log("VAPID_PRIVATE_KEY=" + privateKey.d);
'
