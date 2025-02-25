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
    // 응답 헤더 명시적 설정
    response.setHeader('Content-Type', 'application/json');
  
    try {
      const code = request.query.code;
      if (!code) {
        return response.status(400).json({
          status: false,
          message: "Authorization code is required",
          data: null
        });
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
  
      // Apple로부터 받은 응답 확인
      console.log("Apple response:", JSON.stringify(res.data));
  
      // refresh_token 확인
      if (!res.data?.refresh_token) {
        return response.status(400).json({
          status: false,
          message: "No refresh token in response",
          data: null
        });
      }
  
      // 응답 객체 생성
      const responseData = {
        status: true,
        message: "Success",
        data: {
          refresh_token: res.data.refresh_token
        }
      };
  
      // 응답 보내기 전에 로깅
      console.log("Sending response:", JSON.stringify(responseData));
      
      // 응답 전송
      return response.status(200).json(responseData);
  
    } catch (error) {
      console.error("Error details:", error);
      
      const errorResponse = {
        status: false,
        message: error.message || "Error getting refresh token",
        data: null
      };
  
      console.log("Sending error response:", JSON.stringify(errorResponse));
      return response.status(500).json(errorResponse);
    }
  });

// Token 폐기
exports.revokeToken = functions.https.onRequest(async (request, response) => {
  response.set("Content-Type", "application/json");
  try {
      const refresh_token = request.query.refresh_token;
      if (!refresh_token) {
          return response.status(400).json({
              status: false,
              message: "Refresh token is required",
              data: null
          });
      }

      const client_secret = makeJWT();
      const data = { token: refresh_token, client_id: "com.seokhyun.freshnote", client_secret: client_secret, token_type_hint: "refresh_token" };
      await axios.post("https://appleid.apple.com/auth/revoke", qs.stringify(data), { headers: { "Content-Type": "application/x-www-form-urlencoded" } });

      response.status(200).json({
          status: true,
          message: "Token revoked successfully",
          data: null // 추가 데이터가 없으므로 null
      });
  } catch (error) {
      console.error("Error revoking token:", error);
      response.status(500).json({
          status: false,
          message: "Error revoking token: " + error.message,
          data: null
      });
  }
});