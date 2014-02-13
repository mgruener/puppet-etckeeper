class etckeeper (
  $puppetintegration = true
) {

  $myclass = $module_name

  case type($puppetintegration) {
    'string': {
      validate_re($puppetintegration, '^(true|false)$', "${myclass}::puppetintegration may be either 'true' or 'false' and is set to <${puppetintegration}>.")
      $puppetintegration_real = str2bool($puppetintegration)
    }
    'boolean': {
      $puppetintegration_real = $puppetintegration
    }
    default: {
      fail("${myclass}::puppetintegration type must be true or false.")
    }
  }

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

  if $puppetintegration_real {
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
