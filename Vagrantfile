require 'berkshelf/vagrant'

Vagrant::Config.run do |config|
  config.vm.host_name = "solr-berkshelf"
  config.vm.box = "precise64"
  config.vm.network :hostonly, "33.33.33.10"
  config.vm.forward_port 8080, 8088

  config.ssh.max_tries = 40
  config.ssh.timeout   = 120

  # install ruby and correct Chef version
  # config.vm.provision :shell, :path => "files/default/bootstrap.sh"

  # provision the application
  config.vm.provision :chef_solo do |chef|    
    chef.json = {
      :mysql => {
        :server_root_password   => 'rootpass',
        :server_debian_password => 'debpass',
        :server_repl_password   => 'replpass'
      },
    }

    # sequence to run the recipes
    chef.run_list = [
      "recipe[solr::tomcat]",
      "recipe[solr::default]",
    ]
  end
end
