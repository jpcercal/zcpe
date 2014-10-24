class rvm::passenger::apache(
  $ruby_version,
  $version,
  $rvm_prefix = '/usr/local',
  $mininstances = '1',
  $maxpoolsize = '6',
  $poolidletime = '300',
  $maxinstancesperapp = '0',
  $spawnmethod = 'smart-lv2',
  $proxy_url = undef,
  $install_timeout = 600
) {

  class { 'rvm::passenger::gem':
    ruby_version => $ruby_version,
    version      => $version,
    proxy_url    => $proxy_url
  }

  # TODO: How can we get the gempath automatically using the ruby version
  # Can we read the output of a command into a variable?
  # e.g. $gempath = `usr/local/rvm/bin/rvm ${ruby_version} exec rvm gemdir`
  $gempath = "${rvm_prefix}/rvm/gems/${ruby_version}/gems"
  $binpath = "${rvm_prefix}/rvm/bin/"
  $gemroot = "${gempath}/passenger-${version}"

  if ( versioncmp( $rvm::passenger::apache::version, '4.0.0' ) < 0 ) {
    if ( versioncmp( $rvm::passenger::apache::version, '3.9.0' ) < 0 ) {
      $objdir = 'ext'
    } else {
      $objdir = 'libout'
    }
  } else {
    $objdir = 'buildout'
  }

  $modpath = "${gemroot}/${objdir}/apache2"

  # build the Apache module
  # different passenger versions put the built module in different places (ext, libout, buildout)
  include apache::dev

  class { 'rvm::passenger::dependencies': } ->

  exec { 'passenger-install-apache2-module':
    command     => "${binpath}rvm ${ruby_version} exec passenger-install-apache2-module -a",
    creates     => "${modpath}/mod_passenger.so",
    environment => [ 'HOME=/root', ],
    path        => '/usr/bin:/usr/sbin:/bin',
    require     => Class['rvm::passenger::gem','apache::dev'],
    timeout     => $install_timeout,
  }

  class { 'apache::mod::passenger':
    passenger_root           => $gemroot,
    passenger_ruby           => "${rvm_prefix}/rvm/wrappers/${ruby_version}/ruby",
    passenger_max_pool_size  => $maxpoolsize,
    passenger_pool_idle_time => $poolidletime,
    mod_lib_path             => $modpath,
    require                  => Exec['passenger-install-apache2-module'],
    subscribe                => Exec['passenger-install-apache2-module'],
  }

  case $::osfamily {
    # for redhat and debian OSs Apache configures passenger_extra.conf
    # with the details that should be located in
    # passenger.conf;apache::mod::passenger can't be written directly to
    # passenger.conf without creating a conflict within the apache
    # module, but copying the file contents works fine
    'debian','redhat': {
      case $::osfamily {
        'redhat': {
          $apache_mods_path = '/etc/httpd/conf.d'
        }
        'debian': {
          $apache_mods_path = '/etc/apache2/mods-available'
        }
      }
      exec { 'copy passenger_extra.conf to passenger.conf':
        command     => "/bin/cp ${apache_mods_path}/passenger_extra.conf ${apache_mods_path}/passenger.conf",
        unless      => "/usr/bin/diff ${apache_mods_path}/passenger_extra.conf ${apache_mods_path}/passenger.conf",
        environment => [ 'HOME=/root', ],
        path        => '/usr/bin:/usr/sbin:/bin',
        require     => Class['apache::mod::passenger'],
      }
    }
    default: {}
  }
}