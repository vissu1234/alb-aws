terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------------------------------------------------
# 1️⃣ Enable Required APIs
# ---------------------------------------------------------------------
resource "google_project_service" "enable_apis" {
  for_each = toset([
    "aiplatform.googleapis.com",
    "discoveryengine.googleapis.com",
    "iam.googleapis.com"
  ])
  project = var.project_id
  service = each.key
}

# ---------------------------------------------------------------------
# 2️⃣ Service Account for Agent
# ---------------------------------------------------------------------
resource "google_service_account" "agent_sa" {
  account_id   = "vertex-agent-sa"
  display_name = "Vertex AI Agent Service Account"
}

# Assign minimal permissions
resource "google_project_iam_member" "agent_sa_roles" {
  for_each = toset([
    "roles/aiplatform.user",
    "roles/storage.objectViewer",
    "roles/logging.logWriter"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.agent_sa.email}"
}

# ---------------------------------------------------------------------
# 3️⃣ Vertex AI Search Engine (Knowledge Base)
# ---------------------------------------------------------------------
resource "google_discovery_engine_data_store" "kb_datastore" {
  project        = var.project_id
  location       = "global"
  data_store_id  = "support-knowledge-base"
  display_name   = "Support Knowledge Base"

  content_config {
    gcs_source {
      input_uris = ["gs://${var.kb_bucket}/docs/*.pdf"]
    }
  }
}

resource "google_discovery_engine_search_engine" "search_engine" {
  project       = var.project_id
  location      = "global"
  display_name  = "Support Search Engine"
  data_store_id = google_discovery_engine_data_store.kb_datastore.data_store_id
  solution_type = "SOLUTION_TYPE_SEARCH"
}

# ---------------------------------------------------------------------
# 4️⃣ Vertex AI Agent Builder Agent
# ---------------------------------------------------------------------
resource "google_vertex_ai_agent" "support_agent" {
  display_name = "Support Assistant"
  description  = "Provides help by retrieving product info and docs"
  location     = var.region
  model        = "gemini-1.5-pro"
  instructions = <<-EOT
You are a helpful support assistant. 
Use the linked knowledge base to answer customer queries clearly and accurately.
EOT

  # Link Search Engine as Knowledge Connector
  knowledge_connector {
    search_engine = google_discovery_engine_search_engine.search_engine.name
  }

  service_account = google_service_account.agent_sa.email
}

# ---------------------------------------------------------------------
# 5️⃣ Output for API Calls
# ---------------------------------------------------------------------
output "agent_name" {
  value = google_vertex_ai_agent.support_agent.name
}

output "search_engine_name" {
  value = google_discovery_engine_search_engine.search_engine.name
}
