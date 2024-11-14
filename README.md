# GCP Terraform Infrastructure Setup

This repository provides a Terraform configuration for setting up a GCP-based infrastructure to host a private Google Cloud Storage bucket accessible through an HTTPS load balancer, with SSL certificate management and IAM configurations. The setup is divided into several environment-specific configurations (e.g., `dev`), allowing flexibility in managing multiple environments like `dev`, `prod`, etc.

## Structure and Purpose

- **`dev/` Folder**: Contains environment-specific configurations, such as backend state settings and unique values for the development environment.
  - **Backend State**: Stored in a GCS bucket (`tf-xdatalab-state`) with a specific prefix (`tf-dev`) indicating where the state files are stored.
  - **Values**: Each environment has unique variables defined in `values.tfvars`.

## Key Terraform Files

### `alb.tf`

This file configures the HTTPS load balancer with global forwarding rules, URL maps, and target proxies.

#### Resources and Dependencies

- **Global Address (`google_compute_global_address`)**: Creates an external global IP address for the load balancer, conditional on `create_global_address`.
- **Global Forwarding Rules**: Sets up forwarding rules for both HTTP and HTTPS traffic, with HTTPS targeting the `alb_https_target_proxy` and HTTP targeting the `alb_http_target_proxy`.
- **URL Maps**:
  - **HTTPS Redirect (`https_redirect_url_map`)**: Redirects all HTTP traffic to HTTPS for improved security.
  - **Primary URL Map (`alb_url_map`)**: Routes traffic to the backend service, with specific header actions to remove cookies.
- **Target Proxies**:
  - **HTTP Target Proxy**: Used for handling HTTP requests and redirecting them to HTTPS.
  - **HTTPS Target Proxy**: Used for secure HTTPS connections, linked to the SSL certificates.
- **Backend Service (`google_compute_backend_service`)**:
  - Serves as the backend for the load balancer, connected to the private bucket. This includes custom headers and AWS V4 authentication for GCS.

### `gcloudst.tf`

This file manages the storage resources for GCS.

#### Resources and Dependencies

- **Private Bucket (`google_storage_bucket`)**: Creates a secure bucket with enforced access control and optional versioning.
- **HMAC Key (`google_storage_hmac_key`)**: Generates HMAC credentials linked to a service account for secure access to the private bucket.

### `iam.tf`

This file manages IAM configurations, specifically service accounts and access control for the storage bucket.

#### Resources and Dependencies

- **Service Account (`google_service_account`)**: Created specifically for accessing the private bucket.
- **Bucket IAM Member (`google_storage_bucket_iam_member`)**: Grants `objectViewer` role to the service account, enabling it to read objects in the bucket. This resource depends on the bucket creation (`google_storage_bucket.private_bucket`).

### `locals.tf`

Defines local variables used throughout the Terraform configuration, particularly for IP addresses and domain names.

#### Key Points

- **Dynamic Address and Domain Handling**: Sets local values based on whether a global address or DNS record is created, allowing flexibility in configurations.

### `networkseg.tf`

Contains network endpoint configurations for connecting the bucket to the backend service.

#### Resources and Dependencies

- **Network Endpoint Group**: Configures a global endpoint for the backend, linking it to the bucket’s FQDN.
- **Network Endpoint**: Specifies the bucket’s FQDN as the endpoint for connecting to the private bucket backend.

### `providers.tf`

Defines required providers and backend configurations for Terraform state management.

#### Key Points

- **Provider Versions**: Specifies the required version for Google providers to ensure compatibility.
- **GCS Backend**: Configures a GCS backend with bucket and prefix variables for state management, enabling state segregation across environments.

### `tls.tf`

Manages SSL certificate resources for HTTPS traffic on the load balancer.

#### Resources and Purpose

- **Managed SSL Certificate**: Google-managed SSL certificate for the HTTPS proxy, created if `create_certs` is true. This takes approximately 24 hours for issuance.
- **Self-Signed SSL Certificate**: Used for testing purposes if managed SSL is not required. Not recommended for production as it is in our lab 
 by the was to generate ssl can use 
 openssl genrsa -out tf-xdatalab1t.net.key 2048\n
 openssl req -new -key tf-xdatalab1t.net.key -out tf-xdatalab1t.net.csr\n
 openssl x509 -req -days 365 -in tf-xdatalab1t.net.csr -signkey tf-xdatalab1t.net.key -out tf-xdatalab1t.net.crt

 it will not works for sure becayse domain not real but when you open browser you push continue and content will be opened , but red warning in SSL  for this lab you can ignore
 

 p.s to open website   write  domain name and forntent public ip to your hosts
 
---

## Configuration and Usage

1. **Backend Configuration**: Set up backend state in `backend.hcl` to manage state files for each environment.
2. **Environment Variables**: Unique environment values should be specified in `values.tfvars` for customization across environments.
3. **SSL Management**: Toggle `create_certs` for managed vs. self-signed SSL certificate generation.
4. **Domain Handling**: Define `dns_zone` and `domain_name` for custom DNS and load balancer configuration.

## Notes

- **Resource Dependencies**: Each resource depends on others logically to ensure proper ordering and functionality, such as IAM member roles depending on bucket creation.
- **SSL Flexibility**: Provides flexibility between managed and self-signed SSL certificates for testing and production use cases.
- **Backend State Segregation**: Using GCS backend configuration allows isolated state management across environments within the same bucket by setting different prefixes.

---


# GCP Terraform Infrastructure Setup

This repository provides a Terraform configuration for setting up a GCP-based infrastructure to host a private Google Cloud Storage bucket accessible through an HTTPS load balancer, with SSL certificate management and IAM configurations. The setup is divided into several environment-specific configurations (e.g., `dev`), allowing flexibility in managing multiple environments like `dev`, `prod`, etc.

## Preparation

Before running this Terraform configuration, you need to complete a few preparation steps to set up your Google Cloud Platform (GCP) environment and configure your local machine.

### 1. Create a Google Cloud Account

- If you don’t already have a Google Cloud account, [sign up for a free account](https://cloud.google.com/free).
- Google offers $300 in free credits for new users

### 2. Set Up a Service Account with Proper Permissions

- In the **Google Cloud Console**, navigate to **IAM & Admin > Service Accounts**.
- Create a new service account with a meaningful name (e.g., `terraform-admin`).
- Grant the **Owner** role to this service account for admin access(for tetsing purpose its ok) (or limit it based on your specific requirements(recoomended)).
- Generate a **JSON key** for this service account and download it to your machine. This key will be used for authentication.

### 3. Install the Google Cloud SDK

- [Download and install the Google Cloud SDK](https://cloud.google.com/sdk/docs/install).
- After installation, authenticate with Google Cloud by running:

  ```bash
  gcloud auth login
  gcloud auth application-default login

Purpose: Authenticates applications running on your local machine, setting up application-level credentials for Google Cloud APIs.
Usage: This command is used to set the Application Default Credentials (ADC), allowing applications to authenticate with Google Cloud APIs in a way that simulates how they would run in infra
::::::When you run gcloud auth application-default login, it opens a browser window for authentication, then stores the credentials in a JSON file in a specific location (~/.config/gcloud/application_default_credentials.json). These credentials are used by Google Cloud client libraries (like google-auth ) to authenticate requests. terraform will use for example


==================

                    open url   ( in our test case tf-xdatalab1t.net)
                       |
          +---------------------------+
          |     Global HTTPS Proxy    |
          +---------------------------+
                       |
             External Forwarding Rules
                       |
              Target HTTPS Proxy ---- SSL Certificates
                       |
                    URL Map
                       |
                 Backend Service (CDN)
                       |
            Network Endpoint Group ---- Network Endpoint (GCS Bucket)
                       |
                 Google Cloud Storage Bucket



GCP CDN and HTTPS Load Balancer Architecture
This setup represents a GCP (Google Cloud Platform) infrastructure for serving content stored in a Google Cloud Storage (GCS) bucket through a Content Delivery Network (CDN) using an HTTPS Load Balancer with SSL certificates.

Architecture Overview
This architecture consists of several components working together to provide secure, scalable content delivery using Google Cloud’s CDN and load balancing capabilities.

1. User and Internet Access
User: The end-user accesses the content over HTTPS through the internet.
Internet: The user’s request travels through the internet, reaching the GCP infrastructure.
2. Global External HTTPS Proxy
Global External HTTPS Proxy: Acts as an entry point for all HTTPS traffic from the internet, securely handling incoming user requests.
3. External Forwarding Rule and Reserved IP Address
External Forwarding Rule: Directs incoming traffic from the internet to the Target HTTPS Proxy based on the reserved IP and specified port (typically 443 for HTTPS).
Reserved IP Address: A static IP address that routes traffic to the HTTPS proxy, ensuring consistent access for users.
4. Target HTTPS Proxy and SSL Certificate
Target HTTPS Proxy: Manages SSL termination for incoming HTTPS requests, forwarding them to the appropriate backend based on the URL map.
SSL Certificate: Provides SSL/TLS encryption for secure communication between the user and the load balancer. This can be a Google-managed or self-signed certificate depending on the environment.
5. URL Map
URL Map: Defines routing rules based on URL paths, directing traffic to the appropriate Backend Service (CDN). This enables path-based routing to various backends if needed.
6. Backend Service (CDN)
Backend Service (CDN): Connects the load balancer to the Network Endpoint Group containing the Google Cloud Storage bucket. CDN capabilities allow caching content close to the user, reducing latency and improving performance.
Custom Header: Allows for specific header management (e.g., setting the host header or picture name and e.s) to support routing needs and access control.
7. HMAC Credentials
HMAC Credentials: Used to authenticate requests to Google Cloud Storage. The backend service uses HMAC credentials to securely access the content stored in the bucket.
8. Network Endpoint Group and Network Endpoint
Network Endpoint Group: Contains network endpoints (individual FQDNs or IP addresses). In this architecture, it connects to the GCS bucket endpoint.
Network Endpoint (FQDN): Represents the Google Cloud Storage bucket via its Fully Qualified Domain Name, acting as the origin for the content served to users.
9. Google Cloud Storage Bucket
Google Cloud Storage Bucket: Stores static content (e.g., images, videos, files) to be served to users. The bucket is connected to the network endpoint group, enabling direct content access via the CDN.

## Summary


Serve content securely over HTTPS with SSL termination at the load balancer.
Leverage CDN caching to improve content delivery speeds and reduce latency.
Provide authentication for secure access to the storage bucket using HMAC credentials.
Enable flexible routing through URL maps and custom headers for tailored content delivery.


IT WILL TAKES LITTLE TIME BUT TO REFACTOR ALL THIS AS MODULAR < WOULD BE BETTER APROACH AS RE_USABILITY MODE>



                                       User Access
                                          |
                                          |
                                          ▼
                                  +------------------+
                                  |  User Request    |
                                  +------------------+
                                          |
                                          ▼
                                   +----------------+                      
                                   |   Internet     |
                                   +----------------+
                                          |
                                          ▼
                              +----------------------+
                              | Global HTTPS Proxy   |
                              |   Entry Point        |
                              +----------------------+
                                          |
                   +----------------------+----------------------+
                   |                                              |
                   ▼                                              ▼
        +---------------------------+              +---------------------------+
        | External Forwarding Rule  |              |   Reserved Static IP      |
        |  (Port 443 HTTPS)         |              |                           |
        +---------------------------+              +---------------------------+
                   |                                              |
                   |                                              |
                   +--------------------------+-------------------+
                                          ▼
                                 +---------------------+
                                 |  Target HTTPS Proxy |
                                 | (SSL Termination)   |
                                 +---------------------+
                                         / \
                                        /   \
                              +---------     -----------+
                              |                          |
                        SSL Certificates            SSL/TLS Termination
                      (Google-managed or custom)   (Decrypts traffic here)
                                          |
                                          ▼
                                +---------------------+
                                |       URL Map      |
                                | (Path-Based Routing)|
                                +---------------------+
                                          |
                  +------------------------+--------------------------+
                  |                        |                          |
                  ▼                        ▼                          ▼
      +-------------------+    +------------------------+   +-------------------------+
      | Backend Service   |    | Backend Service        |   | Backend Service         |
      | (GCS Bucket CDN)  |    | (Alternative CDN or    |   | (Versioned Content      |
      |                   |    | Additional Content)    |   | Paths if Needed)        |
      +-------------------+    +------------------------+   +-------------------------+
                  |
                  | Custom Header (e.g., Host Header for GCS bucket access)
                  | HMAC Credentials for GCS access
                  |
                  ▼
      +-------------------------+
      | Network Endpoint Group  |
      |   (Connects to GCS      |
      |    Bucket Endpoint)     |
      +-------------------------+
                  |
                  |
                  ▼
      +-------------------------+
      | Network Endpoint (FQDN) |
      | GCS Bucket (Origin)     |
      +-------------------------+
                  |
                  |
                  ▼
      +-------------------------+
      | Google Cloud Storage    |
      |   Bucket (Static        |
      |    Content)             |
      +-------------------------+

