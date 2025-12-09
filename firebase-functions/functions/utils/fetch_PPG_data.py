from datetime import datetime

# Function to convert Firestore timestamp to ISO format
def timestamp_to_isoformat(ts):
    if isinstance(ts, str):
        try:
            dt = datetime.strptime(ts, "%Y-%m-%dT%H:%M:%S.%fZ")
        except ValueError:
            dt = datetime.strptime(ts, "%Y-%m-%dT%H:%M:%S.%f")
    elif hasattr(ts, 'seconds'):
        dt = datetime.fromtimestamp(ts.seconds + ts.nanoseconds / 1e9)
    else:
        dt = ts  # If already a datetime object
    return dt.isoformat()

# Function to convert hexadecimal data to integers
def hex_to_int(hex_str):
    hex_values = hex_str.split(',')
    int_values = []
    for hv in hex_values:
        try:
            int_value = int(hv.strip(), 16)
            int_values.append(int_value)
        except ValueError:
            print(f"Invalid hex value: {hv}")
    return int_values