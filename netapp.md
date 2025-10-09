# 🚀 Google Cloud NetApp Volumes (GNV)

**Google Cloud NetApp Volumes (GNV)** is a fully managed, enterprise-grade file storage service built on **NetApp ONTAP** technology and natively integrated into **Google Cloud Platform (GCP)**. It provides high-performance **NFS** and **SMB** file shares for applications requiring scalability, resilience, and simplicity.

---

## 🧩 Core Features
- **Fully Managed:** Google manages infrastructure, scaling, and maintenance.  
- **Protocol Support:** Supports **NFSv3**, **NFSv4.1**, and **SMB (CIFS)**.  
- **Performance Tiers:** *Standard* (general purpose), *Premium* (high performance), *Extreme* (ultra-low latency).  
- **Snapshots & Clones:** Point-in-time copies and zero-copy clones for Dev/Test workflows.  
- **Data Protection:** Replication and backup across regions.  
- **Security:** IAM integration, VPC Service Controls, and CMEK (Customer Managed Encryption Keys).  
- **Integration:** Works seamlessly with **Compute Engine**, **GKE**, **Cloud Run**, and **Anthos**.

---

## ⚙️ Architecture Overview




---

## 📦 Deployment Options
- **Regional Service:** High availability within a region (default).  
- **Zonal Service:** Optimized for single-zone workloads; lower cost.  
- **Cross-Region Replication:** Asynchronous replication for DR or compliance.

---

## 💰 Pricing
You are billed for:
- **Allocated storage capacity (GiB/month)**
- **Performance tier**
- **Snapshots and replication usage**

👉 [View official pricing](https://cloud.google.com/netapp/volumes/pricing)

---

## 🔐 Security & Compliance
- Data encrypted **at rest** and **in transit**.  
- Integrated with **Google Cloud IAM**.  
- Supports **VPC Service Controls**.  
- Complies with **HIPAA**, **ISO**, **SOC**, and **GDPR**.

---

## 🧠 Common Use Cases
| Use Case | Description |
|-----------|--------------|
| **Lift-and-Shift** | Move on-prem NetApp or NAS workloads to GCP |
| **Shared Storage for Containers** | Persistent NFS volumes for GKE |
| **AI/ML Data Lakes** | Shared access across compute clusters |
| **Databases** | Stateful apps (SAP, Oracle) using NFS/SMB |
| **Backup/DR** | Snapshots and replication for recovery |

---

## 🛠️ CLI Examples
**Create a NetApp Volume:**
```bash
gcloud netapp volumes create my-volume \
  --region=us-central1 \
  --network=default \
  --capacity=1000 \
  --protocols=NFSv3 \
  --tier=PREMIUM \
  --share-name=myshare

| API                                   | Purpose                                                    |
| ------------------------------------- | ---------------------------------------------------------- |
| `netapp.googleapis.com`               | Core NetApp Volumes API (main service endpoint).           |
| `compute.googleapis.com`              | Required for Compute Engine network access.                |
| `servicenetworking.googleapis.com`    | For private service access between GCP and NetApp systems. |
| `cloudresourcemanager.googleapis.com` | For project and IAM resource access.                       |




The roles/netapp.admin role provides full administrative access to all NetApp resources within a Google Cloud project, including:

Creating, updating, and deleting NetApp Volumes

Managing snapshots, replication, and storage pools

Viewing and managing volume configurations and connections

Full access to NetApp API (netapp.googleapis.com)
