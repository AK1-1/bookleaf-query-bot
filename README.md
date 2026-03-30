# BookLeaf Publishing — AI Customer Query Bot

An intelligent, multi-channel-ready customer query bot built for BookLeaf Publishing's author support operations. The system handles natural language queries from authors about publishing timelines, royalties, dashboard access, add-on services, and more — using a combination of database lookups and RAG-powered knowledge base search.

**Built by:** Achyuth Kumar P  
**Assessment for:** AI Automation Specialist — BookLeaf Publishing  

---

## Architecture

```
Author (Chat UI)
    → Webhook (n8n)
        → OpenAI: Classify intent + extract identifiers
        → Route Query:
            ├── DB Lookup    → Supabase authors table → OpenAI response
            ├── RAG Search   → Supabase pgvector KB → OpenAI response
            ├── Ask Email    → Prompt user for email
            ├── Escalation   → Low confidence fallback
            └── Greeting     → Friendly reply
        → Log query to Supabase
        → Return response to chat
```

## Tech Stack

| Component | Tool | Why |
|-----------|------|-----|
| Workflow Orchestration | **n8n** (self-hosted) | Full control over conditional logic, error handling, sub-workflows. Certified L1 & L2 Creator |
| Database | **Supabase** (PostgreSQL + pgvector) | Specified in assignment. Handles both structured data and vector search |
| LLM | **OpenAI GPT-5.4-mini** | Fast, cost-effective for classification and response generation |
| Embeddings | **OpenAI text-embedding-3-small** | Used via n8n's Supabase Vector Store node for KB embeddings |
| Chat Interface | **Lovable** (HTML/JS) | Rapid frontend deployment with clean UI |

## Features

### Mandatory Task: Customer Query Bot

- **Intent Classification:** OpenAI classifies queries into 7 intents (book_status, royalty_inquiry, dashboard_access, addon_status, book_sales, author_copy, general_inquiry) + greeting detection
- **Smart Routing:** Routes to DB lookup for account-specific queries, RAG for general questions, and asks for email when needed
- **Supabase DB Lookup:** Fetches author-specific data (book status, royalty, add-ons, ISBN, etc.) from the `authors` table
- **RAG Knowledge Base:** 80+ embedded KB chunks from BookLeaf's official FAQ document, searchable via pgvector semantic search
- **Confidence-based Escalation:** Queries with <80% confidence are escalated to human support
- **Error Handling:** Graceful fallbacks for DB errors, no-match results, and multiple matches
- **Query Logging:** Every query, response, intent, confidence score, and escalation status logged to `query_logs` table
- **Chat Interface:** Clean web UI with email capture, typing indicators, and escalation styling

### Intermediate Task: Identity Unification

- **Flowchart Design:** Three-layer matching system (Exact → Fuzzy/LLM → Confidence routing)
- **Database Schema:** `author_identities` table linking authors across email, WhatsApp, Instagram, and dashboard platforms
- **Confidence Scoring:** Auto-link (≥90%), flag for review (70-89%), verify manually (<70%)
- **Mock Data:** Sample identity records for demonstration

## Folder Structure

```
bookleaf-query-bot/
├── README.md
├── workflows/
│   ├── BookLeaf_Query_Bot.json          # Main n8n workflow (import this)
│   └── BookLeaf_KB_Ingestion.json       # KB embedding ingestion workflow
├── database/
│   ├── setup.sql                        # Full Supabase schema + mock data
│   └── match_documents.sql              # Vector search function for n8n
├── frontend/
│   └── index.html                       # Chat UI (deployed on Lovable)
├── docs/
│   ├── screenshots/                     # Workflow & UI screenshots
│   │   ├── n8n-workflow-overview.png
│   │   ├── chat-ui-demo.png
│   │   ├── supabase-tables.png
│   │   └── identity-unification-flowchart.png
│   └── architecture.md                  # System design notes
└── loom-video.md                        # Loom video link
```

## Setup Instructions

### 1. Supabase Setup

1. Create a new Supabase project
2. Run `database/setup.sql` in the SQL Editor — creates all tables, indexes, mock data, and the `match_documents` function
3. Run `database/match_documents.sql` if the function wasn't created in step 2

### 2. n8n Workflow Setup

1. Import `workflows/BookLeaf_Query_Bot.json` into n8n
2. Configure credentials:
   - **OpenAI API** — your OpenAI key
   - **Supabase** — project URL + service role key
3. Import `workflows/BookLeaf_KB_Ingestion.json` and run it once to populate KB embeddings
4. Activate the main workflow

### 3. Frontend Setup

1. Deploy `frontend/index.html` on Lovable (or any static host)
2. Update the `N8N_WEBHOOK_URL` constant in the HTML to your n8n webhook URL
3. Test the chat interface

## Query Examples

| Query | Route | Expected Response |
|-------|-------|-------------------|
| "Is my book live?" (no email) | Ask Email | "I'd need your registered email..." |
| "Is my book live?" (with sara.johnson@xyz.com) | DB Lookup | "Your book Whispers of the Wind went live on January 20, 2026" |
| "What's the minimum requirement for submission?" | RAG Search | "Submit at least 18 poems during the 21-day challenge..." |
| "What does the ₹1999 cover?" | RAG Search | Publishing package details from KB |
| "Hello, I have a query" | Greeting | Friendly welcome message |
| "asdfghjkl" | Escalation | "Let me connect you with our support team..." |

## Database Schema

### `authors` — Author account data
| Field | Type | Description |
|-------|------|-------------|
| email | text | Registered email |
| author_name | text | Full name |
| book_title | text | Published book title |
| final_submission_date | date | Manuscript submission date |
| book_live_date | date | Publication date |
| royalty_status | text | pending / processed / paid / under_review |
| isbn | text | Assigned ISBN |
| add_on_services | jsonb | Bestseller package, PR, award status |
| dashboard_access | boolean | Dashboard active/inactive |
| author_copy_status | text | shipped / delivered / not_yet |

### `query_logs` — All bot interactions logged
| Field | Type | Description |
|-------|------|-------------|
| query_text | text | Author's question |
| intent_classified | text | Detected intent |
| confidence_score | numeric | Classification confidence (0-100) |
| escalated | boolean | Whether query was escalated |
| error_type | text | no_match / low_confidence / db_down / null |

### `knowledge_base` — RAG-searchable KB
| Field | Type | Description |
|-------|------|-------------|
| content | text | KB text chunk |
| metadata | jsonb | Topic tags |
| embedding | vector(1536) | OpenAI embedding for semantic search |

### `author_identities` — Identity unification (Task 2)
| Field | Type | Description |
|-------|------|-------------|
| author_id | uuid | FK to authors table |
| platform | text | email / whatsapp / instagram / dashboard |
| identifier | text | The actual email/phone/handle |
| confidence_score | numeric | Match confidence |
| verified | boolean | Manually verified or not |

## Self-Rating

| Skill | Rating | Notes |
|-------|--------|-------|
| n8n / Make / Zapier | **9/10** | Certified n8n L1 & L2, Verified Creator, 30+ production workflows |
| OpenAI / LangChain integrations | **7/10** | Extensive OpenAI integration in production. Basic LangChain — I primarily use direct API calls and n8n AI nodes |
| System Design & Troubleshooting | **8/10** | Designed multi-system integrations with error handling, race condition fixes, and production debugging |

## What I'd Improve With More Time

1. **Multi-channel ingestion** — Native WhatsApp Business API, Gmail parsing, Instagram DM via Meta Graph API
2. **Conversation memory** — Store context in Supabase so follow-up questions work naturally
3. **Human handoff dashboard** — UI for support agents to see and resolve escalated queries
4. **Identity unification working demo** — Full n8n workflow with LLM-based fuzzy matching
5. **Analytics dashboard** — Track common query types, confidence scores, escalation rates
6. **Auto-learning** — Feed resolved escalations back into the KB

## Live Links

🌐 **Chat UI (Lovable):** (https://preview--bookleaf-companion.lovable.app/)

📊 **Identity Unification Flowchart (Figma):** (https://www.figma.com/board/KVjupvdLLVEoZR0lFeO9xP/BookLeaf-Identity-Unification-Logic?node-id=0-1&t=nwAzGEERZTu7opm8-1)

## Loom Video

🎥 [Watch the walkthrough here] (https://www.tella.tv/video/ai-automation-system-demo-n8n-supabase-openai-267i)

---

**Built with n8n, Supabase, OpenAI, and Lovable**
