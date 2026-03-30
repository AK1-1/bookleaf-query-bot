-- match_documents function required by n8n Supabase Vector Store node
-- Run this in Supabase SQL Editor

DROP FUNCTION IF EXISTS match_documents(vector, jsonb, int);

CREATE OR REPLACE FUNCTION match_documents(
  query_embedding vector(1536),
  filter jsonb DEFAULT '{}',
  match_count int DEFAULT 5
)
RETURNS TABLE (
  id uuid,
  content text,
  metadata jsonb,
  embedding vector(1536),
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    kb.id,
    kb.content,
    kb.metadata,
    kb.embedding,
    1 - (kb.embedding <=> query_embedding) AS similarity
  FROM knowledge_base kb
  WHERE kb.embedding IS NOT NULL
  ORDER BY kb.embedding <=> query_embedding
  LIMIT match_count;
END;
$$;
