locals{

datasets = {
   for file in fileset(path.module, "datasets/*json") :
    file => ( jsondecode(file("${path.module}/${file}")))

 }

tables = {
   for file in fileset(path.module, "tables/*json") :
    file => ( jsondecode(file("${path.module}/${file}")))

 }
}
