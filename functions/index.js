const functions = require("firebase-functions");
const { HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const jwt = require("jsonwebtoken");
const fs = require("fs");
const axios = require("axios");
const qs = require("qs");

admin.initializeApp();

// 환경에 따른 설정 값
const configMap = {
  debug: {
    p8File: "AuthKey_G2XK4HA494.p8",
    sub: "com.seokhyun.freshnote",
    kid: "G2XK4HA494",
    client_id: "com.seokhyun.freshnote",
  },
  release: {
    p8File: "AuthKey_42228GLYPW.p8",
    sub: "com.seokhyun.freshnote.release",
    kid: "42228GLYPW",
    client_id: "com.seokhyun.freshnote.release",
  },
};

// JWT 토큰 생성 함수
function makeJWT(buildConfig) {
  const config = configMap[buildConfig];
  if (!config) {
    throw new Error("Invalid build configuration: must be 'debug' or 'release'");
  }
  const privateKey = fs.readFileSync(config.p8File);
  return jwt.sign(
    {
      iss: "BH624LXP8S",
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 120,
      aud: "https://appleid.apple.com",
      sub: config.sub,
    },
    privateKey,
    {
      algorithm: "ES256",
      header: {
        alg: "ES256",
        kid: config.kid,
      },
    }
  );
}

// Refresh Token 얻기
exports.getRefreshToken = functions.https.onRequest(async (request, response) => {
  response.setHeader("Content-Type", "application/json");

  try {
    const code = request.query.code;
    const buildConfig = request.query.build_configuration;
    if (!code || !buildConfig) {
      return response.status(400).json({
        status: false,
        message: "Authorization code and build configuration are required",
        data: null,
      });
    }

    const client_secret = makeJWT(buildConfig);
    const config = configMap[buildConfig];
    const data = {
      code: code,
      client_id: config.client_id,
      client_secret: client_secret,
      grant_type: "authorization_code",
    };

    const res = await axios.post(
      "https://appleid.apple.com/auth/token",
      qs.stringify(data),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    );

    console.log("Apple response:", JSON.stringify(res.data));

    if (!res.data?.refresh_token) {
      return response.status(400).json({
        status: false,
        message: "No refresh token in response",
        data: null,
      });
    }

    const responseData = {
      status: true,
      message: "Success",
      data: {
        refresh_token: res.data.refresh_token,
      },
    };

    console.log("Sending response:", JSON.stringify(responseData));
    return response.status(200).json(responseData);
  } catch (error) {
    console.error("Error details:", error);
    const errorResponse = {
      status: false,
      message: error.message || "Error getting refresh token",
      data: null,
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
    const buildConfig = request.query.build_configuration;
    if (!refresh_token || !buildConfig) {
      return response.status(400).json({
        status: false,
        message: "Refresh token and build configuration are required",
        data: null,
      });
    }

    const client_secret = makeJWT(buildConfig);
    const config = configMap[buildConfig];
    const data = {
      token: refresh_token,
      client_id: config.client_id,
      client_secret: client_secret,
      token_type_hint: "refresh_token",
    };

    await axios.post(
      "https://appleid.apple.com/auth/revoke",
      qs.stringify(data),
      {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }
    );

    response.status(200).json({
      status: true,
      message: "Token revoked successfully",
      data: null,
    });
  } catch (error) {
    console.error("Error revoking token:", error);
    response.status(500).json({
      status: false,
      message: "Error revoking token: " + error.message,
      data: null,
    });
  }
});