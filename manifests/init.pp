#init.pp
class oracle-xe (
  $http_port = 8080,
  $listener_port = 1521,
  $ipv6 = false,
  $startup = 'y',
  $password= 'inist01',
  $iniface = undef,
) {

  $oracle_rpm = "oracle-xe-11.2.0-1.0.x86_64.rpm"
  $oracle_rpm_tmp = "/tmp/$oracle_rpm"
  $oracle_home="/u01/app/oracle/product/11.2.0/xe/"

  file { 'oracle-xe-rpm':
    path   => "$oracle_rpm_tmp",
    ensure => file,
    source => "puppet:///modules/oracle-xe/$oracle_rpm",
    mode   => 0444,
    owner  => root,
    group  => root,
  }


  package { [ 'libaio', 'flex', 'bc']: 
    ensure => 'latest',
    before => Package['oracle-xe'],
    require => Class[epelrepo]
  }

  package { 'oracle-xe':
    ensure   => present,
    source   => "$oracle_rpm_tmp",
    provider => 'rpm',
  }

  if $::virtualizer == "lxc" {
	file { 'oracle_init_ora':
		source => 'puppet:///modules/oracle-xe/init.ora',
		path => "${oracle_home}/config/scripts/init.ora",
		backup => true,
		group => 'dba',
		owner => 'oracle',
		require => Package['oracle-xe'],
		before => Exec['oracle-xe-conf']
	}

        file { 'oracle_initXE_ora':
                source => 'puppet:///modules/oracle-xe/initXETemp.ora',
                path => "${oracle_home}/config/scripts/initXETemp.ora",
		backup => true,
                group => 'dba',
                owner => 'oracle',
                require => Package['oracle-xe'],
                before => Exec['oracle-xe-conf']
        }
  }
	
  exec { 'oracle-xe-conf':
    creates => '/etc/sysconfig/oracle-xe',
    command => "/usr/bin/printf \"$http_port\\n$listener_port\\n$password\\n$password\\n$startup\\n\" | /etc/init.d/oracle-xe configure",
  }

  service { 'oracle-xe':
    ensure => running,
    enable => true,
    hasrestart => true,
    hasstatus  => true,
  }

 # if $::osfamily == "RedHat" {
 #	centosfirewall::ajout_service { 'oracle-listener':
 #		 port => $listener_port,
 #       	 protocol  => 'tcp',
 #  	}
 #	centosfirewall::ajout_service { 'oracle-web':
 #                port => $http_port,
 #                protocol  => 'tcp',
 #       }
 # }


  File['oracle-xe-rpm'] -> Package['oracle-xe']
  Package['oracle-xe'] -> Exec['oracle-xe-conf']
  Exec['oracle-xe-conf'] -> Service['oracle-xe']
#  Service['oracle-xe'] -> Firewall['100 oracle']
}
