from firebase_functions import https_fn
from firebase_functions.params import SecretParam
from firebase_admin import initialize_app, firestore, storage
from firebase_admin.firestore import SERVER_TIMESTAMP
from utils.fetch_PPG_data import timestamp_to_isoformat, hex_to_int
from utils.process_PPG_data import bandpass_filter, moving_average_filter, eliminate_noise_in_time
from utils.metrics_calculations import get_ppg_features
from twilio.rest import Client
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
import os
import json
import joblib
import numpy as np
import io

# Initialize Firebase Admin SDK
initialize_app()

# Define secret parameters
TWILIO_ACCOUNT_SID = SecretParam('TWILIO_ACCOUNT_SID')
TWILIO_AUTH_TOKEN = SecretParam('TWILIO_AUTH_TOKEN')
TWILIO_PHONE_NUMBER = SecretParam('TWILIO_PHONE_NUMBER')
SENDGRID_API_KEY = SecretParam('SENDGRID_API_KEY')
RECIPIENT_PHONE_NUMBER = SecretParam('RECIPIENT_PHONE_NUMBER')

# ML model path
MODEL_PATH = "lightgbm_model.joblib"

# Function 1: Process PPG
@https_fn.on_request()
def process_ppg(req: https_fn.Request) -> https_fn.Response:
    # Extract participant_id and hrv_document_id from the request
    participant_id = req.args.get("participant_id")
    hrv_document_id = req.args.get("hrv_document_id")

    if not participant_id or not hrv_document_id:
        return https_fn.Response(
            json.dumps({"error": "Missing participant_id or hrv_document_id"}), 
            status=400, 
            mimetype="application/json"
        )

    # Initialize Firestore
    db = firestore.client()

    try:
        # Fetch data from Firestore
        ppg_data = fetch_ppg_array(db, participant_id, hrv_document_id)
    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": f"Error fetching data from Firestore: {str(e)}"}), 
            status=500, 
            mimetype="application/json"
        )

    try:
        if len(ppg_data) < 15:  # Check if the signal is shorter than the padlen
            raise ValueError("PPG data length is too short for processing.")

        # Process the PPG data
        bandpass_ppg = bandpass_filter(ppg_data, 0.7, 5, 25)
        bandpass_ppg = bandpass_ppg[50:]
        smoothed_ppg = moving_average_filter(bandpass_ppg, 3)
        denoised_ppg = eliminate_noise_in_time(smoothed_ppg, 25, 12.0, 5.0, [1.8, 1.5])
        dubSmoothed_ppg = moving_average_filter(denoised_ppg, 3)
    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": f"Error processing PPG data: {str(e)}"}), 
            status=500, 
            mimetype="application/json"
        )


    try:
        # Calculate metrics
        features_dict = get_ppg_features(dubSmoothed_ppg)
        
        # Check if features are extracted
        if not features_dict:
            return https_fn.Response(
                json.dumps({"message": "No features extracted from PPG data."}), 
                status=200, 
                mimetype="application/json"
            )
        
        # Add the Firebase server timestamp to the features dictionary
        features_dict["timestamp"] = SERVER_TIMESTAMP

        # Fetch model and scaler from Firebase Storage
        lightgbm_model = load_from_storage(MODEL_PATH)

        # Extract features and prepare for prediction
        feature_array = np.array([
            features_dict["HR_mean"], 
            features_dict["meanNN"],
            features_dict["sdnn"], 
            features_dict["medianNN"],
            features_dict["meanSD"],
            features_dict["SDSD"], 
            features_dict["rmssd"], 
            features_dict["pNN50"]  
        ]).reshape(1, -1)

        # Predict stress level
        stress_probability = lightgbm_model.predict_proba(feature_array)[0, 1]
        features_dict["stress_probability"] = stress_probability

    except Exception as e:
        return https_fn.Response(
            json.dumps({"error": f"Error calculating metrics: {str(e)}"}), 
            status=500, 
            mimetype="application/json"
        )
    
    # Save metrics to firebase
    doc_ref = db.collection('users').document(participant_id).collection('HRV-inApp').document(hrv_document_id)
    try:
        doc_ref.set(features_dict, merge=True)  # Save the metrics
        print(f"Metrics saved successfully for document {hrv_document_id} in participant {participant_id}'s data.")
        return https_fn.Response(
            json.dumps({"status": "success", "message": "Metrics saved successfully."}), 
            mimetype="application/json", 
            status=200
        )
    except Exception as e:
        print(f"Error saving metrics: {e}")
        return https_fn.Response(
            json.dumps({"error": f"Error saving metrics: {str(e)}"}), 
            status=500, 
            mimetype="application/json"
        )

# Function 2: Flagged Message Notification
@https_fn.on_request(secrets=[
    TWILIO_ACCOUNT_SID,
    TWILIO_AUTH_TOKEN,
    TWILIO_PHONE_NUMBER,
    SENDGRID_API_KEY,
    RECIPIENT_PHONE_NUMBER,
])
def send_flagged_message_notification(req: https_fn.Request) -> https_fn.Response:
    try:
        # Parse JSON payload from request
        data = req.get_json(silent=True)
        if not data:
            return https_fn.Response("Invalid request: No JSON payload found", status=400)

        # Extract fields from the request data
        user_id = data.get("userID", "Unknown User")
        message = data.get("message", "No Message")
        categories = data.get("categories", [])
        timestamp = data.get("timestamp", "Unknown Time")

        # Format the message content
        flagged_categories = ", ".join(categories)
        notification_message = f"""
        A new flagged message has been detected:

        User ID: {user_id}
        Message: "{message}"
        Categories: {flagged_categories}
        Timestamp: {timestamp}

        Please review this message in the Firebase Console.
        """

        # Send SMS notification using Twilio
        send_sms_notification(notification_message)

        # Send Email notification using SendGrid
        send_email_notification(
            subject="Flagged Message Detected",
            content=notification_message,
        )

        return https_fn.Response("Notification sent successfully", status=200)

    except Exception as e:
        print(f"Error in send_flagged_message_notification: {e}")
        return https_fn.Response(f"Internal Server Error: {e}", status=500)


def send_sms_notification(body: str) -> None:
    """Send SMS notification using Twilio"""
    try:
        client = Client(
            TWILIO_ACCOUNT_SID.value, 
            TWILIO_AUTH_TOKEN.value
        )
        message = client.messages.create(
            body=body,
            from_=TWILIO_PHONE_NUMBER.value,
            to=RECIPIENT_PHONE_NUMBER.value,
        )
        print(f"SMS sent with SID: {message.sid}")
    except Exception as e:
        print(f"Error sending SMS: {e}")


def send_email_notification(subject: str, content: str) -> None:
    """Send Email notification using SendGrid"""
    try:
        sg = SendGridAPIClient(SENDGRID_API_KEY.value)
        email = Mail(
            from_email='jlaiti@vt.edu',
            to_emails='jlaiti@vt.edu',
            subject=subject,
            html_content=content,
        )
        response = sg.send(email)
        print(f"Email sent with status: {response.status_code}")
    except Exception as e:
        print(f"Error sending email: {e}")

# Utillity functions:
# Function to fetch PPG data array from Firestore
def fetch_ppg_array(db, participant_id, hrv_document_id):
    try:
        raw_data_ref = db.collection('users').document(participant_id).collection('HRV-inApp').document(hrv_document_id).collection('rawData')
        raw_data_docs = raw_data_ref.stream()

        raw_data_list = []
        for doc in raw_data_docs:
            doc_data = doc.to_dict()
            doc_data['timestamp'] = timestamp_to_isoformat(doc_data['timestamp'])  # Convert timestamp
            raw_data_list.append(doc_data)

        # Sort by timestamp and combine raw data
        raw_data_list.sort(key=lambda x: x['timestamp'])
        combined_data = []
        for entry in raw_data_list:
            raw_data_values = hex_to_int(entry['rawData'])
            combined_data.extend(raw_data_values)

        return combined_data
    except Exception as e:
        print(f"Error fetching PPG data: {str(e)}")
        raise e
    

def load_from_storage(file_path):
    """Fetches a file from Firebase Storage and loads it with joblib."""
    bucket = storage.bucket()
    blob = bucket.blob(file_path)
    model_data = blob.download_as_bytes()
    model_file = io.BytesIO(model_data)
    return joblib.load(model_file)