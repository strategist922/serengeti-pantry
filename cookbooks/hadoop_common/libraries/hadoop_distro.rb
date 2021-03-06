#
#   Copyright (c) 2012 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

module HadoopCluster
  def distro(name)
    data_bag_item("hadoop_distros", name)
  end

  def current_distro
    @current_distro ||= distro(node[:hadoop][:distro_name])
  end

  def package_repos
    current_distro['package_repos'] || []
  end

  def is_install_from_tarball
    current_distro['is_install_from_tarball']
  end

  class Chef::Recipe ; include HadoopCluster ; end
  class Chef::Resource::Directory ; include HadoopCluster ; end
end
