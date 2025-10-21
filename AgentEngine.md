When you create an Agent Builder agent (via console, Terraform, or API), Agent Engine is automatically provisioned and used by Google Cloud in the background.

There is no separate Terraform resource called agent_engine you need to create.

All you manage are:

The Agent Builder agent (its config, model, instructions)

Service account / permissions

Optional knowledge bases or connectors

Agent Engine is always there — it’s the runtime that powers your agent. You don’t need to provision it.

################################################################################
What you actually need to focus on : 

Agent Builder Agent config – Make sure your agent points to the correct Vertex AI model (Gemini/PaLM)

Service account permissions – Workbench / other clients must have access to call the agent

Knowledge sources (optional) – GCS / BigQuery / Web if doing RAG

Calling the agent – via Python SDK, REST API, or other clients
