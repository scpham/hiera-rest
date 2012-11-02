$msg = hiera('message', 'no response')
notify { "Message is ${msg}": }
$role = hiera('deviceRole', 'no response')
notify { "Role for ${::testcms} is ${role}": }
