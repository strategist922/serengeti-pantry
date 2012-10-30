maintainer        "VMware Inc."
maintainer_email  "serengeti-dev@googlegroups.com"
license           "Apache 2.0"
description       "MapR"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.txt'))
version           "0.0.2"

%w[ centos ].each do |os|
  supports os
end
