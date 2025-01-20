/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const functions = require("firebase-functions"); // 이 부분이 중요합니다!
const {HttpsError} = require("firebase-functions/v2/https");
const admin = require('firebase-admin');
const jwt = require("jsonwebtoken");
const fs = require("fs");
const axios = require("axios");
const qs = require("qs");

admin.initializeApp();

// JWT 토큰 생성 함수
function makeJWT() {
    const privateKey = fs.readFileSync("AuthKey_G2XK4HA494.p8");
    return jwt.sign(
        {
            iss: "BH624LXP8S",
            iat: Math.floor(Date.now() / 1000),
            exp: Math.floor(Date.now() / 1000) + 120,
            aud: "https://appleid.apple.com",
            sub: "com.seokhyun.freshnote",
        },
        privateKey,
        {
            algorithm: "ES256",
            header: {
                alg: "ES256",
                kid: "G2XK4HA494"
            }
        }
    );
}

// Refresh Token 얻기
exports.getRefreshToken = functions.https.onRequest(async (request, response) => {
    try {
        // authorization code로 apple 서버에 refresh token 요청
        const code = request.query.code;
        if (!code) {
            response.status(400).send("Authorization code is required");
            return;
        }

        const client_secret = makeJWT();
        const data = {
            code: code,
            client_id: "com.seokhyun.freshnote",
            client_secret: client_secret,
            grant_type: "authorization_code"
        };

        const res = await axios.post(
            "https://appleid.apple.com/auth/token",
            qs.stringify(data),
            {
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded"
                }
            }
        );
        // refresh token을 받아서 iOS에 전달
        response.send(res.data.refresh_token);
    } catch (error) {
        console.error("Error getting refresh token:", error);
        response.status(500).send("Error getting refresh token: " + error.message);
    }
});

// Token 폐기
exports.revokeToken = functions.https.onRequest(async (request, response) => {
    try {
        const refresh_token = request.query.refresh_token;
        if (!refresh_token) {
            response.status(400).send("Refresh token is required");
            return;
        }

        const client_secret = makeJWT();
        const data = {
            token: refresh_token,
            client_id: "com.seokhyun.freshnote",
            client_secret: client_secret,
            token_type_hint: "refresh_token"
        };

        await axios.post(
            "https://appleid.apple.com/auth/revoke",
            qs.stringify(data),
            {
                headers: {
                    "Content-Type": "application/x-www-form-urlencoded"
                }
            }
        );

        response.send("Token revoked successfully");
    } catch (error) {
        console.error("Error revoking token:", error);
        response.status(500).send("Error revoking token: " + error.message);
    }
});