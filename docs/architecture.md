# System Architecture

## Query Flow

```
User sends message via Chat UI
         │
         ▼
    n8n Webhook receives POST { query, email, channel }
         │
         ▼
    Set Input Fields (normalize data)
         │
         ▼
    OpenAI - Classify Intent
    → Returns: { intent, confidence, extracted_email }
         │
         ▼
    Parse Classification (Code node)
    → Determines route: db_lookup | rag_search | ask_email | escalate | greeting
         │
         ▼
    Route Query (Switch node — 5 outputs)
         │
    ┌────┼────────┬──────────┬──────────┐
    ▼    ▼        ▼          ▼          ▼
  DB   RAG    Ask Email  Escalate   Greeting
Lookup Search  Response  Response   Response
    │    │        │          │          │
    ▼    │        │          │          │
 Check   │        │          │          │
 Match   │        │          │          │
Results  │        │          │          │
    │    │        │          │          │
  ┌─┼─┐  │        │          │          │
  ▼ ▼ ▼  │        │          │          │
 No S  M  │        │          │          │
 Mt in ul  │        │          │          │
 ch gl ti  │        │          │          │
    e  pl  │        │          │          │
    │  e   │        │          │          │
    │  │   │        │          │          │
    ▼  ▼   │        │          │          │
  OpenAI   │        │          │          │
 Generate  │        │          │          │
 Response  │        │          │          │
    │      │        │          │          │
    └──────┴────────┴──────────┴──────────┘
                    │
                    ▼
           Merge All Responses
                    │
                    ▼
           Log to query_logs (Supabase)
                    │
                    ▼
           Send Response to Chat UI
```

## Routing Logic

| Intent | Has Email? | Confidence | Route |
|--------|-----------|------------|-------|
| book_status | Yes | ≥80% | DB Lookup |
| book_status | No | Any | Ask Email |
| book_status | Yes | <80% | Escalate |
| general_inquiry | Any | Any | RAG Search |
| greeting | Any | Any | Greeting Response |

## Error Handling

| Scenario | Behavior |
|----------|----------|
| DB connection fails | "Our systems are temporarily updating..." |
| No author found in DB | Routes to RAG as fallback |
| Multiple authors match | "Could you confirm your email or book title?" |
| Confidence < 80% | Escalates to human support |
| RAG returns no context | "I don't have specific information, let me connect you with our team" |

## Identity Unification (Task 2)

Three-layer matching:
1. **Exact Match** — email or phone lookup → 100% confidence
2. **Fuzzy Match** — LLM compares names, handles, patterns → variable confidence
3. **Confidence Routing** — ≥90% auto-link, 70-89% flag for review, <70% manual verification
