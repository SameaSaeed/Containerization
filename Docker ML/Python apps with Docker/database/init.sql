-- Initialize the Flask application database
-- This script runs when the PostgreSQL container starts

-- Create visitors table
CREATE TABLE IF NOT EXISTS visitors (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    visit_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET,
    user_agent TEXT
);

-- Insert some sample data
INSERT INTO visitors (name, ip_address) VALUES 
    ('Docker Lab Student', '127.0.0.1'),
    ('Container Enthusiast', '192.168.1.100'),
    ('Python Developer', '10.0.0.1');

-- Create an index for better performance
CREATE INDEX IF NOT EXISTS idx_visitors_visit_time ON visitors(visit_time);

-- Grant permissions
GRANT ALL PRIVILEGES ON TABLE visitors TO flaskuser;
GRANT USAGE, SELECT ON SEQUENCE visitors_id_seq TO flaskuser;