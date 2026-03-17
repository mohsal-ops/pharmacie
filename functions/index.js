const functions = require("firebase-functions");
const admin     = require("firebase-admin");
const vision    = require("@google-cloud/vision");

admin.initializeApp();
const visionClient = new vision.ImageAnnotatorClient();

exports.analyzeMedicine = functions.https.onRequest(async (req, res) => {

  // ── CORS headers (required for Flutter & testing) ──────────────────────
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Headers", "Content-Type,Authorization");
  if (req.method === "OPTIONS") { res.status(204).send(""); return; }
  if (req.method !== "POST")   { res.status(405).json({ error: "POST only" }); return; }

  try {
    const { imageBase64 } = req.body;

    if (!imageBase64) {
      res.status(400).json({ error: "Missing imageBase64 in request body" });
      return;
    }

    // ── Call Google Vision API ──────────────────────────────────────────
    const [result] = await visionClient.annotateImage({
      image: { content: imageBase64 },
      features: [
        { type: "TEXT_DETECTION" },               // reads text on the box
        { type: "LABEL_DETECTION", maxResults: 10 }, // identifies objects
      ],
    });

    const textAnnotations  = result.textAnnotations  || [];
    const labelAnnotations = result.labelAnnotations || [];

    // Full raw text from the image
    const fullText = textAnnotations.length > 0
      ? textAnnotations[0].description
      : "";

    const labels = labelAnnotations.map(l => l.description);

    // ── Parse medicine information from detected text ────────────────────
    const lines = fullText
      .split("\n")
      .map(l => l.trim())
      .filter(l => l.length > 1);

    // First non-empty line is usually the medicine name
    const medicineName = lines[0] || "Unknown";

    // Look for dosage patterns: 500mg, 250 mg, 10ml, etc.
    const dosageRegex = /(\d+\.?\d*\s?(mg|g|ml|mcg|IU))/gi;
    const dosageMatches = fullText.match(dosageRegex) || [];
    const dosage = dosageMatches[0] || "Not detected";

    // Look for expiry date: "EXP 12/2026" or "Expires: 2026-12"
    const expiryRegex = /(exp|expiry|expires?|use before|best before)[:\s]*([\d\/\-\.]+)/gi;
    const expiryMatch = expiryRegex.exec(fullText);
    const expiry = expiryMatch ? expiryMatch[2] : "Not detected";

    // Look for manufacturer / lab name
    const mfgKeywords = ["laboratoire", "lab", "pharma", "manufactured by", "mfg"];
    const manufacturer = lines.find(l =>
      mfgKeywords.some(k => l.toLowerCase().includes(k))
    ) || "Not detected";

    // ── Return structured JSON ──────────────────────────────────────────
    res.status(200).json({
      success: true,
      medicine: {
        name:         medicineName,
        dosage:       dosage,
        expiry:       expiry,
        manufacturer: manufacturer,
        allLines:     lines,
        labels:       labels,
        rawText:      fullText,
      },
    });

  } catch (err) {
    console.error("analyzeMedicine error:", err);
    res.status(500).json({ error: err.message || "Internal server error" });
  }
});