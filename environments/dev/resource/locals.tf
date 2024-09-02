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
  for file_path in workflows_file_list :
  trimsuffix(file_path, ".yaml") => "${file_path}" 
}


#prepare the list of required sub workflows 
subworkflows_file_list  = fileset(path.module, "subworkflows/*yaml")
subworkflows_list = [
  for file_path in subworkflows_file_list :
  "${file_path}"
]


## prepare final list of individual workflow and associated subworkflows

workflows_list = {
  for file_stem_path, file_path in workflows_list_raw:
  file_stem_path => join(
   "\n",
   concat(
    [templatefile(file_path)],
    [for sub_file in subworkflows_list: templatefile(sub_file)]
   )
  )
}


}
