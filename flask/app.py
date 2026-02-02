from datetime import datetime, timedelta
from flask import Flask, jsonify, request
from dateutil.relativedelta import relativedelta  
from prophet import Prophet
import pandas as pd
from firebase_admin import firestore, credentials, initialize_app
import logging
import numpy as np

# Initialize Flask app
app = Flask(__name__)

# Initialize Firestore
cred = credentials.Certificate("service_account/spendlytracking-firebase-adminsdk-fbsvc-f872f89e4d.json")
initialize_app(cred)
db = firestore.client()

# Configure logging
logging.basicConfig(level=logging.DEBUG)

def calculate_data_sufficiency(df):
    """
    Calculate a sufficiency score for the data based on:
    - Number of data points
    - Time range of the data
    - Variance in the data
    """
    num_points = len(df)
    time_range = (df['ds'].max() - df['ds'].min()).days
    variance = df['y'].var()

    # Normalize the metrics (adjust weights as needed)
    sufficiency_score = (
        0.5 * (num_points / 30) +  # Weight for number of data points
        0.3 * (time_range / 365) +  # Weight for time range
        0.2 * (1 / (1 + variance))  # Weight for variance (lower variance = higher score)
    )

    return sufficiency_score

def adjust_for_sparse_data(category_df):
    """
    Adjust Prophet model parameters for sparse data.
    """
    # Use lower sensitivity to changepoint detection
    model = Prophet(
        changepoint_prior_scale=0.01,  # Reduced sensitivity for sparse data
        seasonality_prior_scale=15.0,  # Increased flexibility for seasonality
        yearly_seasonality=False,  # Disable yearly seasonality for sparse data
        weekly_seasonality=False,  # Disable weekly seasonality for sparse data
    )
    model.add_seasonality(name='monthly', period=30.5, fourier_order=5)  # Custom monthly seasonality

    # Fit the model on available data
    model.fit(category_df)
    return model

def calculate_monthly_mean(category_df):
    """
    Calculate the mean of total expenses for each month in the past.
    """
    # Extract month and year from the date
    category_df['month'] = category_df['ds'].dt.to_period('M')

    # Aggregate expenses by month
    monthly_totals = category_df.groupby('month')['y'].sum().reset_index()

    # Calculate the mean of monthly totals
    monthly_mean = monthly_totals['y'].mean()

    return monthly_mean

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get user ID from the request
        data = request.json
        user_id = data.get('user_id')

        app.logger.debug(f"Received request with user_id: {user_id}")

        if not user_id:
            return jsonify({"error": "Missing user_id"}), 400

        # Fetch data from Firestore
        user_ref = db.collection('Spendlys').document(user_id)
        user_doc = user_ref.get()

        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404

        user_data = user_doc.to_dict()
        expenses = []

        # MODIFIED: Access transactions field first
        transactions = user_data.get('transactions', {})
        
        # Extract and format expenses from transactions
        for category, items in transactions.items():
            if category.lower() == 'income':
                continue 
            if isinstance(items, list):
                for item in items:
                    if 'date' in item and 'amount' in item:
                        expenses.append({
                            'ds': item['date'],
                            'y': item['amount'],
                            'category': category
                        })

        app.logger.debug(f"Expenses extracted: {expenses}")

        # Convert to DataFrame
        df = pd.DataFrame(expenses)
        df['ds'] = pd.to_datetime(df['ds'], format='ISO8601')

        # Aggregate expenses by category and date
        df = df.groupby(['category', 'ds'])['y'].sum().reset_index()

        app.logger.debug(f"Aggregated DataFrame: {df}")

        # Run Prophet model for each category to predict next month's total expenses
        predictions = {}
        for category in df['category'].unique():
            # Filter data for the current category
            category_df = df[df['category'] == category]

            # Calculate data sufficiency score
            sufficiency_score = calculate_data_sufficiency(category_df)
            app.logger.debug(f"Data sufficiency score for {category}: {sufficiency_score}")

            # Use Prophet only if the data is sufficiently reliable
            if sufficiency_score > 0.5:  # Adjust threshold as needed
                # Prepare data for Prophet
                prophet_df = category_df[['ds', 'y']].rename(columns={'ds': 'ds', 'y': 'y'})

                # Adjust Prophet model for sparse data
                model = adjust_for_sparse_data(prophet_df)

                # Predict for the next month
                future = model.make_future_dataframe(periods=30, freq='D')  # Predict next 30 days
                forecast = model.predict(future)

                # Get the predicted total for the next month
                next_month_total = forecast.tail(30)['yhat'].sum()  # Sum predictions for the next 30 days
            else:
                # Use the mean of past monthly expenses as the fallback method
                next_month_total = calculate_monthly_mean(category_df)
                app.logger.debug(f"Using fallback method for {category}: {next_month_total}")

            # Store the prediction
            predictions[category] = next_month_total

        # Log predictions
        app.logger.debug(f"Predictions: {predictions}")

        return jsonify(predictions)
    except Exception as e:
        app.logger.error(f"Error: {e}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)