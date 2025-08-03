-- Create tenant-specific schemas
CREATE SCHEMA IF NOT EXISTS tenant_a;
CREATE SCHEMA IF NOT EXISTS tenant_b;
CREATE SCHEMA IF NOT EXISTS tenant_c;

-- Create sample tables for each tenant
CREATE TABLE IF NOT EXISTS tenant_a.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_b.customers (
    id SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    contact_email VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tenant_c.analytics (
    id SERIAL PRIMARY KEY,
    event_name VARCHAR(100) NOT NULL,
    event_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample data
INSERT INTO tenant_a.users (username, email) VALUES 
    ('user1', 'user1@tenanta.com'),
    ('user2', 'user2@tenanta.com');

INSERT INTO tenant_b.customers (company_name, contact_email) VALUES 
    ('Company A', 'contact@companya.com'),
    ('Company B', 'contact@companyb.com');

INSERT INTO tenant_c.analytics (event_name, event_data) VALUES 
    ('page_view', '{"page": "/dashboard", "user_id": 123}'),
    ('button_click', '{"button": "submit", "form": "contact"}');