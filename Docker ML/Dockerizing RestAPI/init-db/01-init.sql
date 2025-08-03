-- Create sample users after table creation
INSERT INTO users (name, email) VALUES 
    ('Alice Johnson', 'alice@example.com'),
    ('Bob Wilson', 'bob@example.com'),
    ('Carol Brown', 'carol@example.com')
ON CONFLICT (email) DO NOTHING;