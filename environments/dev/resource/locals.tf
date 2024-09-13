locals{

datasets = {
   for file in fileset(path.module, "datasets/*json") :
    file => ( jsondecode(file("${path.module}/${file}")))

 }

tables = {
   for file in fileset(path.module, "tables/*json") :
    file => ( jsondecode(file("${path.module}/${file}")))

 }

buckets = {
   for file in fileset(path.module, "buckets/*json") :
    file => ( jsondecode(file("${path.module}/${file}")))

 }

# Define a workflow

#prepare the list of workflows 

workflows_file_list  = fileset(path.module, "workflows/*yaml")
workflows_list_raw = {
  for file_path in local.workflows_file_list :
  trimsuffix(file_path, ".yaml") => "${file_path}" 
}


#prepare the list of required sub workflows 
subworkflows_file_list  = fileset(path.module, "subworkflows/*yaml")
subworkflows_list = [
  for file_path in local.subworkflows_file_list :
  "${file_path}"
]


## prepare final list of individual workflow and associated subworkflows

workflows_list = {
  for file_stem_path, file_path in local.workflows_list_raw:
  file_stem_path => join(
   "\n",
   concat(
    [templatefile(file_path, {project_id = var.project_id, bq_location = "EU"} )],
    [for sub_file in local.subworkflows_list: templatefile(sub_file, {project_id = var.project_id})]
   )
  )
}

 ##schedulers list to be deployed

 schedulers_file_list  = fileset(path.module, "schedulers/*json")
 schedulers_list_raw = {
  for file_path in local.schedulers_file_list :
  trimsuffix(file_path, ".json") => "${file_path}"
 }

 schedulers_list = {
  for file_stem_path, file_path in local.schedulers_list_raw:
    file_stem_path => jsondecode(templatefile(file_path, {project_id = var.project_id, region_id = var.region_id, env = var.env} ))
 }

 ##cloudfunction deployment

 cloudfunctions_file_list  = fileset(path.module, "cloudfunctions/*json")
 cloudfunctions_list_raw = {
  for file_path in local.cloudfunctions_file_list :
  trimsuffix(file_path, ".json") => "${file_path}"
 }

 cloudfunctions_list = {
  for file_stem_path, file_path in local.cloudfunctions_list_raw:
    file_stem_path => jsondecode(templatefile(file_path, {project_id = var.project_id, region_id = var.region_id} ))
 }

 ##bigquery view deployment

 views_file_list  = fileset(path.module, "views/*json")
 views_list_raw = {
  for file_path in local.views_file_list :
  trimsuffix(file_path, ".json") => "${file_path}"
 }

 views_list = {
  for file_stem_path, file_path in local.views_list_raw:
    file_stem_path => jsondecode(templatefile(file_path, {project_id = var.project_id} ))
 }

  ##bigquery sproc stored procedure deployment

 sprocs_file_list  = fileset(path.module, "sql_scripts/*yaml")
 sprocs_list_raw = {
  for file_path in local.sprocs_file_list :
  trimsuffix(file_path, ".yaml") => "${file_path}"
 }

 sprocs_list = {
  for file_stem_path, file_path in local.sprocs_list_raw:
    file_stem_path => yamldecode(templatefile(file_path, {project_id = var.project_id} ))
 }

##bigquery materialized views deployment

 mat_views_file_list  = fileset(path.module, "mat_views/*json")
 mat_views_list_raw = {
  for file_path in local.mat_views_file_list :
  trimsuffix(file_path, ".json") => "${file_path}"
 }

 mat_views_list = {
  for file_stem_path, file_path in local.mat_views_list_raw:
    file_stem_path => jsondecode(templatefile(file_path, {project_id = var.project_id} ))
 }

}

