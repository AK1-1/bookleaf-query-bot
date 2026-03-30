-- =============================================
-- BookLeaf Query Bot - Supabase Setup
-- Run this entire script in Supabase SQL Editor
-- =============================================

-- 1. Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Authors table (main data)
CREATE TABLE IF NOT EXISTS authors (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  email TEXT NOT NULL,
  author_name TEXT,
  phone TEXT,
  book_title TEXT,
  final_submission_date DATE,
  book_live_date DATE,
  royalty_status TEXT,
  isbn TEXT,
  add_on_services JSONB,
  dashboard_access BOOLEAN DEFAULT true,
  author_copy_status TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Query logs table
CREATE TABLE IF NOT EXISTS query_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  query_text TEXT NOT NULL,
  intent_classified TEXT,
  author_email TEXT,
  response_text TEXT,
  confidence_score NUMERIC,
  escalated BOOLEAN DEFAULT false,
  source_channel TEXT,
  error_type TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Knowledge base table (RAG)
CREATE TABLE IF NOT EXISTS knowledge_base (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  content TEXT NOT NULL,
  metadata JSONB,
  embedding vector(1536),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 5. Author identities table (for Task 2: Identity Unification)
CREATE TABLE IF NOT EXISTS author_identities (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  author_id UUID REFERENCES authors(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  identifier TEXT NOT NULL,
  display_name TEXT,
  confidence_score NUMERIC,
  verified BOOLEAN DEFAULT false,
  linked_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Create index for vector search
CREATE INDEX IF NOT EXISTS kb_embedding_idx ON knowledge_base 
  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 10);

-- 7. Create index for email lookups
CREATE INDEX IF NOT EXISTS authors_email_idx ON authors (email);
CREATE INDEX IF NOT EXISTS identities_author_idx ON author_identities (author_id);

-- =============================================
-- MOCK DATA
-- =============================================

-- Authors
INSERT INTO authors (email, author_name, phone, book_title, final_submission_date, book_live_date, royalty_status, isbn, add_on_services, dashboard_access, author_copy_status) VALUES
('sara.johnson@xyz.com', 'Sara Johnson', '+919876543210', 'Whispers of the Wind', '2025-11-15', '2026-01-20', 'processed', '978-93-12345-01-1', '{"bestseller_package": "active", "pr": "completed", "award": "pending"}'::jsonb, true, 'delivered'),
('rahul.mehta@gmail.com', 'Rahul Mehta', '+919123456789', 'Code & Canvas', '2025-12-01', NULL, 'pending', '978-93-12345-02-8', '{"bestseller_package": "pending", "pr": "not_purchased"}'::jsonb, true, 'not_yet'),
('priya.sharma@outlook.com', 'Priya Sharma', '+918765432109', 'The Last Monsoon', '2025-10-20', '2025-12-15', 'paid', '978-93-12345-03-5', '{"bestseller_package": "completed", "pr": "active", "award": "shortlisted"}'::jsonb, true, 'delivered'),
('john.doe@email.com', 'John Doe', '+917654321098', 'Startup Diaries', '2026-01-10', NULL, 'under_review', '978-93-12345-04-2', '{"bestseller_package": "not_purchased", "pr": "not_purchased"}'::jsonb, false, 'not_yet'),
('ananya.reddy@gmail.com', 'Ananya Reddy', '+916543210987', 'Poetry in Motion', '2025-09-05', '2025-11-01', 'paid', '978-93-12345-05-9', '{"bestseller_package": "completed", "pr": "completed", "award": "won"}'::jsonb, true, 'shipped');

-- Author Identities (for Task 2 demo)
INSERT INTO author_identities (author_id, platform, identifier, display_name, confidence_score, verified) VALUES
((SELECT id FROM authors WHERE email = 'sara.johnson@xyz.com'), 'email', 'sara.johnson@xyz.com', 'Sara Johnson', 100, true),
((SELECT id FROM authors WHERE email = 'sara.johnson@xyz.com'), 'whatsapp', '+919876543210', 'Sara', 100, true),
((SELECT id FROM authors WHERE email = 'sara.johnson@xyz.com'), 'dashboard', 'sara.johnson@xyz.com', 'Sara J.', 100, true),
((SELECT id FROM authors WHERE email = 'sara.johnson@xyz.com'), 'instagram', '@sarapoetry23', 'Sara Poetry', 85, false),
((SELECT id FROM authors WHERE email = 'rahul.mehta@gmail.com'), 'email', 'rahul.mehta@gmail.com', 'Rahul Mehta', 100, true),
((SELECT id FROM authors WHERE email = 'rahul.mehta@gmail.com'), 'whatsapp', '+919123456789', 'Rahul M', 100, true),
((SELECT id FROM authors WHERE email = 'priya.sharma@outlook.com'), 'email', 'priya.sharma@outlook.com', 'Priya Sharma', 100, true),
((SELECT id FROM authors WHERE email = 'priya.sharma@outlook.com'), 'instagram', '@priyawrites', 'Priya Writes', 78, false);

-- =============================================
-- HELPER FUNCTION: Semantic search for RAG
-- =============================================

CREATE OR REPLACE FUNCTION match_knowledge_base(
  query_embedding vector(1536),
  match_threshold float DEFAULT 0.5,
  match_count int DEFAULT 3
)
RETURNS TABLE (
  id UUID,
  content TEXT,
  metadata JSONB,
  similarity float
)
LANGUAGE sql STABLE
AS $$
  SELECT
    knowledge_base.id,
    knowledge_base.content,
    knowledge_base.metadata,
    1 - (knowledge_base.embedding <=> query_embedding) AS similarity
  FROM knowledge_base
  WHERE 1 - (knowledge_base.embedding <=> query_embedding) > match_threshold
  ORDER BY knowledge_base.embedding <=> query_embedding
  LIMIT match_count;
$$;

-- =============================================
-- VERIFY SETUP
-- =============================================

SELECT 'Authors: ' || COUNT(*) FROM authors;
SELECT 'Identities: ' || COUNT(*) FROM author_identities;
SELECT 'Setup complete!' AS status;
