const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.notifyTruckOwners = functions.https.onCall(async (data, context) => {
  try {
    const snapshot = await admin.firestore().collection("userFcmTokens").get();
    const tokens = snapshot.docs.map(doc => doc.data().token).filter(Boolean);

    if (tokens.length === 0) {
      return { success: false, message: "No FCM tokens found." };
    }

    const payload = {
      notification: {
        title: "🚚 New Cargo Request",
        body: `${data.cargoDetails} (${data.weight}) from ${data.fromLocation} to ${data.toLocation}`,
      },
      data: {
        cargoDetails: data.cargoDetails,
        weight: data.weight,
        fromLocation: data.fromLocation,
        toLocation: data.toLocation,
        distance: data.distance,
        vehicleType: data.vehicleType,
      },
    };

    await admin.messaging().sendToDevice(tokens, payload);

    return { success: true, message: "Notifications sent." };
  } catch (error) {
    console.error("Error sending notification:", error);
    return { success: false, message: error.message };
  }
});
