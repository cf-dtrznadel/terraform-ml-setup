terraform {
	required_providers {
		google = {
			source = "hashicorp/google"
			version = "6.17.0"
		}
	}
}

provider "google" {
	project = "learn-vertex-pipelines"
	region = "europe-central2"
	zone = "europe-central2-a"
}

# Create the VPC network
resource "google_compute_network" "vpc_network_dominik" {
  name                            = "vpc-network-dominik-implementation"
  project                         = "learn-vertex-pipelines"
  auto_create_subnetworks         = false
  mtu                             = 1460
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false
}

# Create the subnet
resource "google_compute_subnetwork" "subnet_beans" {
  name          = "subnet-beans"
  project       = "learn-vertex-pipelines"
  ip_cidr_range = "10.0.0.0/8"
  region        = "europe-central2"
  network       = google_compute_network.vpc_network_dominik.id
  stack_type    = "IPV4_ONLY"
}

resource "google_compute_address" "compute_address_dominik" {
  name = "compute-address-dominik"
  address_type = "EXTERNAL"
  region       = "europe-central2"
}

# bucket
resource "google_storage_bucket" "GCS-dominik" {
	name = "ml-training-bucket-dominik_0001"
	location = "europe-central2"
    project  = "learn-vertex-pipelines"
}

# bucket
resource "google_storage_bucket" "GCS-dominik-2" {
	name = "ml-training-bucket-dominik_2332"
	location = "europe-central2"
    project  = "learn-vertex-pipelines"
}

# workbench
resource "google_workbench_instance" "my_workbench" {
  name     = "ml-training-workbench-dominik-vpc"
  location = "europe-central2-a"
  project  = "learn-vertex-pipelines"

  gce_setup {
    machine_type = "n2-standard-2"

    boot_disk {
      disk_size_gb = 150
    }

    data_disks {
      disk_size_gb  = 100
    }

    network_interfaces {
      network = google_compute_network.vpc_network_dominik.id
      subnet = google_compute_subnetwork.subnet_beans.id
      nic_type = "GVNIC"
      access_configs {
        external_ip = google_compute_address.compute_address_dominik.address
      }
    }
    metadata = {
      idle-timeout-seconds = "1800"  # 3 hours in seconds
    }
  }



  desired_state = "ACTIVE"
}

data "google_iam_policy" "iam_policy_workbench" {
  binding {
    role = "roles/notebooks.viewer"
    members = [
      "user:trznadel.dom@gmail.com"
    ]
  }
  binding {
    role = "roles/notebooks.admin"
    members = [
      "user:dominik.vertex.ai@gmail.com"
    ]
  }
}


data "google_iam_policy" "iam_policy_bucket" {
  binding {
    role = "roles/storage.admin"
    members = [
      "user:dominik.vertex.ai@gmail.com"
    ]
  }
  binding {
    role = "roles/storage.objectAdmin"
    members = [
      "user:dominik.vertex.ai@gmail.com"
    ]
  }
}

resource "google_workbench_instance_iam_policy" "workbench_policy_dominik" {
  project = google_workbench_instance.my_workbench.project
  location = google_workbench_instance.my_workbench.location
  name = google_workbench_instance.my_workbench.name
  policy_data = data.google_iam_policy.iam_policy_workbench.policy_data
}

resource "google_storage_bucket_iam_policy" "bucket_policy_dominik" {
  bucket      = google_storage_bucket.GCS-dominik.name
  policy_data = data.google_iam_policy.iam_policy_bucket.policy_data
}