# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provider "google" {
  project = "${var.project_id}"
}

resource "google_bigquery_dataset" "datasets" {
  for_each = local.datasets

  project                     = var.project_id
  dataset_id                  = each.value["dataset_id"]
  friendly_name               = each.value["friendly_name"]
  description                 = each.value["description"]
  location                    = each.value["location"]

}

resource "google_bigquery_table" "tables" {
  for_each = local.tables

  project                     = var.project_id
  dataset_id                  = each.value["dataset_id"]
  table_id                    = each.value["table_id"]
  schema                      = jsonencode(each.value.schema)
  deletion_protection         = false
  dynamic "time_partitioning" {
   for_each = each.value.time_partitioning != null ? [each.value.time_partitioning] : [] 
   content{
     type  = each.value.time_partitioning.type
     field = each.value.time_partitioning.field
     require_partition_filter = each.value.time_partitioning.require_partition_filter
     expiration_ms = try(each.value.time_partitioning._ms, null)
    }
  }
  depends_on = [ google_bigquery_dataset.datasets ]
}
