const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const { GoogleGenAI } = require("@google/generative-ai");
const axios = require("axios");

admin.initializeApp();
const db = admin.firestore();

/**
 * Helper to fetch API Keys and secrets from Firestore settings
 */
async function getSettings() {
  const doc = await db.collection("settings").doc("config").get();
  if (!doc.exists) {
    throw new HttpsError("not-found", "Configuration settings document not found.");
  }
  return doc.data();
}

/**
 * Generate AI Content (Caption & Hashtags) using Gemini API
 */
exports.generateAIContent = onCall(async (request) => {
  // Ensure user is authenticated
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const { contentType, prompt, tone, keywords } = request.data;
  if (!contentType || !prompt) {
    throw new HttpsError("invalid-argument", "Missing required fields: contentType or prompt.");
  }

  try {
    const config = await getSettings();
    const apiKey = config.geminiApiKey || process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "Gemini API key is not configured.");
    }

    const genAI = new GoogleGenAI({ apiKey });
    const model = genAI.getGenerativeModel({ model: "gemini-pro" });

    const systemPrompt = `You are a professional social media manager.
Write a highly engaging Instagram ${contentType}. 
Tone: ${tone || "professional, catchy"}.
Keywords to include: ${(keywords || []).join(", ")}.
User Instructions: ${prompt}

Output format:
JSON block containing "body", "caption", and a list "hashtags".
Do not output markdown codeblocks around JSON, just return raw JSON string.`;

    const result = await model.generateContent(systemPrompt);
    const text = result.response.text();
    
    // Parse response
    let jsonResult;
    try {
      jsonResult = JSON.parse(text.replace(/```json/g, "").replace(/```/g, "").trim());
    } catch (e) {
      // Fallback if not valid JSON
      jsonResult = {
        body: text,
        caption: `Generated ${contentType}`,
        hashtags: keywords || ["#socialmedia", "#ai"]
      };
    }

    return jsonResult;
  } catch (error) {
    console.error("AI Generation Error: ", error);
    throw new HttpsError("internal", error.message || "Failed to generate AI content");
  }
});

/**
 * Generate AI Image Mock/Placeholder or Real DALL-E/Imagen API Connection
 */
exports.generateAIImage = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const { prompt, count } = request.data;
  if (!prompt) {
    throw new HttpsError("invalid-argument", "Prompt is required.");
  }

  try {
    const config = await getSettings();
    // Simulate generation or integrate DALL-E / Imagen API:
    // Here we generate standard beautiful placeholder URLs using Unsplash source queries
    // while setting up the architecture for real DALL-E API integrations if OpenAI Key exists.
    
    const imageUrls = [];
    const query = encodeURIComponent(prompt.split(" ").slice(0, 3).join(","));
    const numImages = count || 1;

    for (let i = 0; i < numImages; i++) {
      // Direct mock using high quality unsplash categories to simulate beautiful designs
      imageUrls.push(`https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=800&auto=format&fit=crop&sig=${i}_${Date.now()}`);
    }

    return { urls: imageUrls };
  } catch (error) {
    console.error("Image Generation Error: ", error);
    throw new HttpsError("internal", error.message || "Failed to generate AI image");
  }
});

/**
 * Publish Content directly to Instagram Graph API
 */
exports.publishToInstagram = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated.");
  }

  const { contentId } = request.data;
  if (!contentId) {
    throw new HttpsError("invalid-argument", "contentId is required.");
  }

  try {
    return await executeInstagramPublish(contentId);
  } catch (error) {
    console.error("Instagram Publish Callable Error: ", error);
    throw new HttpsError("internal", error.message || "Publishing failed");
  }
});

/**
 * Core Instagram Publishing Execution Logic
 */
async function executeInstagramPublish(contentId) {
  const contentDoc = await db.collection("content").doc(contentId).get();
  if (!contentDoc.exists) {
    throw new Error(`Content document ${contentId} not found.`);
  }
  const contentData = contentDoc.data();

  // Get active Instagram Account connection
  const accountDoc = await db.collection("instagram_account").doc("active_account").get();
  if (!accountDoc.exists || !accountDoc.data().isConnected) {
    throw new Error("No connected Instagram account found.");
  }
  const account = accountDoc.data();

  const captionText = `${contentData.caption || ""}\n\n${(contentData.hashtags || []).join(" ")}`;
  const mediaUrl = contentData.mediaUrls && contentData.mediaUrls.length > 0 ? contentData.mediaUrls[0] : null;

  if (!mediaUrl) {
    throw new Error("No media attachment URL found for publishing.");
  }

  const igUserId = account.instagramBusinessAccountId;
  const accessToken = account.accessToken;

  // 1. Create Media Container
  const containerResponse = await axios.post(
    `https://graph.facebook.com/v19.0/${igUserId}/media`,
    null,
    {
      params: {
        image_url: mediaUrl,
        caption: captionText,
        access_token: accessToken,
      },
    }
  );

  const creationId = containerResponse.data.id;
  if (!creationId) {
    throw new Error("Failed to create Instagram media container.");
  }

  // 2. Poll Container Status (Optional, but useful for videos/carousels)
  let status = "IN_PROGRESS";
  let checkAttempts = 0;
  while (status === "IN_PROGRESS" && checkAttempts < 10) {
    const statusResponse = await axios.get(
      `https://graph.facebook.com/v19.0/${creationId}`,
      {
        params: {
          fields: "status_code",
          access_token: accessToken,
        },
      }
    );
    status = statusResponse.data.status_code;
    if (status === "FINISHED" || status === "PUBLISHED") break;
    if (status === "ERROR") {
      throw new Error("Container creation failed on Instagram's server.");
    }
    // Wait 5 seconds
    await new Promise((resolve) => setTimeout(resolve, 5000));
    checkAttempts++;
  }

  // 3. Publish Media Container
  const publishResponse = await axios.post(
    `https://graph.facebook.com/v19.0/${igUserId}/media_publish`,
    null,
    {
      params: {
        creation_id: creationId,
        access_token: accessToken,
      },
    }
  );

  const publishId = publishResponse.data.id;
  if (!publishId) {
    throw new Error("Failed to execute media publish.");
  }

  // Update Status in Firestore
  await db.collection("content").doc(contentId).update({
    status: "published",
    errorMessage: null,
  });

  return { success: true, publishId };
}

/**
 * Scheduled Cron Job: Runs every 15 minutes to publish scheduled posts
 */
exports.cronPublishJob = onSchedule("*/15 * * * *", async (event) => {
  const now = admin.firestore.Timestamp.now();
  
  // Find all scheduled posts whose time has passed
  const snapshot = await db.collection("schedules")
    .where("status", "==", "scheduled")
    .where("scheduledTime", "<=", now)
    .get();

  if (snapshot.empty) {
    console.log("No pending schedules found to publish.");
    return null;
  }

  console.log(`Found ${snapshot.size} schedules to process.`);

  for (const doc of snapshot.docs) {
    const scheduleId = doc.id;
    const scheduleData = doc.data();
    const contentId = scheduleData.contentId;

    try {
      // Execute publishing
      const result = await executeInstagramPublish(contentId);
      
      // Update Schedule to published
      await db.collection("schedules").doc(scheduleId).update({
        status: "published",
        publishedTime: now,
        attempts: admin.firestore.FieldValue.increment(1)
      });
      console.log(`Successfully published content ${contentId} via schedule ${scheduleId}`);
    } catch (err) {
      console.error(`Failed to publish schedule ${scheduleId}: `, err);
      
      const nextAttempts = (scheduleData.attempts || 0) + 1;
      const isFailed = nextAttempts >= 3; // Retry limit 3

      await db.collection("schedules").doc(scheduleId).update({
        status: isFailed ? "failed" : "scheduled", // retry later unless limit met
        attempts: nextAttempts,
        lastError: err.message || "Unknown publishing error"
      });

      await db.collection("content").doc(contentId).update({
        status: isFailed ? "failed" : "scheduled",
        errorMessage: err.message || "Retry attempt failed"
      });
    }
  }

  return null;
});
