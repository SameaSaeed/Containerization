-- Create database for ML predictions
CREATE DATABASE ml_predictions;

-- Connect to the database
\c ml_predictions;

-- Create predictions table
CREATE TABLE predictions (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    features JSONB NOT NULL,
    prediction INTEGER NOT NULL,
    predicted_class VARCHAR(50) NOT NULL,
    probabilities JSONB NOT NULL,
    model_version VARCHAR(20) DEFAULT '1.0',
    request_id VARCHAR(100)
);

-- Create index on timestamp for better query performance
CREATE INDEX idx_predictions_timestamp ON predictions(timestamp);

-- Create index on predicted_class
CREATE INDEX idx_predictions_class ON predictions(predicted_class);

-- Create a view for daily prediction summary
CREATE VIEW daily_predictions AS
SELECT 
    DATE(timestamp) as prediction_date,
    predicted_class,
    COUNT(*) as prediction_count,
    AVG((probabilities->>predicted_class)::float) as avg_confidence
FROM predictions 
GROUP BY DATE(timestamp), predicted_class
ORDER BY prediction_date DESC, predicted_class;

-- Insert sample data for testing
INSERT INTO predictions (features, prediction, predicted_class, probabilities, request_id) VALUES
('[5.1, 3.5, 1.4, 0.2]', 0, 'setosa', '{"setosa": 0.95, "versicolor": 0.03, "virginica": 0.02}', 'test-001'),
('[6.2, 2.9, 4.3, 1.3]', 1, 'versicolor', '{"setosa": 0.05, "versicolor": 0.85, "virginica": 0.10}', 'test-002'),
('[7.3, 2.9, 6.3, 1.8]', 2, 'virginica', '{"setosa": 0.02, "versicolor": 0.08, "virginica": 0.90}', 'test-003');