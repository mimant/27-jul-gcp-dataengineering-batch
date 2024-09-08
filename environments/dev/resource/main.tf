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
  region = "${var.region_id}" 
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


resource "google_storage_bucket" "buckets" {
  for_each = local.buckets

  project = var.project_id
  name = format("%s-%s",var.project_id,each.value["name"])
  location = each.value["location"]
  storage_class = each.value["storage_class"]
}

#create the current project workflows to be deployed

resource "google_workflows_workflow" "workflows_example" {
  for_each = local.workflows_list
  name            = format("%s-%s-%s", var.project_id,"wkf",basename(each.key))
  project         = var.project_id
  region          = var.region_id
  description     = each.key
  # Import main workflow and subworkflow YAML files
  source_contents = each.value
}

#create the current project schedulers to be deployed

resource "google_cloud_scheduler_job" "schedulers" {
  for_each = local.schedulers_list

  name            = format("%s-%s",var.project_id, each.value.name)
  project         = var.project_id
  schedule        = try(each.value.schedule, null)
  description     = try(each.value.description, null)
  time_zone       = try(each.value.time_zone, null)
  attempt_deadline = try(each.value.attempt_deadline, null)

  dynamic "retry_config" {
   for_each = try(each.value.retry_config, null) != null ? [1] : []

   content {
    retry_count    = try(each.value.retry_config.retry_count, null)
    max_retry_duration  = try(each.value.retry_config.max_retry_duration, null)
    min_backoff_duration = try(each.value.retry_config.min_backoff_duration, null)
    max_backoff_duration = try(each.value.retry_config.max_backoff_duration, null)
    max_doublings = try(each.value.retry_config.max_doublings, null)

   }

  }

  dynamic "http_target" {
   for_each = try(each.value.http_target, null) != null ? [1] : []
   content {
    uri = each.value.http_target.uri
    http_method = try(each.value.http_target.http_method, null)
    body = try(base64encode(try(each.value.http_target.body,null)), null)
    headers = try(each.value.http_target.headers, null)

      dynamic "oauth_token"{
       for_each = try(each.value.http_target.oauth_token, null) != null ? [1] : []
       content {
        service_account_email = each.value.http_target.oauth_token.service_account_email
        scope                 = try(each.value.http_target.oauth_token.scope, null)

         }
        }
       }
      }
     }

## Create the cloud run functions

resource "google_cloudfunctions2_function" "cloudfunctions" {
  for_each = local.cloudfunctions_list
   name            = each.value.name
   location        = each.value.location
   description     = try(each.value.description, null)

   dynamic "build_config" {
    for_each = try(each.value.build_config, null) != null ? [1] : []

    content {
     runtime  = try(each.value.build_config.runtime, null)
     entry_point   = try(each.value.build_config.entry_point , null)

       dynamic "source" {
        for_each = try(each.value.build_config.source, null) != null ? [1] : []

        content{
          dynamic "storage_source" {
          for_each = try(each.value.build_config.source.storage_source, null) != null ? [1] : []

        content{
           bucket = each.value.build_config.source.storage_source.bucket
           object = each.value.build_config.source.storage_source.object
             }
            }
           }
          }
         }
        }

     dynamic "service_config" {
      for_each = try(each.value.service_config, null) != null ? [1] : []
      content {
        min_instance_count = try(each.value.service_config.min_instance_count, null)
        available_memory = try(each.value.service_config.available_memory, null)
        timeout_seconds = try(each.value.service_config.timeout_seconds, null)
        service_account_email = try(each.value.service_config.service_account_email, null)
		dynamic "secret_environment_variables"{
		 for_each = try(each.value.service_config.secret_environment_variables, null) != null ? [1] : []
		 content{
		  project_id = try(each.value.service_config.secret_environment_variables.project_id, null)
		  version    = try(each.value.service_config.secret_environment_variables.version, null)
		  }
		 }
       }
     }

     dynamic "event_trigger" {
      for_each = try(each.value.event_trigger, null) != null ? [1] : []
      content {
       trigger_region = try(each.value.event_trigger.trigger_region, null)
       event_type = try(each.value.event_trigger.event_type, null)
       service_account_email = try(each.value.event_trigger.service_account_email, null)

       dynamic "event_filters"  {
        for_each = try(each.value.event_trigger.event_filters, null) != null ? [1] : []
        content{
          attribute =  try(each.value.event_trigger.event_filters.attribute, null)
          value  =  try(each.value.event_trigger.event_filters.value, null)
        }
       }
      }
     }
    }