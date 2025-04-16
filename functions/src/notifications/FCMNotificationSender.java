import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;

public class FCMNotificationSender {

    // 🔑 Replace with your actual server key from Firebase project settings
    private static final String SERVER_KEY = "YOUR_SERVER_KEY_HERE";
    private static final String FCM_API_URL = "https://fcm.googleapis.com/fcm/send";

    // 🚚 Notify all truck owners about available cargo
    public static void notifyTruckOwnersAboutCargo(String cargoLocation, String cargoType, String bookingId) throws Exception {
        URL url = new URL(FCM_API_URL);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();

        conn.setUseCaches(false);
        conn.setDoInput(true);
        conn.setDoOutput(true);
        conn.setRequestMethod("POST");

        conn.setRequestProperty("Authorization", "key=" + SERVER_KEY);
        conn.setRequestProperty("Content-Type", "application/json");

        // 🔔 Notification content
        String title = "🚚 New Cargo Available!";
        String body = "Cargo from " + cargoLocation + " (" + cargoType + ") is ready for delivery.";

        // 📨 JSON payload with notification + data
        String jsonPayload = "{"
                + "\"to\": \"/topics/truck_owner\","
                + "\"notification\": {"
                +     "\"title\": \"" + title + "\","
                +     "\"body\": \"" + body + "\""
                + "},"
                + "\"data\": {"
                +     "\"bookingId\": \"" + bookingId + "\","
                +     "\"cargoLocation\": \"" + cargoLocation + "\","
                +     "\"cargoType\": \"" + cargoType + "\""
                + "}"
                + "}";

        // Send the payload
        OutputStream os = conn.getOutputStream();
        os.write(jsonPayload.getBytes());
        os.flush();
        os.close();

        int responseCode = conn.getResponseCode();
        System.out.println("📨 Notification sent to truck_owner topic. Response Code: " + responseCode);

        conn.disconnect();
    }
}
