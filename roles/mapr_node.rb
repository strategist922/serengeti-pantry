name        'mapr_node'
description 'mapr node'

run_list *%w[
  role[mapr_cldb]
  role[mapr_zookeeper]
  role[mapr_jobtracker]
  role[mapr_tasktracker]
  role[mapr_fileserver]
  role[mapr_nfs]
  role[mapr_webserver]

  recipe[mapr::prereqs]
  recipe[mapr::install]
  recipe[mapr::diskconfig]
  recipe[mapr::startup]
]
