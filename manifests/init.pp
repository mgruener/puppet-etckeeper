class etckeeper ($puppetintegration = str2bool(hiera("${module_name}::puppetintegration",true))) {
  package { 'etckeeper':
    ensure => present,
  }

  exec { 'etckeeper init':
    creates => '/etc/.etckeeper',
    path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    require => Package['etckeeper']
  }

  # etckeeper init does not commit
  exec { 'etckeeper commit "initial commit"':
    onlyif      => 'etckeeper unclean',
    path        => '/bin:/usr/bin:/sbin:/usr/sbin',
    subscribe   => Exec['etckeeper init'],
    refreshonly => true
  }

  if $puppetintegration {
    file { '/etc/puppet/etckeeper-commit-pre':
      ensure => file,
      source => "puppet:///modules/${module_name}/etckeeper-commit-pre",
      owner  => root,
      group  => root,
      mode   => '0754'
    }

    file { '/etc/puppet/etckeeper-commit-post':
      ensure => file,
      source => "puppet:///modules/${module_name}/etckeeper-commit-post",
      owner  => root,
      group  => root,
      mode   => '0754'
    }

    puppet::config { 'prerun_command':
      value   => '/etc/puppet/etckeeper-commit-pre',
      require => Exec['etckeeper init']
    }

    puppet::config { 'postrun_command':
      value   => '/etc/puppet/etckeeper-commit-post',
      require => Exec['etckeeper init']
    }
  }
}
